-- Migration v2 : nouveaux types d'operations + edition/suppression avec recalcul de soldes
-- A executer dans le SQL Editor Supabase.
--
-- PostgreSQL : les valeurs ajoutees a un ENUM ne sont utilisables qu'apres COMMIT.
-- Les fonctions ci-dessous comparent p_type::text (chaines) pour eviter l'erreur 55P04
-- si tout le script tourne dans une seule transaction (comportement SQL Editor).

do $$
begin
  alter type public.transaction_type add value if not exists 'transfert_uv';
  alter type public.transaction_type add value if not exists 'transfert_c2c';
exception
  when duplicate_object then null;
end $$;

create or replace function public.calculate_commission(p_type public.transaction_type, p_amount numeric)
returns numeric
language sql
immutable
as $$
  select case p_type::text
    when 'depot' then p_amount * 0.0014
    when 'retrait' then p_amount * 0.0028
    when 'nafama' then p_amount * 0.0455
    when 'forfait' then p_amount * 0.10
    when 'sewa' then p_amount * 0.10
    when 'transfert_uv' then 0::numeric
    when 'transfert_c2c' then 0::numeric
    when 'achat' then 0::numeric
    else 0::numeric
  end;
$$;

create or replace function public.transaction_balance_delta(
  p_category public.transaction_category,
  p_type public.transaction_type,
  p_amount numeric
)
returns numeric
language sql
immutable
as $$
  select case
    when p_category = 'UV' and p_type::text in ('depot', 'nafama', 'transfert_c2c') then -p_amount
    when p_category = 'UV' and p_type::text in ('retrait', 'transfert_uv') then p_amount
    when p_category = 'CREDIT' and p_type::text in ('sewa', 'forfait') then -p_amount
    when p_category = 'CREDIT' and p_type::text = 'achat' then p_amount
    else 0::numeric
  end;
$$;

create or replace function public.before_insert_transaction()
returns trigger
language plpgsql
as $$
declare
  v_balance numeric(16,2);
  v_delta numeric(16,2);
begin
  if new.commission = 0 then
    new.commission = round(public.calculate_commission(new.type, new.amount)::numeric, 2);
  end if;
  new.net_profit = new.commission;

  select balance into v_balance
  from public.wallets
  where user_id = new.user_id and category = new.category
  for update;

  if v_balance is null then
    raise exception 'Wallet introuvable pour user=% et category=%', new.user_id, new.category;
  end if;

  new.balance_before = v_balance;
  v_delta = public.transaction_balance_delta(new.category, new.type, new.amount);
  new.balance_after = v_balance + v_delta;

  return new;
end;
$$;

create or replace function public.delete_transaction(p_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tx public.transactions%rowtype;
  v_delta numeric(16,2);
begin
  select *
  into v_tx
  from public.transactions
  where id = p_id and user_id = p_user_id
  for update;

  if not found then
    raise exception 'Transaction introuvable';
  end if;

  v_delta = public.transaction_balance_delta(v_tx.category, v_tx.type, v_tx.amount);

  update public.wallets
  set balance = balance - v_delta
  where user_id = p_user_id and category = v_tx.category;

  if v_tx.category = 'UV' then
    update public.profiles
    set solde_uv = (select balance from public.wallets where user_id = p_user_id and category = 'UV')
    where id = p_user_id;
  else
    update public.profiles
    set solde_credit = (select balance from public.wallets where user_id = p_user_id and category = 'CREDIT')
    where id = p_user_id;
  end if;

  delete from public.transactions where id = p_id and user_id = p_user_id;
end;
$$;

create or replace function public.update_transaction(
  p_id uuid,
  p_user_id uuid,
  p_type public.transaction_type,
  p_category public.transaction_category,
  p_client_name text,
  p_client_phone text,
  p_merchant_phone text,
  p_amount numeric,
  p_note text default null
)
returns setof public.transactions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old public.transactions%rowtype;
  v_old_delta numeric(16,2);
  v_new_delta numeric(16,2);
  v_before numeric(16,2);
  v_after numeric(16,2);
  v_commission numeric(16,2);
begin
  select *
  into v_old
  from public.transactions
  where id = p_id and user_id = p_user_id
  for update;

  if not found then
    raise exception 'Transaction introuvable';
  end if;

  v_old_delta = public.transaction_balance_delta(v_old.category, v_old.type, v_old.amount);
  update public.wallets
  set balance = balance - v_old_delta
  where user_id = p_user_id and category = v_old.category;

  select balance into v_before
  from public.wallets
  where user_id = p_user_id and category = p_category
  for update;

  if v_before is null then
    raise exception 'Wallet introuvable';
  end if;

  v_new_delta = public.transaction_balance_delta(p_category, p_type, p_amount);
  v_after = v_before + v_new_delta;
  v_commission = round(public.calculate_commission(p_type, p_amount)::numeric, 2);

  update public.wallets
  set balance = v_after
  where user_id = p_user_id and category = p_category;

  update public.transactions
  set
    type = p_type,
    category = p_category,
    client_name = p_client_name,
    client_phone = p_client_phone,
    merchant_phone = nullif(trim(coalesce(p_merchant_phone, '')), ''),
    amount = p_amount,
    commission = v_commission,
    net_profit = v_commission,
    note = p_note,
    balance_before = v_before,
    balance_after = v_after,
    updated_at = now()
  where id = p_id and user_id = p_user_id;

  update public.profiles
  set solde_uv = (select balance from public.wallets where user_id = p_user_id and category = 'UV'),
      solde_credit = (select balance from public.wallets where user_id = p_user_id and category = 'CREDIT')
  where id = p_user_id;

  return query
  select *
  from public.transactions
  where id = p_id and user_id = p_user_id;
end;
$$;

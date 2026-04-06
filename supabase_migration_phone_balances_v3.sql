-- CreditTrak v3 : soldes UV / Crédit et bénéfices PAR numéro d'opération
-- + type transfert_profit_uv, numéro de journal (journal_seq), refus si solde négatif
-- À exécuter dans le SQL Editor Supabase APRÈS supabase_schema_full.sql et migration v2.
--
-- Résumé métier :
-- - Chaque ligne operation_phone_wallets = un numéro d'opération avec solde_uv, solde_credit, profit_uv, profit_credit
-- - Les transactions doivent avoir merchant_phone (sauf si tu adaptes l'app pour un mode sans numéro)
-- - profiles.solde_uv / solde_credit et wallets.balance restent des TOTAUX (somme des lignes) pour compatibilité app

-- =========================
-- 1) Enum : transfert profit UV
-- =========================
do $$
begin
  alter type public.transaction_type add value if not exists 'transfert_profit_uv';
exception
  when duplicate_object then null;
end $$;

-- =========================
-- 2) Table portefeuille par numéro d'opération
-- =========================
create table if not exists public.operation_phone_wallets (
  user_id uuid not null references public.profiles(id) on delete cascade,
  phone text not null,
  solde_uv numeric(16,2) not null default 0 check (solde_uv >= 0),
  solde_credit numeric(16,2) not null default 0 check (solde_credit >= 0),
  profit_uv numeric(16,2) not null default 0 check (profit_uv >= 0),
  profit_credit numeric(16,2) not null default 0 check (profit_credit >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, phone)
);

create index if not exists idx_op_phone_wallets_user on public.operation_phone_wallets (user_id);

drop trigger if exists trg_op_phone_wallets_updated_at on public.operation_phone_wallets;
create trigger trg_op_phone_wallets_updated_at
before update on public.operation_phone_wallets
for each row execute function public.set_updated_at();

-- =========================
-- 3) Numéro de journal (lisible côté reçu)
-- =========================
alter table public.transactions add column if not exists journal_seq bigint;

create table if not exists public.user_journal_counter (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  next_seq bigint not null default 0
);

-- =========================
-- 4) RLS
-- =========================
alter table public.operation_phone_wallets enable row level security;

drop policy if exists op_phone_wallets_all_own on public.operation_phone_wallets;
create policy op_phone_wallets_all_own on public.operation_phone_wallets
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =========================
-- 5) Données existantes : une ligne par numéro du profil, soldes sur le 1er numéro
-- =========================
insert into public.operation_phone_wallets (user_id, phone, solde_uv, solde_credit)
select s.user_id,
       s.phone,
       case when s.rn = 1 then coalesce(wu.balance, 0) else 0 end,
       case when s.rn = 1 then coalesce(wc.balance, 0) else 0 end
from (
  select p.id as user_id,
         trim(both from x.p) as phone,
         row_number() over (partition by p.id order by ord) as rn
  from public.profiles p
  cross join lateral unnest(p.operation_phones) with ordinality as x(p, ord)
  where cardinality(p.operation_phones) > 0
    and nullif(trim(both from x.p), '') is not null
) s
left join public.wallets wu on wu.user_id = s.user_id and wu.category = 'UV'
left join public.wallets wc on wc.user_id = s.user_id and wc.category = 'CREDIT'
on conflict (user_id, phone) do nothing;

-- Backfill journal_seq pour anciennes lignes
insert into public.user_journal_counter (user_id)
select distinct user_id from public.transactions
on conflict (user_id) do nothing;

with ranked as (
  select id, user_id,
         row_number() over (partition by user_id order by created_at asc, id asc) as seq
  from public.transactions
  where journal_seq is null
)
update public.transactions t
set journal_seq = ranked.seq
from ranked
where t.id = ranked.id;

update public.user_journal_counter c
set next_seq = coalesce((
  select max(journal_seq) from public.transactions x where x.user_id = c.user_id
), 0);

-- =========================
-- 6) Fonctions métier
-- =========================
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
    when 'transfert_profit_uv' then 0::numeric
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
    when p_type::text = 'transfert_profit_uv' and p_category = 'UV' then p_amount
    when p_category = 'UV' and p_type::text in ('depot', 'nafama', 'transfert_c2c') then -p_amount
    when p_category = 'UV' and p_type::text in ('retrait', 'transfert_uv') then p_amount
    when p_category = 'CREDIT' and p_type::text in ('sewa', 'forfait') then -p_amount
    when p_category = 'CREDIT' and p_type::text = 'achat' then p_amount
    else 0::numeric
  end;
$$;

create or replace function public.refresh_totals_from_phone_wallets(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  s_uv numeric(16,2);
  s_cr numeric(16,2);
begin
  select coalesce(sum(solde_uv), 0), coalesce(sum(solde_credit), 0)
  into s_uv, s_cr
  from public.operation_phone_wallets
  where user_id = p_user_id;

  update public.wallets set balance = s_uv where user_id = p_user_id and category = 'UV';
  update public.wallets set balance = s_cr where user_id = p_user_id and category = 'CREDIT';

  update public.profiles
  set solde_uv = s_uv, solde_credit = s_cr
  where id = p_user_id;
end;
$$;

create or replace function public.before_insert_transaction()
returns trigger
language plpgsql
as $$
declare
  v_phone text;
  v_uv numeric(16,2);
  v_cr numeric(16,2);
  v_pu numeric(16,2);
  v_pc numeric(16,2);
  v_delta numeric(16,2);
  v_next bigint;
begin
  v_phone := nullif(trim(both from coalesce(new.merchant_phone, '')), '');
  if v_phone is null then
    raise exception 'MERCHANT_PHONE_REQUIRED';
  end if;

  insert into public.operation_phone_wallets (user_id, phone)
  values (new.user_id, v_phone)
  on conflict (user_id, phone) do nothing;

  insert into public.user_journal_counter (user_id, next_seq) values (new.user_id, 0)
  on conflict (user_id) do nothing;

  update public.user_journal_counter
  set next_seq = next_seq + 1
  where user_id = new.user_id
  returning next_seq into v_next;

  new.journal_seq := v_next;

  if new.commission = 0 then
    new.commission := round(public.calculate_commission(new.type, new.amount)::numeric, 2);
  end if;
  new.net_profit := new.commission;

  select solde_uv, solde_credit, profit_uv, profit_credit
  into v_uv, v_cr, v_pu, v_pc
  from public.operation_phone_wallets
  where user_id = new.user_id and phone = v_phone
  for update;

  if not found then
    raise exception 'Portefeuille introuvable pour le numéro %', v_phone;
  end if;

  if new.type::text = 'transfert_profit_uv' then
    new.category := 'UV';
    if new.amount <= 0 then
      raise exception 'Le montant doit être strictement positif.';
    end if;
    if new.amount > v_pu then
      raise exception 'Montant supérieur au bénéfice UV disponible (%.2f).', v_pu;
    end if;
    new.balance_before := v_uv;
    new.balance_after := v_uv + new.amount;
    if new.balance_after < 0 then
      raise exception 'Solde UV insuffisant après opération.';
    end if;
    return new;
  end if;

  if new.category = 'UV' then
    new.balance_before := v_uv;
    v_delta := public.transaction_balance_delta(new.category, new.type, new.amount);
    new.balance_after := v_uv + v_delta;
  elsif new.category = 'CREDIT' then
    new.balance_before := v_cr;
    v_delta := public.transaction_balance_delta(new.category, new.type, new.amount);
    new.balance_after := v_cr + v_delta;
  else
    raise exception 'Catégorie invalide';
  end if;

  if new.balance_after < 0 then
    raise exception 'SOLDE_INSUFFISANT';
  end if;

  return new;
end;
$$;

create or replace function public.after_insert_transaction()
returns trigger
language plpgsql
as $$
declare
  v_phone text;
begin
  v_phone := nullif(trim(both from coalesce(new.merchant_phone, '')), '');
  if v_phone is null then
    raise exception 'MERCHANT_PHONE_REQUIRED';
  end if;

  if new.type::text = 'transfert_profit_uv' then
    update public.operation_phone_wallets
    set
      solde_uv = new.balance_after,
      profit_uv = profit_uv - new.amount,
      updated_at = now()
    where user_id = new.user_id and phone = v_phone;
  elsif new.category = 'UV' then
    update public.operation_phone_wallets
    set
      solde_uv = new.balance_after,
      profit_uv = profit_uv + new.commission,
      updated_at = now()
    where user_id = new.user_id and phone = v_phone;
  else
    update public.operation_phone_wallets
    set
      solde_credit = new.balance_after,
      profit_credit = profit_credit + new.commission,
      updated_at = now()
    where user_id = new.user_id and phone = v_phone;
  end if;

  perform public.refresh_totals_from_phone_wallets(new.user_id);

  insert into public.audit_logs (user_id, event, entity, entity_id, payload)
  values (
    new.user_id,
    'transaction_created',
    'transactions',
    new.id,
    jsonb_build_object(
      'type', new.type,
      'category', new.category,
      'amount', new.amount,
      'commission', new.commission,
      'merchant_phone', v_phone,
      'journal_seq', new.journal_seq
    )
  );

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
  v_phone text;
  v_delta numeric(16,2);
begin
  select * into v_tx
  from public.transactions
  where id = p_id and user_id = p_user_id
  for update;

  if not found then
    raise exception 'Transaction introuvable';
  end if;

  v_phone := nullif(trim(both from coalesce(v_tx.merchant_phone, '')), '');
  if v_phone is null then
    raise exception 'Transaction sans numéro d''opération';
  end if;

  perform 1 from public.operation_phone_wallets
  where user_id = p_user_id and phone = v_phone
  for update;

  if v_tx.type::text = 'transfert_profit_uv' then
    update public.operation_phone_wallets
    set
      solde_uv = solde_uv - v_tx.amount,
      profit_uv = profit_uv + v_tx.amount,
      updated_at = now()
    where user_id = p_user_id and phone = v_phone;
  else
    v_delta := public.transaction_balance_delta(v_tx.category, v_tx.type, v_tx.amount);
    if v_tx.category = 'UV' then
      update public.operation_phone_wallets
      set
        solde_uv = solde_uv - v_delta,
        profit_uv = greatest(0, profit_uv - v_tx.commission),
        updated_at = now()
      where user_id = p_user_id and phone = v_phone;
    else
      update public.operation_phone_wallets
      set
        solde_credit = solde_credit - v_delta,
        profit_credit = greatest(0, profit_credit - v_tx.commission),
        updated_at = now()
      where user_id = p_user_id and phone = v_phone;
    end if;
  end if;

  perform public.refresh_totals_from_phone_wallets(p_user_id);

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
  v_old_phone text;
  v_new_phone text;
  v_old_delta numeric(16,2);
  v_new_delta numeric(16,2);
  v_uv numeric(16,2);
  v_cr numeric(16,2);
  v_pu numeric(16,2);
  v_pc numeric(16,2);
  v_commission numeric(16,2);
  v_before numeric(16,2);
  v_after numeric(16,2);
begin
  select * into v_old
  from public.transactions
  where id = p_id and user_id = p_user_id
  for update;

  if not found then
    raise exception 'Transaction introuvable';
  end if;

  v_old_phone := nullif(trim(both from coalesce(v_old.merchant_phone, '')), '');
  v_new_phone := nullif(trim(both from coalesce(p_merchant_phone, '')), '');
  if v_new_phone is null then
    raise exception 'MERCHANT_PHONE_REQUIRED';
  end if;

  insert into public.operation_phone_wallets (user_id, phone)
  values (p_user_id, v_new_phone)
  on conflict (user_id, phone) do nothing;

  -- Annuler l'ancienne opération sur l'ancien numéro
  if v_old_phone is not null then
    perform 1 from public.operation_phone_wallets where user_id = p_user_id and phone = v_old_phone for update;
    if v_old.type::text = 'transfert_profit_uv' then
      update public.operation_phone_wallets
      set solde_uv = solde_uv - v_old.amount,
          profit_uv = profit_uv + v_old.amount,
          updated_at = now()
      where user_id = p_user_id and phone = v_old_phone;
    elsif v_old.category = 'UV' then
      v_old_delta := public.transaction_balance_delta(v_old.category, v_old.type, v_old.amount);
      update public.operation_phone_wallets
      set solde_uv = solde_uv - v_old_delta,
          profit_uv = greatest(0, profit_uv - v_old.commission),
          updated_at = now()
      where user_id = p_user_id and phone = v_old_phone;
    else
      v_old_delta := public.transaction_balance_delta(v_old.category, v_old.type, v_old.amount);
      update public.operation_phone_wallets
      set solde_credit = solde_credit - v_old_delta,
          profit_credit = greatest(0, profit_credit - v_old.commission),
          updated_at = now()
      where user_id = p_user_id and phone = v_old_phone;
    end if;
  end if;

  v_commission := round(public.calculate_commission(p_type, p_amount)::numeric, 2);

  -- Lire les soldes sur le numéro cible (nouveau ou même)
  perform 1 from public.operation_phone_wallets where user_id = p_user_id and phone = v_new_phone for update;
  select solde_uv, solde_credit, profit_uv, profit_credit
  into v_uv, v_cr, v_pu, v_pc
  from public.operation_phone_wallets
  where user_id = p_user_id and phone = v_new_phone;

  if p_type::text = 'transfert_profit_uv' then
    p_category := 'UV';
    if p_amount <= 0 then raise exception 'Le montant doit être strictement positif.'; end if;
    if p_amount > v_pu then
      raise exception 'Montant supérieur au bénéfice UV disponible (%.2f).', v_pu;
    end if;
    v_before := v_uv;
    v_after := v_uv + p_amount;
    if v_after < 0 then raise exception 'SOLDE_INSUFFISANT'; end if;

    update public.operation_phone_wallets
    set solde_uv = v_after,
        profit_uv = profit_uv - p_amount,
        updated_at = now()
    where user_id = p_user_id and phone = v_new_phone;

    update public.transactions
    set
      type = p_type,
      category = 'UV',
      client_name = p_client_name,
      client_phone = p_client_phone,
      merchant_phone = v_new_phone,
      amount = p_amount,
      commission = 0,
      net_profit = 0,
      note = p_note,
      balance_before = v_before,
      balance_after = v_after,
      updated_at = now()
    where id = p_id and user_id = p_user_id;
  else
    if p_category = 'UV' then
      v_before := v_uv;
      v_new_delta := public.transaction_balance_delta(p_category, p_type, p_amount);
      v_after := v_uv + v_new_delta;
    else
      v_before := v_cr;
      v_new_delta := public.transaction_balance_delta(p_category, p_type, p_amount);
      v_after := v_cr + v_new_delta;
    end if;

    if v_after < 0 then
      raise exception 'SOLDE_INSUFFISANT';
    end if;

    if p_category = 'UV' then
      update public.operation_phone_wallets
      set solde_uv = v_after,
          profit_uv = profit_uv + v_commission,
          updated_at = now()
      where user_id = p_user_id and phone = v_new_phone;
    else
      update public.operation_phone_wallets
      set solde_credit = v_after,
          profit_credit = profit_credit + v_commission,
          updated_at = now()
      where user_id = p_user_id and phone = v_new_phone;
    end if;

    update public.transactions
    set
      type = p_type,
      category = p_category,
      client_name = p_client_name,
      client_phone = p_client_phone,
      merchant_phone = v_new_phone,
      amount = p_amount,
      commission = v_commission,
      net_profit = v_commission,
      note = p_note,
      balance_before = v_before,
      balance_after = v_after,
      updated_at = now()
    where id = p_id and user_id = p_user_id;
  end if;

  perform public.refresh_totals_from_phone_wallets(p_user_id);

  return query
  select * from public.transactions where id = p_id and user_id = p_user_id;
end;
$$;

-- Ajustement manuel des soldes UV / crédit par ligne (sans toucher aux bénéfices cumulés)
create or replace function public.set_operation_phone_balances(
  p_phone text,
  p_solde_uv numeric,
  p_solde_credit numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  ph text := nullif(trim(both from p_phone), '');
begin
  if uid is null then
    raise exception 'Non authentifié';
  end if;
  if ph is null then
    raise exception 'Numéro d''opération vide';
  end if;
  if p_solde_uv < 0 or p_solde_credit < 0 then
    raise exception 'Les soldes ne peuvent pas être négatifs.';
  end if;

  insert into public.operation_phone_wallets (user_id, phone, solde_uv, solde_credit)
  values (uid, ph, p_solde_uv, p_solde_credit)
  on conflict (user_id, phone) do update set
    solde_uv = excluded.solde_uv,
    solde_credit = excluded.solde_credit,
    updated_at = now();

  perform public.refresh_totals_from_phone_wallets(uid);
end;
$$;

revoke all on function public.set_operation_phone_balances(text, numeric, numeric) from public;
grant execute on function public.set_operation_phone_balances(text, numeric, numeric) to authenticated;
revoke all on function public.refresh_totals_from_phone_wallets(uuid) from public;
grant execute on function public.refresh_totals_from_phone_wallets(uuid) to authenticated;

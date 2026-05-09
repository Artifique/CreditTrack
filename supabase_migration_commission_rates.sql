-- Migration : taux de commission configurables par utilisateur (business_settings.commission_rates)
-- À exécuter dans le SQL Editor Supabase après phone_balances_v3 (ou schéma équivalent).
--
-- JSON attendu : {"depot":0.0014,"retrait":0.0028,"nafama":0.0455,"forfait":0.10,"sewa":0.10}
-- Les multiplicateurs correspondent aux anciennes constantes (fraction du montant, pas pourcentage UI).

alter table public.business_settings
  add column if not exists commission_rates jsonb
  not null
  default '{"depot":0.0014,"retrait":0.0028,"nafama":0.0455,"forfait":0.10,"sewa":0.10}'::jsonb;

update public.business_settings
set commission_rates = '{"depot":0.0014,"retrait":0.0028,"nafama":0.0455,"forfait":0.10,"sewa":0.10}'::jsonb
where commission_rates is null;

create or replace function public.calculate_commission_for_user(
  p_user_id uuid,
  p_type public.transaction_type,
  p_amount numeric
)
returns numeric
language plpgsql
stable
set search_path = public
as $$
declare
  j jsonb;
  r_depot numeric := 0.0014;
  r_retrait numeric := 0.0028;
  r_nafama numeric := 0.0455;
  r_forfait numeric := 0.10;
  r_sewa numeric := 0.10;
begin
  select bs.commission_rates into j
  from public.business_settings bs
  where bs.user_id = p_user_id;

  if j is not null then
    r_depot := coalesce((j ->> 'depot')::numeric, r_depot);
    r_retrait := coalesce((j ->> 'retrait')::numeric, r_retrait);
    r_nafama := coalesce((j ->> 'nafama')::numeric, r_nafama);
    r_forfait := coalesce((j ->> 'forfait')::numeric, r_forfait);
    r_sewa := coalesce((j ->> 'sewa')::numeric, r_sewa);
  end if;

  case p_type::text
    when 'depot' then return p_amount * r_depot;
    when 'retrait' then return p_amount * r_retrait;
    when 'nafama' then return p_amount * r_nafama;
    when 'forfait' then return p_amount * r_forfait;
    when 'sewa' then return p_amount * r_sewa;
    when 'transfert_uv' then return 0::numeric;
    when 'transfert_c2c' then return 0::numeric;
    when 'achat' then return 0::numeric;
    when 'transfert_profit_uv' then return 0::numeric;
    else return 0::numeric;
  end case;
end;
$$;

-- Recalcul systématique côté serveur (ignore la valeur envoyée par le client)
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

  new.commission := round(public.calculate_commission_for_user(new.user_id, new.type, new.amount)::numeric, 2);
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

  v_commission := round(public.calculate_commission_for_user(p_user_id, p_type, p_amount)::numeric, 2);

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

-- Migration : type "Transfert de crédit" (commission configurable, défaut 10%)
--             + fonction "Effacer toutes les données" (scopée par utilisateur)
-- À exécuter dans le SQL Editor Supabase APRÈS phone_balances_v3 et commission_rates.

-- =========================
-- 1) Enum : nouveau type de transaction
-- =========================
do $$
begin
  alter type public.transaction_type add value if not exists 'transfert_credit';
exception
  when duplicate_object then null;
end $$;

-- =========================
-- 2) Taux de commission configurable (business_settings.commission_rates)
-- =========================
update public.business_settings
set commission_rates = commission_rates || '{"transfert_credit":0.10}'::jsonb
where not (commission_rates ? 'transfert_credit');

alter table public.business_settings
  alter column commission_rates set default
  '{"depot":0.0014,"retrait":0.0028,"nafama":0.0455,"forfait":0.10,"sewa":0.10,"transfert_credit":0.10}'::jsonb;

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
  r_transfert_credit numeric := 0.10;
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
    r_transfert_credit := coalesce((j ->> 'transfert_credit')::numeric, r_transfert_credit);
  end if;

  case p_type::text
    when 'depot' then return p_amount * r_depot;
    when 'retrait' then return p_amount * r_retrait;
    when 'nafama' then return p_amount * r_nafama;
    when 'forfait' then return p_amount * r_forfait;
    when 'sewa' then return p_amount * r_sewa;
    when 'transfert_credit' then return p_amount * r_transfert_credit;
    when 'transfert_uv' then return 0::numeric;
    when 'transfert_c2c' then return 0::numeric;
    when 'achat' then return 0::numeric;
    when 'transfert_profit_uv' then return 0::numeric;
    else return 0::numeric;
  end case;
end;
$$;

-- =========================
-- 3) Mouvement de stock : seul le montant transféré sort du stock crédit
--    (la commission n'est jamais déduite du stock, comme pour tous les autres types)
-- =========================
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
    when p_category = 'CREDIT' and p_type::text in ('sewa', 'forfait', 'transfert_credit') then -p_amount
    when p_category = 'CREDIT' and p_type::text = 'achat' then p_amount
    else 0::numeric
  end;
$$;

-- Note : before_insert_transaction / after_insert_transaction / update_transaction / delete_transaction
-- appellent déjà calculate_commission_for_user et transaction_balance_delta de façon générique par type,
-- et after_insert_transaction fait déjà profit_credit = profit_credit + new.commission pour toute
-- transaction CREDIT. Aucune modification de ces fonctions n'est nécessaire : le cumul des commissions
-- pour "Transfert de crédit" fonctionne automatiquement dès que les fonctions ci-dessus sont en place.

-- =========================
-- 4) Effacer toutes les données (scopé strictement à l'utilisateur connecté)
--    Conserve : profil (nom, téléphone, numéros d'opération enregistrés) et réglages (taux, thème).
--    Remet à zéro : transactions, logs, exports, portefeuilles par numéro, soldes/bénéfices UV/crédit.
-- =========================
create or replace function public.clear_all_data()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Non authentifié';
  end if;

  delete from public.transactions where user_id = uid;
  delete from public.audit_logs where user_id = uid;
  delete from public.report_exports where user_id = uid;
  delete from public.operation_phone_wallets where user_id = uid;
  delete from public.user_journal_counter where user_id = uid;
  delete from public.clients where user_id = uid;

  update public.wallets set balance = 0, updated_at = now() where user_id = uid;
  update public.profiles set solde_uv = 0, solde_credit = 0, updated_at = now() where id = uid;
end;
$$;

revoke all on function public.clear_all_data() from public;
grant execute on function public.clear_all_data() to authenticated;

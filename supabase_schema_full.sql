-- CreditTrack - Schema SQL complet (Supabase/PostgreSQL)
-- Objectif: dynamiser auth, dashboard, operations, history, reports, settings.

create extension if not exists pgcrypto;

-- =========================
-- 1) Types metier
-- =========================
do $$
begin
  if not exists (select 1 from pg_type where typname = 'transaction_type') then
    create type public.transaction_type as enum (
      'depot',
      'retrait',
      'nafama',
      'transfert_uv',
      'transfert_c2c',
      'achat',
      'forfait',
      'sewa'
    );
  end if;
  if not exists (select 1 from pg_type where typname = 'transaction_category') then
    create type public.transaction_category as enum ('UV', 'CREDIT');
  end if;
  if not exists (select 1 from pg_type where typname = 'tx_status') then
    create type public.tx_status as enum ('pending', 'success', 'failed', 'cancelled');
  end if;
end
$$;

-- =========================
-- 2) Profil commerçant
-- =========================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  business_name text not null default 'Mon Commerce',
  owner_name text,
  phone_number text,
  operation_phones text[] not null default '{}',
  -- Colonnes legacy pour compatibilite avec le code existant.
  solde_uv numeric(16,2) not null default 0,
  solde_credit numeric(16,2) not null default 0,
  currency text not null default 'CFA',
  locale text not null default 'fr_SN',
  timezone text not null default 'Africa/Dakar',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================
-- 3) Portefeuilles (UV / CREDIT)
-- =========================
create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category public.transaction_category not null,
  balance numeric(16,2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, category)
);

-- =========================
-- 4) Clients
-- =========================
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  full_name text not null,
  phone text not null,
  last_transaction_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, phone)
);

-- =========================
-- 5) Transactions
-- =========================
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  client_id uuid references public.clients(id) on delete set null,
  type public.transaction_type not null,
  category public.transaction_category not null,
  status public.tx_status not null default 'success',
  amount numeric(16,2) not null check (amount >= 0),
  commission numeric(16,2) not null default 0 check (commission >= 0),
  net_profit numeric(16,2) not null default 0,
  balance_before numeric(16,2) not null default 0,
  balance_after numeric(16,2) not null default 0,
  client_name text not null,
  client_phone text not null,
  merchant_phone text,
  note text,
  external_ref text,
  device_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_transactions_user_created_at on public.transactions (user_id, created_at desc);
create index if not exists idx_transactions_user_merchant_phone on public.transactions (user_id, merchant_phone);
create index if not exists idx_transactions_user_category on public.transactions (user_id, category);
create index if not exists idx_transactions_user_type on public.transactions (user_id, type);
create index if not exists idx_transactions_client_phone on public.transactions (client_phone);

-- =========================
-- 6) Reçus imprimés / exports
-- =========================
create table if not exists public.receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  format text not null default '58mm',
  printed boolean not null default false,
  printed_at timestamptz,
  pdf_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.report_exports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  report_type text not null, -- daily, weekly, monthly, custom
  file_type text not null,   -- pdf, csv
  from_date date,
  to_date date,
  file_url text,
  created_at timestamptz not null default now()
);

-- =========================
-- 7) Paramètres (settings)
-- =========================
create table if not exists public.business_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  dark_mode boolean not null default false,
  language text not null default 'fr',
  auto_print_receipt boolean not null default false,
  receipt_header text,
  receipt_footer text,
  updated_at timestamptz not null default now()
);

create table if not exists public.printers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  mac_address text,
  paper_size text not null default '58mm',
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================
-- 8) Audit minimal
-- =========================
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  event text not null,
  entity text not null,
  entity_id uuid,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_audit_user_created_at on public.audit_logs (user_id, created_at desc);

-- =========================
-- 9) Fonctions utilitaires
-- =========================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

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

create or replace function public.ensure_profile_and_defaults()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, business_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'business_name', 'Mon Commerce'))
  on conflict (id) do nothing;

  insert into public.wallets (user_id, category) values (new.id, 'UV')
  on conflict (user_id, category) do nothing;

  insert into public.wallets (user_id, category) values (new.id, 'CREDIT')
  on conflict (user_id, category) do nothing;

  insert into public.business_settings (user_id) values (new.id)
  on conflict (user_id) do nothing;

  return new;
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

create or replace function public.after_insert_transaction()
returns trigger
language plpgsql
as $$
begin
  update public.wallets
  set balance = new.balance_after
  where user_id = new.user_id and category = new.category;

  -- Synchronise les soldes legacy dans profiles.
  if new.category = 'UV' then
    update public.profiles set solde_uv = new.balance_after where id = new.user_id;
  else
    update public.profiles set solde_credit = new.balance_after where id = new.user_id;
  end if;

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
      'commission', new.commission
    )
  );

  return new;
end;
$$;

-- =========================
-- 10) Triggers
-- =========================
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.ensure_profile_and_defaults();

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_wallets_updated_at on public.wallets;
create trigger trg_wallets_updated_at before update on public.wallets
for each row execute function public.set_updated_at();

drop trigger if exists trg_clients_updated_at on public.clients;
create trigger trg_clients_updated_at before update on public.clients
for each row execute function public.set_updated_at();

drop trigger if exists trg_transactions_updated_at on public.transactions;
create trigger trg_transactions_updated_at before update on public.transactions
for each row execute function public.set_updated_at();

drop trigger if exists trg_printers_updated_at on public.printers;
create trigger trg_printers_updated_at before update on public.printers
for each row execute function public.set_updated_at();

drop trigger if exists trg_business_settings_updated_at on public.business_settings;
create trigger trg_business_settings_updated_at before update on public.business_settings
for each row execute function public.set_updated_at();

drop trigger if exists trg_before_insert_transaction on public.transactions;
create trigger trg_before_insert_transaction
before insert on public.transactions
for each row execute function public.before_insert_transaction();

drop trigger if exists trg_after_insert_transaction on public.transactions;
create trigger trg_after_insert_transaction
after insert on public.transactions
for each row execute function public.after_insert_transaction();

-- =========================
-- 11) RLS
-- =========================
alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.clients enable row level security;
alter table public.transactions enable row level security;
alter table public.receipts enable row level security;
alter table public.report_exports enable row level security;
alter table public.business_settings enable row level security;
alter table public.printers enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
for select using (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
for update using (auth.uid() = id);

drop policy if exists wallets_all_own on public.wallets;
create policy wallets_all_own on public.wallets
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists clients_all_own on public.clients;
create policy clients_all_own on public.clients
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists transactions_all_own on public.transactions;
create policy transactions_all_own on public.transactions
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists receipts_all_own on public.receipts;
create policy receipts_all_own on public.receipts
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists report_exports_all_own on public.report_exports;
create policy report_exports_all_own on public.report_exports
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists business_settings_all_own on public.business_settings;
create policy business_settings_all_own on public.business_settings
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists printers_all_own on public.printers;
create policy printers_all_own on public.printers
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists audit_logs_select_own on public.audit_logs;
create policy audit_logs_select_own on public.audit_logs
for select using (auth.uid() = user_id);

drop policy if exists audit_logs_insert_own on public.audit_logs;
create policy audit_logs_insert_own on public.audit_logs
for insert with check (auth.uid() = user_id);


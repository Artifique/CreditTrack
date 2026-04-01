-- Migration : numéros d'opération (profil) + association aux transactions
-- À exécuter sur un projet Supabase existant (SQL Editor).

alter table public.profiles
  add column if not exists operation_phones text[] not null default '{}';

alter table public.transactions
  add column if not exists merchant_phone text;

create index if not exists idx_transactions_user_merchant_phone
  on public.transactions (user_id, merchant_phone);

comment on column public.profiles.operation_phones is 'Jusqu''à 3 numéros agent pour filtrer historique / stats.';
comment on column public.transactions.merchant_phone is 'Numéro d''opération choisi pour cette transaction.';

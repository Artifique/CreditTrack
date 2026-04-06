-- CreditTrak — correctif après migration v3
-- Si l’app affiche « Action non autorisée » à l’enregistrement d’une transaction,
-- c’est souvent un refus PostgreSQL sur user_journal_counter (insert/update du compteur)
-- ou des droits manquants sur operation_phone_wallets.
-- Exécute ce script une fois dans le SQL Editor Supabase.

-- 1) Journal : droits + RLS pour que le trigger (sous le rôle authenticated) puisse lire/écrire
grant select, insert, update, delete on public.user_journal_counter to authenticated;

alter table public.user_journal_counter enable row level security;

drop policy if exists user_journal_counter_own on public.user_journal_counter;
create policy user_journal_counter_own on public.user_journal_counter
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- 2) Portefeuilles par numéro (au cas où les grants par défaut manquent)
grant select, insert, update, delete on public.operation_phone_wallets to authenticated;

-- =============================================================================
-- CreditTrack — Vider / réinitialiser les données (Supabase → SQL Editor)
-- Irréversible : exporte ou sauvegarde avant si besoin.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A) TRANSACTIONS + CLIENTS + LOGS + EXPORTS (tu gardes comptes, profils, wallets)
-- Exécute ce bloc seul.
-- -----------------------------------------------------------------------------
begin;

truncate table public.transactions restart identity cascade;
truncate table public.clients restart identity cascade;
truncate table public.audit_logs restart identity cascade;
truncate table public.report_exports restart identity cascade;

update public.wallets set balance = 0, updated_at = now();
update public.profiles set solde_uv = 0, solde_credit = 0, updated_at = now();

commit;

-- -----------------------------------------------------------------------------
-- B) TOUT SUPPRIMER, Y COMPRIS LES COMPTES (Auth + toute l’app en cascade)
-- N’exécute PAS A et B dans la même session. Pour B : commente le bloc A
-- (ou annule la transaction), puis exécute uniquement ceci :
-- -----------------------------------------------------------------------------
/*
begin;
delete from auth.users;
commit;
*/

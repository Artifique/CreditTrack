-- =============================================================================
-- MIGRATION SUPABASE : OPTION ESPÈCE – CAISSE UNIVERSELLE AUTOMATIQUE
-- =============================================================================
-- 1. Ajoute la colonne solde_espece avec contrainte de non-négativité (>= 0).
-- 2. Fonction et trigger assurant la synchronisation automatique stricte
--    entre l'argent électronique Orange Money UV et l'argent liquide en caisse.
-- 3. Sécurité : Bloque toute opération diminuant le solde en dessous de 0 FCFA
--    avec le message d'erreur 'Solde Espèce insuffisant'.
-- =============================================================================

-- 1. Colonne solde_espece dans profiles avec contrainte >= 0
alter table public.profiles
add column if not exists solde_espece numeric(16,2) not null default 0;

-- S'assurer de la contrainte >= 0
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'chk_profiles_solde_espece_positive'
  ) then
    alter table public.profiles 
    add constraint chk_profiles_solde_espece_positive 
    check (solde_espece >= 0);
  end if;
end;
$$;

comment on column public.profiles.solde_espece is 
  'Solde physique universel en caisse (espèces), protégé (>= 0) et équilibré avec les flux Orange Money UV.';

-- 2. Fonction de calcul du delta espèce pour une transaction
create or replace function public.transaction_cash_delta(
  p_category public.transaction_category,
  p_type public.transaction_type,
  p_amount numeric
)
returns numeric
language sql
immutable
as $$
  select case
    -- Solde UV diminue -> Caisse Espèce augmente (+ montant)
    when p_category = 'UV' and p_type::text in ('depot', 'nafama', 'transfert_c2c') then p_amount
    -- Solde UV augmente -> Caisse Espèce diminue (- montant)
    when p_category = 'UV' and p_type::text in ('retrait', 'transfert_uv') then -p_amount
    -- Transfert profit interne et transactions Crédit : aucun impact caisse
    else 0::numeric
  end;
$$;

-- 3. Trigger de synchronisation et protection du solde Espèce
create or replace function public.process_transaction_cash_balance()
returns trigger
language plpgsql
security definer
as $$
declare
  v_current_cash numeric;
  v_delta numeric;
begin
  if tg_op = 'INSERT' then
    v_delta := public.transaction_cash_delta(new.category, new.type, new.amount);
    if v_delta <> 0 then
      select solde_espece into v_current_cash
      from public.profiles
      where id = new.user_id
      for update;

      if (v_current_cash + v_delta) < 0 then
        raise exception 'Solde Espèce insuffisant';
      end if;

      update public.profiles
      set solde_espece = solde_espece + v_delta,
          updated_at = now()
      where id = new.user_id;
    end if;

  elsif tg_op = 'DELETE' then
    -- Annulation : on inverse le delta
    v_delta := public.transaction_cash_delta(old.category, old.type, old.amount);
    if v_delta <> 0 then
      update public.profiles
      set solde_espece = greatest(0, solde_espece - v_delta),
          updated_at = now()
      where id = old.user_id;
    end if;

  elsif tg_op = 'UPDATE' then
    declare
      v_old_delta numeric;
      v_new_delta numeric;
      v_net_delta numeric;
    begin
      v_old_delta := public.transaction_cash_delta(old.category, old.type, old.amount);
      v_new_delta := public.transaction_cash_delta(new.category, new.type, new.amount);
      v_net_delta := v_new_delta - v_old_delta;

      if v_net_delta <> 0 then
        select solde_espece into v_current_cash
        from public.profiles
        where id = new.user_id
        for update;

        if (v_current_cash + v_net_delta) < 0 then
          raise exception 'Solde Espèce insuffisant';
        end if;

        update public.profiles
        set solde_espece = solde_espece + v_net_delta,
            updated_at = now()
        where id = new.user_id;
      end if;
    end;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_transaction_cash_balance on public.transactions;
create trigger trg_transaction_cash_balance
before insert or update or delete on public.transactions
for each row
execute function public.process_transaction_cash_balance();

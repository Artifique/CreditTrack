-- =============================================================================
-- MIGRATION SUPABASE : SOLDE ESPÈCE AVANT ET APRÈS DANS L'HISTORIQUE
-- =============================================================================
-- 1. Ajoute les colonnes solde_espece_avant et solde_espece_apres dans public.transactions
-- 2. Met à jour le trigger public.process_transaction_cash_balance() pour
--    enregistrer automatiquement solde_espece_avant et solde_espece_apres
--    sur chaque transaction créée.
-- =============================================================================

alter table public.transactions
add column if not exists solde_espece_avant numeric(16,2),
add column if not exists solde_espece_apres numeric(16,2);

comment on column public.transactions.solde_espece_avant is 'Solde physique en caisse (espèces) avant cette transaction';
comment on column public.transactions.solde_espece_apres is 'Solde physique en caisse (espèces) après cette transaction';

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

    select coalesce(solde_espece, 0) into v_current_cash
    from public.profiles
    where id = new.user_id
    for update;

    if v_current_cash is null then
      v_current_cash := 0;
    end if;

    -- Enregistrer l'état du solde espèce avant et après pour l'historique
    new.solde_espece_avant := v_current_cash;
    new.solde_espece_apres := v_current_cash + v_delta;

    if v_delta <> 0 then
      if (v_current_cash + v_delta) < 0 then
        raise exception 'Solde Espèce insuffisant';
      end if;

      update public.profiles
      set solde_espece = solde_espece + v_delta,
          updated_at = now()
      where id = new.user_id;
    end if;

  elsif tg_op = 'DELETE' then
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

      select coalesce(solde_espece, 0) into v_current_cash
      from public.profiles
      where id = new.user_id
      for update;

      new.solde_espece_avant := coalesce(old.solde_espece_avant, v_current_cash);
      new.solde_espece_apres := coalesce(new.solde_espece_avant, v_current_cash) + v_new_delta;

      if v_net_delta <> 0 then
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


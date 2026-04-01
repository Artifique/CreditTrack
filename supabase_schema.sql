-- SCHEMA POUR CREDITTRAK (SUPABASE / POSTGRESQL)

-- 1. Table des Profils (Commerçants)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name TEXT DEFAULT 'Mon Commerce',
  owner_name TEXT,
  phone_number TEXT,
  solde_uv DOUBLE PRECISION DEFAULT 0,
  solde_credit DOUBLE PRECISION DEFAULT 0,
  currency TEXT DEFAULT 'CFA',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Table des Transactions
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('depot', 'retrait', 'nafama', 'achat', 'forfait', 'sewa')),
  category TEXT NOT NULL CHECK (category IN ('UV', 'CREDIT')),
  client_name TEXT NOT NULL,
  client_phone TEXT NOT NULL,
  amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  commission DOUBLE PRECISION DEFAULT 0, -- NOUVEAU : Commission calculée
  solde_apres DOUBLE PRECISION DEFAULT 0,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fonctions pour mettre à jour les soldes automatiquement lors d'une transaction
CREATE OR REPLACE FUNCTION update_profile_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.category = 'UV' THEN
    IF NEW.type = 'retrait' THEN
      UPDATE profiles SET solde_uv = solde_uv + NEW.amount WHERE id = NEW.user_id;
    ELSE
      UPDATE profiles SET solde_uv = solde_uv - NEW.amount WHERE id = NEW.user_id;
    END IF;
  ELSIF NEW.category = 'CREDIT' THEN
    IF NEW.type = 'achat' THEN
      UPDATE profiles SET solde_credit = solde_credit + NEW.amount WHERE id = NEW.user_id;
    ELSE
      UPDATE profiles SET solde_credit = solde_credit - NEW.amount WHERE id = NEW.user_id;
    END IF;
  END IF;
  RETURN NEW;   
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_transaction_added
  AFTER INSERT ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION update_profile_balance();

-- Politiques RLS (Sécurité)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Propriétaire voit son profil" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Propriétaire modifie son profil" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Propriétaire voit ses transactions" ON transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Propriétaire ajoute ses transactions" ON transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

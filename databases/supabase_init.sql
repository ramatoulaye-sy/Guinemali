-- Script d'initialisation de la base de données Supabase pour Guinemali
-- Exécutez ce script dans l'éditeur SQL de votre projet Supabase

-- =====================================================
-- CRÉATION DES TABLES PRINCIPALES
-- =====================================================

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS utilisateurs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  pseudo TEXT UNIQUE NOT NULL,
  type_utilisateur TEXT NOT NULL DEFAULT 'victime' CHECK (type_utilisateur IN ('victime', 'aidant', 'ong', 'admin')),
  prenom TEXT,
  nom TEXT,
  telephone TEXT,
  region TEXT,
  date_naissance DATE,
  genre TEXT CHECK (genre IN ('homme', 'femme', 'autre')),
  photo_url TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des alertes
CREATE TABLE IF NOT EXISTS alertes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
  statut TEXT NOT NULL DEFAULT 'active' CHECK (statut IN ('active', 'resolue', 'annulee')),
  type_alerte TEXT NOT NULL DEFAULT 'urgence' CHECK (type_alerte IN ('urgence', 'harcelement', 'agression', 'autre')),
  position_lat DOUBLE PRECISION,
  position_lng DOUBLE PRECISION,
  adresse TEXT,
  description TEXT,
  niveau_urgence INTEGER DEFAULT 1 CHECK (niveau_urgence BETWEEN 1 AND 5),
  is_silent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des contacts d'urgence
CREATE TABLE IF NOT EXISTS contacts_urgence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
  nom TEXT NOT NULL,
  telephone TEXT NOT NULL,
  relation TEXT,
  is_primary BOOLEAN DEFAULT FALSE,
  is_notified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des preuves
CREATE TABLE IF NOT EXISTS preuves (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alerte_id UUID REFERENCES alertes(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('audio', 'video', 'photo', 'document')),
  fichier_url TEXT,
  nom_fichier TEXT,
  taille_fichier BIGINT,
  metadata JSONB,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des positions des alertes (pour le suivi GPS)
CREATE TABLE IF NOT EXISTS positions_alertes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alerte_id UUID REFERENCES alertes(id) ON DELETE CASCADE,
  position_lat DOUBLE PRECISION NOT NULL,
  position_lng DOUBLE PRECISION NOT NULL,
  precision_m DOUBLE PRECISION,
  vitesse_ms DOUBLE PRECISION,
  direction_deg DOUBLE PRECISION,
  altitude_m DOUBLE PRECISION,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
  titre TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'info' CHECK (type IN ('info', 'warning', 'error', 'success')),
  is_read BOOLEAN DEFAULT FALSE,
  data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des sessions utilisateur
CREATE TABLE IF NOT EXISTS sessions_utilisateur (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  device_info JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEX POUR LES PERFORMANCES
-- =====================================================

-- Index sur les utilisateurs
CREATE INDEX IF NOT EXISTS idx_utilisateurs_email ON utilisateurs(email);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_pseudo ON utilisateurs(pseudo);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_type ON utilisateurs(type_utilisateur);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_region ON utilisateurs(region);

-- Index sur les alertes
CREATE INDEX IF NOT EXISTS idx_alertes_utilisateur ON alertes(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_alertes_statut ON alertes(statut);
CREATE INDEX IF NOT EXISTS idx_alertes_type ON alertes(type_alerte);
CREATE INDEX IF NOT EXISTS idx_alertes_created ON alertes(created_at);
CREATE INDEX IF NOT EXISTS idx_alertes_position ON alertes USING GIST (
  ll_to_earth(position_lat, position_lng)
);

-- Index sur les contacts d'urgence
CREATE INDEX IF NOT EXISTS idx_contacts_utilisateur ON contacts_urgence(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_contacts_primary ON contacts_urgence(is_primary);

-- Index sur les preuves
CREATE INDEX IF NOT EXISTS idx_preuves_alerte ON preuves(alerte_id);
CREATE INDEX IF NOT EXISTS idx_preuves_type ON preuves(type);

-- Index sur les positions
CREATE INDEX IF NOT EXISTS idx_positions_alerte ON positions_alertes(alerte_id);
CREATE INDEX IF NOT EXISTS idx_positions_timestamp ON positions_alertes(timestamp);
CREATE INDEX IF NOT EXISTS idx_positions_position ON positions_alertes USING GIST (
  ll_to_earth(position_lat, position_lng)
);

-- Index sur les notifications
CREATE INDEX IF NOT EXISTS idx_notifications_utilisateur ON notifications(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at);

-- =====================================================
-- FONCTIONS ET TRIGGERS
-- =====================================================

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour updated_at
CREATE TRIGGER update_utilisateurs_updated_at 
  BEFORE UPDATE ON utilisateurs 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alertes_updated_at 
  BEFORE UPDATE ON alertes 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour vérifier qu'un utilisateur n'a qu'un seul contact primaire
CREATE OR REPLACE FUNCTION check_single_primary_contact()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_primary = TRUE THEN
    UPDATE contacts_urgence 
    SET is_primary = FALSE 
    WHERE utilisateur_id = NEW.utilisateur_id AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour les contacts primaires
CREATE TRIGGER check_primary_contact
  BEFORE INSERT OR UPDATE ON contacts_urgence
  FOR EACH ROW EXECUTE FUNCTION check_single_primary_contact();

-- =====================================================
-- POLITIQUES DE SÉCURITÉ (RLS)
-- =====================================================

-- Activer Row Level Security sur toutes les tables
ALTER TABLE utilisateurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE alertes ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts_urgence ENABLE ROW LEVEL SECURITY;
ALTER TABLE preuves ENABLE ROW LEVEL SECURITY;
ALTER TABLE positions_alertes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions_utilisateur ENABLE ROW LEVEL SECURITY;

-- Politiques pour les utilisateurs
CREATE POLICY "Users can view own profile" ON utilisateurs
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON utilisateurs
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON utilisateurs
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Politiques pour les alertes
CREATE POLICY "Users can view own alerts" ON alertes
  FOR SELECT USING (auth.uid() = utilisateur_id);

CREATE POLICY "Users can insert own alerts" ON alertes
  FOR INSERT WITH CHECK (auth.uid() = utilisateur_id);

CREATE POLICY "Users can update own alerts" ON alertes
  FOR UPDATE USING (auth.uid() = utilisateur_id);

-- Politiques pour les contacts d'urgence
CREATE POLICY "Users can manage own emergency contacts" ON contacts_urgence
  FOR ALL USING (auth.uid() = utilisateur_id);

-- Politiques pour les preuves
CREATE POLICY "Users can manage own evidence" ON preuves
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM alertes 
      WHERE alertes.id = preuves.alerte_id 
      AND alertes.utilisateur_id = auth.uid()
    )
  );

-- Politiques pour les positions
CREATE POLICY "Users can manage own positions" ON positions_alertes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM alertes 
      WHERE alertes.id = positions_alertes.alerte_id 
      AND alertes.utilisateur_id = auth.uid()
    )
  );

-- Politiques pour les notifications
CREATE POLICY "Users can manage own notifications" ON notifications
  FOR ALL USING (auth.uid() = utilisateur_id);

-- Politiques pour les sessions
CREATE POLICY "Users can manage own sessions" ON sessions_utilisateur
  FOR ALL USING (auth.uid() = utilisateur_id);

-- =====================================================
-- DONNÉES DE TEST (OPTIONNEL)
-- =====================================================

-- Insérer un utilisateur de test (décommentez si nécessaire)
-- INSERT INTO utilisateurs (email, pseudo, type_utilisateur, prenom, nom, region)
-- VALUES ('test@guinemali.com', 'testuser', 'victime', 'Test', 'User', 'Conakry');

-- =====================================================
-- VÉRIFICATION
-- =====================================================

-- Vérifier que toutes les tables ont été créées
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('utilisateurs', 'alertes', 'contacts_urgence', 'preuves', 'positions_alertes', 'notifications', 'sessions_utilisateur')
ORDER BY table_name;

-- Vérifier que RLS est activé
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('utilisateurs', 'alertes', 'contacts_urgence', 'preuves', 'positions_alertes', 'notifications', 'sessions_utilisateur');

-- Vérifier les politiques créées
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public';

PRINT '✅ Base de données Guinemali initialisée avec succès!';
PRINT '🔐 RLS activé et politiques de sécurité configurées';
PRINT '📊 Tables créées et index optimisés';
PRINT '🚀 Prêt pour le développement!';

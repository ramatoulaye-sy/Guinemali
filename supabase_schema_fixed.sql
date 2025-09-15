-- =====================================================
-- SCHEMA SUPABASE POUR GUINEMALI - VERSION CORRIGÉE
-- =====================================================

-- Activer l'extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABLE UTILISATEURS
-- =====================================================
CREATE TABLE IF NOT EXISTS utilisateurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pseudo VARCHAR(50) UNIQUE NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    pin_chiffre VARCHAR(255) NOT NULL,
    num_tel VARCHAR(20),
    type_utilisateur VARCHAR(20) NOT NULL CHECK (type_utilisateur IN ('victime', 'aidant', 'ong', 'admin')),
    langue VARCHAR(10) DEFAULT 'fr',
    region VARCHAR(100),
    actif BOOLEAN DEFAULT true,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    derniere_connexion TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABLE ALERTES
-- =====================================================
CREATE TABLE IF NOT EXISTS alertes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    type_alerte VARCHAR(50) DEFAULT 'urgence',
    niveau_danger INTEGER DEFAULT 5 CHECK (niveau_danger BETWEEN 1 AND 10),
    statut VARCHAR(20) DEFAULT 'active' CHECK (statut IN ('active', 'cancelled', 'resolved')),
    description TEXT,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_annulation TIMESTAMP WITH TIME ZONE,
    date_resolution TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABLE PREUVES
-- =====================================================
CREATE TABLE IF NOT EXISTS preuves (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alerte_id UUID NOT NULL REFERENCES alertes(id) ON DELETE CASCADE,
    type_preuve VARCHAR(20) NOT NULL CHECK (type_preuve IN ('audio', 'video', 'photo')),
    nom_fichier VARCHAR(255) NOT NULL,
    chemin_storage VARCHAR(500) NOT NULL,
    taille_fichier BIGINT,
    duree_secondes INTEGER,
    chiffre BOOLEAN DEFAULT true,
    synchronise BOOLEAN DEFAULT false,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. TABLE CONTACTS D'URGENCE
-- =====================================================
CREATE TABLE IF NOT EXISTS contacts_urgence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    num_tel VARCHAR(20) NOT NULL,
    relation VARCHAR(50),
    actif BOOLEAN DEFAULT true,
    priorite INTEGER DEFAULT 1 CHECK (priorite BETWEEN 1 AND 5),
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TABLE FORUM MESSAGES
-- =====================================================
CREATE TABLE IF NOT EXISTS forum_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    contenu TEXT NOT NULL,
    valide BOOLEAN DEFAULT false,
    date_post TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_moderation TIMESTAMP WITH TIME ZONE,
    moderateur_id UUID REFERENCES utilisateurs(id),
    raison_rejet TEXT,
    likes INTEGER DEFAULT 0,
    signalements INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. TABLE NOTIFICATIONS
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    alerte_id UUID REFERENCES alertes(id) ON DELETE CASCADE,
    type_notification VARCHAR(50) NOT NULL,
    titre VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    lu BOOLEAN DEFAULT false,
    date_envoi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEX POUR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_utilisateurs_pseudo ON utilisateurs(pseudo);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_type ON utilisateurs(type_utilisateur);
CREATE INDEX IF NOT EXISTS idx_alertes_utilisateur ON alertes(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_alertes_statut ON alertes(statut);
CREATE INDEX IF NOT EXISTS idx_preuves_alerte ON preuves(alerte_id);
CREATE INDEX IF NOT EXISTS idx_contacts_utilisateur ON contacts_urgence(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_forum_utilisateur ON forum_messages(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_forum_valide ON forum_messages(valide);

-- =====================================================
-- FONCTION RPC SIMPLIFIÉE
-- =====================================================
CREATE OR REPLACE FUNCTION login_by_pseudo_hash(
    p_pseudo VARCHAR(50),
    p_pin_hash VARCHAR(255)
)
RETURNS TABLE (
    id UUID,
    pseudo VARCHAR(50),
    prenom VARCHAR(100),
    type_utilisateur VARCHAR(20),
    langue VARCHAR(10),
    region VARCHAR(100),
    actif BOOLEAN,
    date_creation TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.pseudo,
        u.prenom,
        u.type_utilisateur,
        u.langue,
        u.region,
        u.actif,
        u.date_creation
    FROM utilisateurs u
    WHERE u.pseudo = p_pseudo 
      AND u.pin_chiffre = p_pin_hash 
      AND u.actif = true;
    
    IF FOUND THEN
        UPDATE utilisateurs 
        SET derniere_connexion = NOW(), updated_at = NOW()
        WHERE pseudo = p_pseudo;
    END IF;
END;
$$;

-- =====================================================
-- DÉSACTIVER RLS TEMPORAIREMENT POUR LES TESTS
-- =====================================================
ALTER TABLE utilisateurs DISABLE ROW LEVEL SECURITY;
ALTER TABLE alertes DISABLE ROW LEVEL SECURITY;
ALTER TABLE preuves DISABLE ROW LEVEL SECURITY;
ALTER TABLE contacts_urgence DISABLE ROW LEVEL SECURITY;
ALTER TABLE forum_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- DONNÉES DE TEST
-- =====================================================
INSERT INTO utilisateurs (
    pseudo, 
    prenom, 
    pin_chiffre, 
    type_utilisateur, 
    langue, 
    region
) VALUES (
    'test_user',
    'Utilisateur Test',
    'test_pin_hash',
    'victime',
    'fr',
    'Conakry'
) ON CONFLICT (pseudo) DO NOTHING;

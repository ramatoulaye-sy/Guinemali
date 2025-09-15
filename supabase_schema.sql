-- =====================================================
-- SCHEMA SUPABASE POUR GUINEMALI - VERSION PRO
-- =====================================================

-- 1. TABLE UTILISATEURS
-- =====================================================
CREATE TABLE IF NOT EXISTS utilisateurs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alerte_id UUID NOT NULL REFERENCES alertes(id) ON DELETE CASCADE,
    type_preuve VARCHAR(20) NOT NULL CHECK (type_preuve IN ('audio', 'video', 'photo')),
    nom_fichier VARCHAR(255) NOT NULL,
    chemin_storage VARCHAR(500) NOT NULL,
    taille_fichier BIGINT,
    duree_secondes INTEGER, -- Pour audio/video
    chiffre BOOLEAN DEFAULT true,
    synchronise BOOLEAN DEFAULT false,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. TABLE CONTACTS D'URGENCE
-- =====================================================
CREATE TABLE IF NOT EXISTS contacts_urgence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    contenu TEXT NOT NULL,
    valide BOOLEAN DEFAULT false, -- Modération a priori
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    alerte_id UUID REFERENCES alertes(id) ON DELETE CASCADE,
    type_notification VARCHAR(50) NOT NULL,
    titre VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    lu BOOLEAN DEFAULT false,
    date_envoi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. TABLE JOURNAL ACTIONS
-- =====================================================
CREATE TABLE IF NOT EXISTS journal_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    date_action TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEX POUR PERFORMANCE
-- =====================================================

-- Index pour utilisateurs
CREATE INDEX IF NOT EXISTS idx_utilisateurs_pseudo ON utilisateurs(pseudo);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_type ON utilisateurs(type_utilisateur);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_actif ON utilisateurs(actif);

-- Index pour alertes
CREATE INDEX IF NOT EXISTS idx_alertes_utilisateur ON alertes(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_alertes_statut ON alertes(statut);
CREATE INDEX IF NOT EXISTS idx_alertes_date ON alertes(date_creation);
CREATE INDEX IF NOT EXISTS idx_alertes_position ON alertes(latitude, longitude);

-- Index pour preuves
CREATE INDEX IF NOT EXISTS idx_preuves_alerte ON preuves(alerte_id);
CREATE INDEX IF NOT EXISTS idx_preuves_type ON preuves(type_preuve);
CREATE INDEX IF NOT EXISTS idx_preuves_sync ON preuves(synchronise);

-- Index pour contacts
CREATE INDEX IF NOT EXISTS idx_contacts_utilisateur ON contacts_urgence(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_contacts_actif ON contacts_urgence(actif);

-- Index pour forum
CREATE INDEX IF NOT EXISTS idx_forum_utilisateur ON forum_messages(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_forum_valide ON forum_messages(valide);
CREATE INDEX IF NOT EXISTS idx_forum_date ON forum_messages(date_post);

-- Index pour notifications
CREATE INDEX IF NOT EXISTS idx_notifications_utilisateur ON notifications(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_notifications_lu ON notifications(lu);

-- =====================================================
-- FONCTIONS RPC
-- =====================================================

-- Fonction de connexion par pseudo et PIN hashé
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
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier les identifiants
    RETURN QUERY
    SELECT 
        u.id,
        u.pseudo,
        u.prenom,
        u.type_utilisateur,
        u.langue,
        u.region,
        u.actif,
        u.created_at
    FROM utilisateurs u
    WHERE u.pseudo = p_pseudo 
      AND u.pin_chiffre = p_pin_hash 
      AND u.actif = true;
    
    -- Mettre à jour la dernière connexion si trouvé
    IF FOUND THEN
        UPDATE utilisateurs 
        SET derniere_connexion = NOW(), updated_at = NOW()
        WHERE pseudo = p_pseudo;
    END IF;
END;
$$;

-- Fonction pour créer une alerte
CREATE OR REPLACE FUNCTION create_emergency_alert(
    p_utilisateur_id UUID,
    p_latitude DECIMAL(10, 8),
    p_longitude DECIMAL(11, 8),
    p_type_alerte VARCHAR(50) DEFAULT 'urgence',
    p_niveau_danger INTEGER DEFAULT 5,
    p_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_alerte_id UUID;
BEGIN
    -- Créer l'alerte
    INSERT INTO alertes (
        utilisateur_id,
        latitude,
        longitude,
        type_alerte,
        niveau_danger,
        description
    ) VALUES (
        p_utilisateur_id,
        p_latitude,
        p_longitude,
        p_type_alerte,
        p_niveau_danger,
        p_description
    ) RETURNING id INTO v_alerte_id;
    
    -- Créer une notification
    INSERT INTO notifications (
        utilisateur_id,
        alerte_id,
        type_notification,
        titre,
        message
    ) VALUES (
        p_utilisateur_id,
        v_alerte_id,
        'alerte_created',
        'Alerte d''urgence créée',
        'Votre alerte d''urgence a été créée avec succès'
    );
    
    RETURN v_alerte_id;
END;
$$;

-- Fonction pour annuler une alerte
CREATE OR REPLACE FUNCTION cancel_alert(
    p_alerte_id UUID,
    p_utilisateur_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier que l'alerte appartient à l'utilisateur
    UPDATE alertes 
    SET 
        statut = 'cancelled',
        date_annulation = NOW(),
        updated_at = NOW()
    WHERE id = p_alerte_id 
      AND utilisateur_id = p_utilisateur_id
      AND statut = 'active';
    
    -- Créer une notification
    INSERT INTO notifications (
        utilisateur_id,
        alerte_id,
        type_notification,
        titre,
        message
    ) VALUES (
        p_utilisateur_id,
        p_alerte_id,
        'alerte_cancelled',
        'Alerte annulée',
        'Votre alerte d''urgence a été annulée'
    );
    
    RETURN FOUND;
END;
$$;

-- =====================================================
-- POLITIQUES RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE utilisateurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE alertes ENABLE ROW LEVEL SECURITY;
ALTER TABLE preuves ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts_urgence ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_actions ENABLE ROW LEVEL SECURITY;

-- Politiques pour utilisateurs
CREATE POLICY "Users can view own profile" ON utilisateurs
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON utilisateurs
    FOR UPDATE USING (auth.uid() = id);

-- Politiques pour alertes
CREATE POLICY "Users can view own alerts" ON alertes
    FOR SELECT USING (auth.uid() = utilisateur_id);

CREATE POLICY "Users can create own alerts" ON alertes
    FOR INSERT WITH CHECK (auth.uid() = utilisateur_id);

CREATE POLICY "Users can update own alerts" ON alertes
    FOR UPDATE USING (auth.uid() = utilisateur_id);

-- Politiques pour preuves
CREATE POLICY "Users can view proofs of own alerts" ON preuves
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM alertes 
            WHERE alertes.id = preuves.alerte_id 
            AND alertes.utilisateur_id = auth.uid()
        )
    );

CREATE POLICY "Users can create proofs for own alerts" ON preuves
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM alertes 
            WHERE alertes.id = preuves.alerte_id 
            AND alertes.utilisateur_id = auth.uid()
        )
    );

-- Politiques pour contacts
CREATE POLICY "Users can manage own contacts" ON contacts_urgence
    FOR ALL USING (auth.uid() = utilisateur_id);

-- Politiques pour forum (lecture anonyme, écriture authentifiée)
CREATE POLICY "Anyone can view approved forum messages" ON forum_messages
    FOR SELECT USING (valide = true);

CREATE POLICY "Authenticated users can create forum messages" ON forum_messages
    FOR INSERT WITH CHECK (auth.uid() = utilisateur_id);

-- Politiques pour notifications
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (auth.uid() = utilisateur_id);

CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = utilisateur_id);

-- Politiques pour journal
CREATE POLICY "Users can view own journal" ON journal_actions
    FOR SELECT USING (auth.uid() = utilisateur_id);

CREATE POLICY "System can create journal entries" ON journal_actions
    FOR INSERT WITH CHECK (true);

-- =====================================================
-- TRIGGERS POUR UPDATED_AT
-- =====================================================

-- Fonction trigger pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour updated_at
CREATE TRIGGER update_utilisateurs_updated_at BEFORE UPDATE ON utilisateurs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alertes_updated_at BEFORE UPDATE ON alertes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_preuves_updated_at BEFORE UPDATE ON preuves
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON contacts_urgence
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_forum_updated_at BEFORE UPDATE ON forum_messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- DONNÉES DE TEST (OPTIONNEL)
-- =====================================================

-- Insérer un utilisateur de test
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

-- =====================================================
-- FIN DU SCHEMA
-- =====================================================

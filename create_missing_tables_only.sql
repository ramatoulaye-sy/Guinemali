-- =====================================================
-- CRÉATION CONDITIONNELLE DES TABLES MANQUANTES
-- =====================================================

-- Activer l'extension UUID si nécessaire
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- CRÉER SEULEMENT LES TABLES QUI N'EXISTENT PAS
-- =====================================================

-- Table ALERTES (si elle n'existe pas)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'alertes') THEN
        CREATE TABLE alertes (
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
        RAISE NOTICE 'Table alertes créée';
    ELSE
        RAISE NOTICE 'Table alertes existe déjà';
    END IF;
END $$;

-- Table PREUVES (si elle n'existe pas)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'preuves') THEN
        CREATE TABLE preuves (
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
        RAISE NOTICE 'Table preuves créée';
    ELSE
        RAISE NOTICE 'Table preuves existe déjà';
    END IF;
END $$;

-- Table CONTACTS D'URGENCE (si elle n'existe pas)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'contacts_urgence') THEN
        CREATE TABLE contacts_urgence (
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
        RAISE NOTICE 'Table contacts_urgence créée';
    ELSE
        RAISE NOTICE 'Table contacts_urgence existe déjà';
    END IF;
END $$;

-- Table FORUM MESSAGES (si elle n'existe pas)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'forum_messages') THEN
        CREATE TABLE forum_messages (
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
        RAISE NOTICE 'Table forum_messages créée';
    ELSE
        RAISE NOTICE 'Table forum_messages existe déjà';
    END IF;
END $$;

-- Table NOTIFICATIONS (si elle n'existe pas)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        CREATE TABLE notifications (
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
        RAISE NOTICE 'Table notifications créée';
    ELSE
        RAISE NOTICE 'Table notifications existe déjà';
    END IF;
END $$;

-- =====================================================
-- CRÉER LES INDEX SEULEMENT S'ILS N'EXISTENT PAS
-- =====================================================

-- Index pour alertes
CREATE INDEX IF NOT EXISTS idx_alertes_utilisateur ON alertes(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_alertes_statut ON alertes(statut);

-- Index pour preuves
CREATE INDEX IF NOT EXISTS idx_preuves_alerte ON preuves(alerte_id);

-- Index pour contacts
CREATE INDEX IF NOT EXISTS idx_contacts_utilisateur ON contacts_urgence(utilisateur_id);

-- Index pour forum
CREATE INDEX IF NOT EXISTS idx_forum_utilisateur ON forum_messages(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_forum_valide ON forum_messages(valide);

-- =====================================================
-- DÉSACTIVER RLS TEMPORAIREMENT (si activé)
-- =====================================================

-- Vérifier et désactiver RLS si nécessaire
DO $$
BEGIN
    -- Désactiver RLS sur utilisateurs si activé
    IF EXISTS (
        SELECT 1 FROM pg_class 
        WHERE relname = 'utilisateurs' 
        AND relrowsecurity = true
    ) THEN
        ALTER TABLE utilisateurs DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS désactivé sur utilisateurs';
    ELSE
        RAISE NOTICE 'RLS déjà désactivé sur utilisateurs';
    END IF;

    -- Désactiver RLS sur les autres tables si elles existent
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'alertes') THEN
        ALTER TABLE alertes DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS désactivé sur alertes';
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'preuves') THEN
        ALTER TABLE preuves DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS désactivé sur preuves';
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'contacts_urgence') THEN
        ALTER TABLE contacts_urgence DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS désactivé sur contacts_urgence';
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'forum_messages') THEN
        ALTER TABLE forum_messages DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS désactivé sur forum_messages';
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'RLS désactivé sur notifications';
    END IF;
END $$;

-- =====================================================
-- RÉSUMÉ FINAL
-- =====================================================
SELECT 
    'Script terminé' as status,
    'Vérifiez les messages NOTICE ci-dessus pour voir ce qui a été créé' as message;

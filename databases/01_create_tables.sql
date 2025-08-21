-- ================================================
-- GUINÉMALI - SCRIPTS DE CRÉATION DES TABLES
-- Application de sécurité pour femmes et filles
-- ================================================

-- 1. Table des utilisateurs (étend auth.users de Supabase)
CREATE TABLE IF NOT EXISTS public.utilisateurs (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    pseudo VARCHAR(50) UNIQUE NOT NULL,
    pin_chiffre VARCHAR(255) NOT NULL, -- PIN crypté
    num_tel VARCHAR(20) UNIQUE,
    langue VARCHAR(10) DEFAULT 'fr',
    region VARCHAR(100),
    type_utilisateur VARCHAR(20) CHECK (type_utilisateur IN ('victime', 'aidant', 'ong', 'admin')) NOT NULL,
    actif BOOLEAN DEFAULT true,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    derniere_connexion TIMESTAMP WITH TIME ZONE,
    profil_complete BOOLEAN DEFAULT false
);

-- 2. Table des alertes
CREATE TABLE IF NOT EXISTS public.alertes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    utilisateur_id UUID REFERENCES public.utilisateurs(id) ON DELETE CASCADE NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    adresse_approximative TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    statut VARCHAR(20) CHECK (statut IN ('active', 'resolue', 'fausse_alerte', 'en_cours')) DEFAULT 'active',
    type_alerte VARCHAR(20) CHECK (type_alerte IN ('urgence', 'suivi', 'harcèlement', 'agression')) DEFAULT 'urgence',
    niveau_danger INTEGER CHECK (niveau_danger BETWEEN 1 AND 5) DEFAULT 3,
    nombre_aidants_notifies INTEGER DEFAULT 0,
    date_resolution TIMESTAMP WITH TIME ZONE,
    notes_resolution TEXT
);

-- 3. Table des preuves (audio, vidéo, photos)
CREATE TABLE IF NOT EXISTS public.preuves (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    alerte_id UUID REFERENCES public.alertes(id) ON DELETE CASCADE NOT NULL,
    type VARCHAR(20) CHECK (type IN ('audio', 'video', 'photo', 'texte')) NOT NULL,
    url TEXT, -- URL vers le fichier stocké
    url_locale TEXT, -- Chemin local pour le cache
    chiffrement VARCHAR(50), -- Type de chiffrement utilisé
    cle_chiffrement TEXT, -- Clé de chiffrement (cryptée elle-même)
    taille_fichier BIGINT,
    duree INTEGER, -- En secondes pour audio/vidéo
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    synchronise BOOLEAN DEFAULT false, -- Si uploadé vers Supabase
    hash_verification VARCHAR(64) -- Pour vérifier l'intégrité
);

-- 4. Table des contacts d'urgence
CREATE TABLE IF NOT EXISTS public.contacts_urgence (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    utilisateur_id UUID REFERENCES public.utilisateurs(id) ON DELETE CASCADE NOT NULL,
    nom VARCHAR(100) NOT NULL,
    numero_telephone VARCHAR(20) NOT NULL,
    relation VARCHAR(50), -- 'famille', 'ami', 'professionnel'
    priorite INTEGER CHECK (priorite BETWEEN 1 AND 3) DEFAULT 1,
    actif BOOLEAN DEFAULT true,
    date_ajout TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Table des messages du forum communautaire
CREATE TABLE IF NOT EXISTS public.messages_forum (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    utilisateur_id UUID REFERENCES public.utilisateurs(id) ON DELETE CASCADE NOT NULL,
    contenu TEXT NOT NULL,
    valide BOOLEAN DEFAULT false, -- Modération
    type_message VARCHAR(20) CHECK (type_message IN ('question', 'temoignage', 'conseil', 'alerte_communautaire')) DEFAULT 'question',
    date_post TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_moderation TIMESTAMP WITH TIME ZONE,
    moderateur_id UUID REFERENCES public.utilisateurs(id),
    nombre_likes INTEGER DEFAULT 0,
    nombre_reponses INTEGER DEFAULT 0,
    epingle BOOLEAN DEFAULT false
);

-- 6. Table des réponses au forum
CREATE TABLE IF NOT EXISTS public.reponses_forum (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    message_id UUID REFERENCES public.messages_forum(id) ON DELETE CASCADE NOT NULL,
    utilisateur_id UUID REFERENCES public.utilisateurs(id) ON DELETE CASCADE NOT NULL,
    contenu TEXT NOT NULL,
    date_reponse TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valide BOOLEAN DEFAULT false
);

-- 7. Table des ressources (guides, contacts, informations)
CREATE TABLE IF NOT EXISTS public.ressources (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titre VARCHAR(200) NOT NULL,
    description TEXT,
    type VARCHAR(30) CHECK (type IN ('guide', 'contact_ong', 'numero_urgence', 'conseil_juridique', 'soutien_psychologique')) NOT NULL,
    langue VARCHAR(10) DEFAULT 'fr',
    region VARCHAR(100),
    url TEXT,
    contenu_texte TEXT,
    numero_telephone VARCHAR(20),
    email VARCHAR(100),
    adresse TEXT,
    actif BOOLEAN DEFAULT true,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    derniere_modification TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    createur_id UUID REFERENCES public.utilisateurs(id)
);

-- 8. Table des notifications d'alertes
CREATE TABLE IF NOT EXISTS public.notifications_alertes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    alerte_id UUID REFERENCES public.alertes(id) ON DELETE CASCADE NOT NULL,
    destinataire_id UUID REFERENCES public.utilisateurs(id) ON DELETE CASCADE NOT NULL,
    type_notification VARCHAR(20) CHECK (type_notification IN ('sms', 'push', 'appel')) NOT NULL,
    statut VARCHAR(20) CHECK (statut IN ('envoye', 'delivre', 'lu', 'echec')) DEFAULT 'envoye',
    message TEXT,
    date_envoi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_lecture TIMESTAMP WITH TIME ZONE
);

-- 9. Table des aidants disponibles (réseau de soutien)
CREATE TABLE IF NOT EXISTS public.aidants_disponibles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    utilisateur_id UUID REFERENCES public.utilisateurs(id) ON DELETE CASCADE NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    rayon_action INTEGER DEFAULT 5000, -- en mètres
    specialites TEXT[], -- domaines d'expertise
    disponible BOOLEAN DEFAULT true,
    derniere_localisation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    nombre_interventions INTEGER DEFAULT 0,
    evaluation_moyenne DECIMAL(3, 2) DEFAULT 0
);

-- 10. Table de journalisation des actions (audit trail)
CREATE TABLE IF NOT EXISTS public.journal_actions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    utilisateur_id UUID REFERENCES public.utilisateurs(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB,
    adresse_ip INET,
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Script pour corriger la structure de la table utilisateurs
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure actuelle
SELECT 
    'STRUCTURE ACTUELLE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Ajouter la colonne 'prenom' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'prenom'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN prenom VARCHAR(100);
        RAISE NOTICE 'Colonne prenom ajoutée';
    ELSE
        RAISE NOTICE 'Colonne prenom existe déjà';
    END IF;
END $$;

-- 3. Ajouter la colonne 'pin_chiffre' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'pin_chiffre'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN pin_chiffre VARCHAR(255);
        RAISE NOTICE 'Colonne pin_chiffre ajoutée';
    ELSE
        RAISE NOTICE 'Colonne pin_chiffre existe déjà';
    END IF;
END $$;

-- 4. Ajouter la colonne 'num_tel' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'num_tel'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN num_tel VARCHAR(20);
        RAISE NOTICE 'Colonne num_tel ajoutée';
    ELSE
        RAISE NOTICE 'Colonne num_tel existe déjà';
    END IF;
END $$;

-- 5. Ajouter la colonne 'type_utilisateur' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'type_utilisateur'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN type_utilisateur VARCHAR(20) DEFAULT 'victime';
        RAISE NOTICE 'Colonne type_utilisateur ajoutée';
    ELSE
        RAISE NOTICE 'Colonne type_utilisateur existe déjà';
    END IF;
END $$;

-- 6. Ajouter la colonne 'actif' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'actif'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN actif BOOLEAN DEFAULT true;
        RAISE NOTICE 'Colonne actif ajoutée';
    ELSE
        RAISE NOTICE 'Colonne actif existe déjà';
    END IF;
END $$;

-- 7. Ajouter la colonne 'langue' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'langue'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN langue VARCHAR(10) DEFAULT 'fr';
        RAISE NOTICE 'Colonne langue ajoutée';
    ELSE
        RAISE NOTICE 'Colonne langue existe déjà';
    END IF;
END $$;

-- 8. Ajouter la colonne 'region' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'region'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN region VARCHAR(100);
        RAISE NOTICE 'Colonne region ajoutée';
    ELSE
        RAISE NOTICE 'Colonne region existe déjà';
    END IF;
END $$;

-- 9. Ajouter la colonne 'date_creation' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'date_creation'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Colonne date_creation ajoutée';
    ELSE
        RAISE NOTICE 'Colonne date_creation existe déjà';
    END IF;
END $$;

-- 10. Ajouter la colonne 'derniere_connexion' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'derniere_connexion'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN derniere_connexion TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Colonne derniere_connexion ajoutée';
    ELSE
        RAISE NOTICE 'Colonne derniere_connexion existe déjà';
    END IF;
END $$;

-- 11. Ajouter la colonne 'profil_complete' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'profil_complete'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN profil_complete BOOLEAN DEFAULT false;
        RAISE NOTICE 'Colonne profil_complete ajoutée';
    ELSE
        RAISE NOTICE 'Colonne profil_complete existe déjà';
    END IF;
END $$;

-- 12. Créer un index unique sur pseudo s'il n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'utilisateurs' 
        AND indexname = 'idx_utilisateurs_pseudo_unique'
        AND schemaname = 'public'
    ) THEN
        CREATE UNIQUE INDEX idx_utilisateurs_pseudo_unique ON utilisateurs(pseudo);
        RAISE NOTICE 'Index unique sur pseudo créé';
    ELSE
        RAISE NOTICE 'Index unique sur pseudo existe déjà';
    END IF;
END $$;

-- 13. Vérifier la structure finale
SELECT 
    'STRUCTURE FINALE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

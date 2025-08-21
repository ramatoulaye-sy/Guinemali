-- Script de mise à jour de la base de données Guinèmali
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure actuelle de la table
SELECT column_name, data_type, is_nullable, column_default
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
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN prenom VARCHAR(50);
    END IF;
END $$;

-- 3. Mettre à jour les données existantes (si des utilisateurs existent déjà)
UPDATE utilisateurs 
SET prenom = pseudo 
WHERE prenom IS NULL AND pseudo IS NOT NULL;

-- 4. Rendre la colonne 'prenom' obligatoire
ALTER TABLE utilisateurs ALTER COLUMN prenom SET NOT NULL;

-- 5. Ajouter un index unique sur 'prenom' pour éviter les doublons
CREATE UNIQUE INDEX IF NOT EXISTS idx_utilisateurs_prenom_unique 
ON utilisateurs(prenom);

-- 6. Mettre à jour les politiques RLS pour inclure 'prenom'
-- Supprimer l'ancienne politique d'inscription
DROP POLICY IF EXISTS "Inscription publique" ON utilisateurs;

-- Créer une nouvelle politique d'inscription avec 'prenom'
CREATE POLICY "Inscription publique" ON utilisateurs
FOR INSERT WITH CHECK (true);

-- Mettre à jour la politique de sélection
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leur profil" ON utilisateurs;
CREATE POLICY "Utilisateurs peuvent voir leur profil" ON utilisateurs
FOR SELECT USING (auth.uid() = id);

-- Mettre à jour la politique de modification
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leur profil" ON utilisateurs;
CREATE POLICY "Utilisateurs peuvent modifier leur profil" ON utilisateurs
FOR UPDATE USING (auth.uid() = id);

-- 7. Vérifier les politiques actuelles
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'utilisateurs';

-- 8. Vérifier la structure finale
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ================================================
-- CORRECTION DE LA TABLE ALERTES
-- ================================================

-- 9. Ajouter la colonne 'description' manquante à la table alertes
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'alertes' 
        AND column_name = 'description'
    ) THEN
        ALTER TABLE alertes ADD COLUMN description TEXT;
        RAISE NOTICE 'Colonne description ajoutée à la table alertes';
    ELSE
        RAISE NOTICE 'La colonne description existe déjà dans la table alertes';
    END IF;
END $$;

-- 10. Vérifier la structure de la table alertes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'alertes' 
AND table_schema = 'public'
ORDER BY ordinal_position;

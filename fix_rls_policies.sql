-- Script pour corriger les politiques RLS de la table utilisateurs
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer toutes les politiques existantes pour éviter les conflits
DROP POLICY IF EXISTS "Inscription autorisée" ON utilisateurs;
DROP POLICY IF EXISTS "Inscription publique" ON utilisateurs;
DROP POLICY IF EXISTS "Lecture publique" ON utilisateurs;
DROP POLICY IF EXISTS "Mise à jour profil" ON utilisateurs;
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leur profil" ON utilisateurs;
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leur profil" ON utilisateurs;

-- 2. Créer une politique d'insertion simple et claire
CREATE POLICY "Inscription libre" ON utilisateurs
FOR INSERT 
TO public
WITH CHECK (true);

-- 3. Créer une politique de lecture pour tous
CREATE POLICY "Lecture libre" ON utilisateurs
FOR SELECT 
TO public
USING (true);

-- 4. Créer une politique de mise à jour pour tous
CREATE POLICY "Mise à jour libre" ON utilisateurs
FOR UPDATE 
TO public
USING (true)
WITH CHECK (true);

-- 5. Vérifier les nouvelles politiques
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'utilisateurs' 
AND schemaname = 'public'
ORDER BY policyname;

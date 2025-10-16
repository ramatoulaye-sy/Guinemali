-- ===============================================
-- CORRECTION DES POLITIQUES RLS POUR AVATARS
-- ===============================================
-- Problème : Les utilisateurs créés directement dans la table utilisateurs
-- (sans Supabase Auth) n'ont pas de auth.uid(), donc les politiques échouent.
-- Solution : Utiliser des politiques basées sur le bucket uniquement (temporaire).

-- Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "Les utilisateurs peuvent uploader leur propre photo de profil" ON storage.objects;
DROP POLICY IF EXISTS "Tout le monde peut voir les photos de profil" ON storage.objects;
DROP POLICY IF EXISTS "Les utilisateurs peuvent mettre à jour leur propre photo" ON storage.objects;
DROP POLICY IF EXISTS "Les utilisateurs peuvent supprimer leur propre photo" ON storage.objects;
DROP POLICY IF EXISTS "Politique de test temporaire - avatars" ON storage.objects;

-- ===============================================
-- POLITIQUES PERMISSIVES POUR LE BUCKET AVATARS
-- ===============================================
-- ATTENTION : Ces politiques sont permissives car l'app n'utilise pas Supabase Auth
-- pour tous les utilisateurs. À sécuriser plus tard si nécessaire.

-- Politique INSERT : Tout utilisateur authentifié ou public peut uploader
CREATE POLICY "Avatars - Upload permissif"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'avatars');

-- Politique SELECT : Tout le monde peut voir les avatars
CREATE POLICY "Avatars - Lecture publique"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Politique UPDATE : Tout utilisateur peut mettre à jour
CREATE POLICY "Avatars - Mise à jour permissive"
ON storage.objects
FOR UPDATE
TO public
USING (bucket_id = 'avatars')
WITH CHECK (bucket_id = 'avatars');

-- Politique DELETE : Tout utilisateur peut supprimer
CREATE POLICY "Avatars - Suppression permissive"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'avatars');

-- ===============================================
-- NOTES DE SÉCURITÉ
-- ===============================================
-- Ces politiques sont permissives car :
-- 1. L'app utilise un système d'auth custom (table utilisateurs)
-- 2. Supabase Auth n'est pas utilisé pour tous les utilisateurs
-- 3. Les avatars sont publics de toute façon
-- 
-- Pour améliorer la sécurité plus tard :
-- - Migrer tous les utilisateurs vers Supabase Auth
-- - Utiliser auth.uid() dans les politiques
-- - Ajouter des validations sur la taille et le type de fichier

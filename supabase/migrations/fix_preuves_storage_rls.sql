-- =====================================================
-- Migration: Configuration du bucket preuves et RLS
-- Description: Crée le bucket 'preuves' et configure des politiques RLS permissives
-- =====================================================

-- 1. Créer le bucket 'preuves' s'il n'existe pas déjà
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'preuves',
  'preuves',
  false, -- Bucket privé (seuls les utilisateurs authentifiés peuvent accéder)
  104857600, -- 100 MB par fichier
  ARRAY[
    'audio/mpeg',
    'audio/mp4',
    'audio/x-m4a',
    'audio/aac',
    'audio/wav',
    'video/mp4',
    'video/mpeg',
    'video/quicktime',
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 104857600,
  allowed_mime_types = ARRAY[
    'audio/mpeg',
    'audio/mp4',
    'audio/x-m4a',
    'audio/aac',
    'audio/wav',
    'video/mp4',
    'video/mpeg',
    'video/quicktime',
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp'
  ];

-- 2. Supprimer toutes les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Les utilisateurs peuvent uploader leurs preuves" ON storage.objects;
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leurs preuves" ON storage.objects;
DROP POLICY IF EXISTS "Les utilisateurs peuvent mettre à jour leurs preuves" ON storage.objects;
DROP POLICY IF EXISTS "Les utilisateurs peuvent supprimer leurs preuves" ON storage.objects;
DROP POLICY IF EXISTS "Preuves - Upload permissif" ON storage.objects;
DROP POLICY IF EXISTS "Preuves - Lecture publique" ON storage.objects;
DROP POLICY IF EXISTS "Preuves - Mise à jour permissive" ON storage.objects;
DROP POLICY IF EXISTS "Preuves - Suppression permissive" ON storage.objects;

-- 3. Créer des politiques RLS PERMISSIVES pour le bucket 'preuves'
-- (Pour les tests - à affiner en production avec auth.uid())

-- Politique INSERT : Tout utilisateur peut uploader des preuves
CREATE POLICY "Preuves - Upload permissif"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'preuves');

-- Politique SELECT : Tout le monde peut voir les preuves (à affiner selon vos besoins)
CREATE POLICY "Preuves - Lecture permissive"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'preuves');

-- Politique UPDATE : Tout utilisateur peut mettre à jour les preuves
CREATE POLICY "Preuves - Mise à jour permissive"
ON storage.objects
FOR UPDATE
TO public
USING (bucket_id = 'preuves')
WITH CHECK (bucket_id = 'preuves');

-- Politique DELETE : Tout utilisateur peut supprimer les preuves
CREATE POLICY "Preuves - Suppression permissive"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'preuves');

-- =====================================================
-- NOTES :
-- =====================================================
-- Ces politiques sont TRÈS PERMISSIVES pour les tests.
-- En production, vous devriez les restreindre avec auth.uid() :
--
-- Exemple restrictif (à utiliser en production) :
-- 
-- CREATE POLICY "Preuves - Upload authentifié"
-- ON storage.objects
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (
--   bucket_id = 'preuves' 
--   AND (storage.foldername(name))[1] = auth.uid()::text
-- );
-- 
-- CREATE POLICY "Preuves - Lecture propriétaire"
-- ON storage.objects
-- FOR SELECT
-- TO authenticated
-- USING (
--   bucket_id = 'preuves' 
--   AND (storage.foldername(name))[1] = auth.uid()::text
-- );
-- =====================================================

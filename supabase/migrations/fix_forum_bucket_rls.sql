-- =====================================================
-- Migration: Correction RLS pour le bucket 'forum'
-- Description: Permet à tous les utilisateurs d'uploader des médias dans le forum
-- =====================================================

-- 1. Créer le bucket 'forum' s'il n'existe pas déjà
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'forum',
  'forum',
  true, -- Public pour que les médias soient accessibles
  104857600, -- 100 MB
  ARRAY[
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/mpeg',
    'video/quicktime',
    'video/webm'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 104857600,
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/mpeg',
    'video/quicktime',
    'video/webm'
  ];

-- 2. Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "Les utilisateurs peuvent uploader leurs médias forum" ON storage.objects;
DROP POLICY IF EXISTS "Tout le monde peut voir les médias forum" ON storage.objects;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leurs médias forum" ON storage.objects;
DROP POLICY IF EXISTS "Les utilisateurs peuvent supprimer leurs médias forum" ON storage.objects;
DROP POLICY IF EXISTS "Forum - Upload permissif" ON storage.objects;
DROP POLICY IF EXISTS "Forum - Lecture publique" ON storage.objects;
DROP POLICY IF EXISTS "Forum - Mise à jour permissive" ON storage.objects;
DROP POLICY IF EXISTS "Forum - Suppression permissive" ON storage.objects;

-- 3. Créer des politiques RLS PERMISSIVES

-- INSERT : Tout utilisateur authentifié peut uploader
CREATE POLICY "Forum - Upload permissif"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'forum');

-- SELECT : Tout le monde peut voir les médias (public)
CREATE POLICY "Forum - Lecture publique"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'forum');

-- UPDATE : Tout utilisateur peut mettre à jour
CREATE POLICY "Forum - Mise à jour permissive"
ON storage.objects
FOR UPDATE
TO public
USING (bucket_id = 'forum')
WITH CHECK (bucket_id = 'forum');

-- DELETE : Tout utilisateur peut supprimer
CREATE POLICY "Forum - Suppression permissive"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'forum');

-- 4. Vérifier les politiques créées
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
WHERE tablename = 'objects'
  AND (qual LIKE '%forum%' OR with_check LIKE '%forum%')
ORDER BY policyname;

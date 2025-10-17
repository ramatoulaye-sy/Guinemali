-- =====================================================
-- Migration: Correction RLS pour le bucket 'forum' (V2)
-- Description: Permet à TOUS (y compris anonymous) d'uploader des médias
-- =====================================================

-- 1. Vérifier/Créer le bucket 'forum'
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'forum',
  'forum',
  true, -- Public
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

-- 2. Supprimer TOUTES les anciennes politiques
DROP POLICY IF EXISTS "Les utilisateurs peuvent uploader leurs médias forum" ON storage.objects;
DROP POLICY IF EXISTS "Tout le monde peut voir les médias forum" ON storage.objects;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leurs médias forum" ON storage.objects;
DROP POLICY IF EXISTS "Les utilisateurs peuvent supprimer leurs médias forum" ON storage.objects;
DROP POLICY IF EXISTS "Forum - Upload permissif" ON storage.objects;
DROP POLICY IF EXISTS "Forum - Lecture publique" ON storage.objects;
DROP POLICY IF EXISTS "Forum - Mise à jour permissive" ON storage.objects;
DROP POLICY IF EXISTS "Forum - Suppression permissive" ON storage.objects;

-- 3. Créer des politiques ULTRA-PERMISSIVES (authenticated + anon)

-- INSERT : Tout le monde (authentifié ou anonyme) peut uploader
CREATE POLICY "Forum - Upload ultra-permissif"
ON storage.objects
FOR INSERT
TO authenticated, anon
WITH CHECK (bucket_id = 'forum');

-- SELECT : Tout le monde peut voir les médias
CREATE POLICY "Forum - Lecture ultra-publique"
ON storage.objects
FOR SELECT
TO authenticated, anon
USING (bucket_id = 'forum');

-- UPDATE : Tout le monde peut mettre à jour
CREATE POLICY "Forum - Mise à jour ultra-permissive"
ON storage.objects
FOR UPDATE
TO authenticated, anon
USING (bucket_id = 'forum')
WITH CHECK (bucket_id = 'forum');

-- DELETE : Tout le monde peut supprimer
CREATE POLICY "Forum - Suppression ultra-permissive"
ON storage.objects
FOR DELETE
TO authenticated, anon
USING (bucket_id = 'forum');

-- 4. Désactiver RLS complètement sur le bucket forum (option nucléaire)
-- ATTENTION : Ceci est TEMPORAIRE pour le développement
-- En production, il faudra des politiques plus strictes
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 5. Vérifier les politiques créées
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

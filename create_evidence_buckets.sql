-- Script pour créer les buckets de stockage des preuves dans Supabase
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Créer le bucket pour les photos de preuves
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'photo_evidence',
  'photo_evidence',
  false, -- privé
  10485760, -- 10MB max
  ARRAY['image/jpeg', 'image/png', 'image/webp']
);

-- 2. Créer le bucket pour les audios de preuves
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'audio_evidence',
  'audio_evidence',
  false, -- privé
  52428800, -- 50MB max
  ARRAY['audio/mp4', 'audio/mpeg', 'audio/wav', 'audio/aac']
);

-- 3. Créer le bucket pour les vidéos de preuves
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'video_evidence',
  'video_evidence',
  false, -- privé
  104857600, -- 100MB max
  ARRAY['video/mp4', 'video/quicktime', 'video/x-msvideo']
);

-- 4. Vérifier que les buckets ont été créés
SELECT id, name, public, file_size_limit, created_at 
FROM storage.buckets 
WHERE id IN ('photo_evidence', 'audio_evidence', 'video_evidence')
ORDER BY created_at;

-- NOTE: Les politiques RLS doivent être créées via l'interface Supabase :
-- 1. Aller dans Storage > Policies
-- 2. Créer les politiques pour chaque bucket :
--    - SELECT: auth.uid()::text = (storage.foldername(name))[1]
--    - INSERT: auth.uid()::text = (storage.foldername(name))[1]  
--    - UPDATE: auth.uid()::text = (storage.foldername(name))[1]
--    - DELETE: auth.uid()::text = (storage.foldername(name))[1]


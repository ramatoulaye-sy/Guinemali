-- =====================================================
-- Migration: Correction des author_name dans forum_posts
-- Description: Met à jour les author_name pour correspondre aux vrais prénoms/pseudos
-- =====================================================

-- Mettre à jour tous les posts avec le vrai prenom/pseudo de l'utilisateur
UPDATE public.forum_posts
SET author_name = COALESCE(u.prenom, u.pseudo, 'Anonyme')
FROM public.utilisateurs u
WHERE forum_posts.author_id = u.id
  AND (forum_posts.author_name IS NULL 
       OR forum_posts.author_name = 'Anonyme' 
       OR forum_posts.author_name = 'Saliou Djiba');

-- Afficher le résultat
DO $$
DECLARE
  updated_count INTEGER;
BEGIN
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RAISE NOTICE '✅ % posts mis à jour avec les vrais author_name', updated_count;
END $$;

-- Vérifier les résultats
SELECT 
  id,
  author_id,
  author_name,
  text,
  created_at
FROM public.forum_posts
ORDER BY created_at DESC
LIMIT 10;

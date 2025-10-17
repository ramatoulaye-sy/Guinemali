-- =====================================================
-- Migration: Réattribuer les anciens posts aux bons auteurs
-- Description: Correction manuelle des posts existants
-- =====================================================

-- ATTENTION : Cette migration réattribue les posts aux bons utilisateurs
-- Adapte les UUIDs selon tes besoins !

-- EXEMPLE : Si tu sais que certains posts ont été créés par "boul" :
-- UPDATE public.forum_posts
-- SET 
--   author_id = 'c89c1468-9a9f-4e22-97c2-38ddfc8726e2',
--   author_name = 'boul'
-- WHERE id = 'POST_ID_ICI';

-- EXEMPLE : Réattribuer un post à "moustapha" :
-- UPDATE public.forum_posts
-- SET 
--   author_id = '0db4f5ae-1b50-4181-b87e-81b936fab76e',
--   author_name = 'moustapha'
-- WHERE id = 'POST_ID_ICI';

-- EXEMPLE : Réattribuer un post à "ramatoulaye" :
-- UPDATE public.forum_posts
-- SET 
--   author_id = '8f5096e4-dae4-4acb-94f4-aa134cf29980',
--   author_name = 'ramatoulaye'
-- WHERE id = 'POST_ID_ICI' OR text LIKE '%ramatoulaye%';

-- OU SUPPRIMER TOUS LES ANCIENS POSTS (à utiliser avec PRÉCAUTION !) :
-- DELETE FROM public.forum_posts WHERE author_id = '8d4cedcf-d963-4fe7-b8ad-d2d4c4b7ea94';

-- Vérifier les résultats :
SELECT 
  fp.id,
  fp.author_id,
  fp.author_name,
  fp.text,
  fp.created_at,
  u.pseudo,
  u.prenom
FROM public.forum_posts fp
LEFT JOIN public.utilisateurs u ON fp.author_id = u.id
ORDER BY fp.created_at DESC
LIMIT 20;

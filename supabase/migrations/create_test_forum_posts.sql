-- =====================================================
-- Migration: Créer des posts de test pour tous les utilisateurs
-- Description: Ajoute des posts pour boul, moustapha, ramatoulaye, etc.
-- =====================================================

-- 1. Vérifier les utilisateurs existants
SELECT 
  id,
  pseudo,
  prenom,
  'Utilisateur: ' || COALESCE(prenom, pseudo) as info
FROM public.utilisateurs
ORDER BY date_creation DESC;

-- 2. Créer des posts de test pour chaque utilisateur
-- (Remplace les UUIDs par les vrais IDs de tes utilisateurs)

-- Post pour "boul" (remplace l'UUID par le vrai ID de boul)
INSERT INTO public.forum_posts (
  id,
  author_id,
  author_name,
  category,
  text,
  medias,
  created_at,
  liked_by
)
SELECT
  gen_random_uuid(),
  u.id,
  COALESCE(u.prenom, u.pseudo),
  'Tous',
  'Ceci est un post de test de ' || COALESCE(u.prenom, u.pseudo),
  '[]'::jsonb,
  NOW() - INTERVAL '1 day',
  '[]'::jsonb
FROM public.utilisateurs u
WHERE u.pseudo = 'boul'
  AND NOT EXISTS (
    SELECT 1 FROM public.forum_posts fp 
    WHERE fp.author_id = u.id 
    AND fp.text LIKE '%post de test%'
  );

-- Post pour "moustapha" (remplace par le vrai pseudo si différent)
INSERT INTO public.forum_posts (
  id,
  author_id,
  author_name,
  category,
  text,
  medias,
  created_at,
  liked_by
)
SELECT
  gen_random_uuid(),
  u.id,
  COALESCE(u.prenom, u.pseudo),
  'Conseil',
  'Salut tout le monde, je suis ' || COALESCE(u.prenom, u.pseudo) || ' !',
  '[]'::jsonb,
  NOW() - INTERVAL '2 hours',
  '[]'::jsonb
FROM public.utilisateurs u
WHERE u.pseudo ILIKE '%moustapha%'
  AND NOT EXISTS (
    SELECT 1 FROM public.forum_posts fp 
    WHERE fp.author_id = u.id 
    AND fp.text LIKE '%Salut tout le monde%'
  );

-- Post pour "ramatoulaye" (remplace par le vrai pseudo si différent)
INSERT INTO public.forum_posts (
  id,
  author_id,
  author_name,
  category,
  text,
  medias,
  created_at,
  liked_by
)
SELECT
  gen_random_uuid(),
  u.id,
  COALESCE(u.prenom, u.pseudo),
  'Témoignage',
  'Merci pour cette application ! - ' || COALESCE(u.prenom, u.pseudo),
  '[]'::jsonb,
  NOW() - INTERVAL '3 hours',
  '[]'::jsonb
FROM public.utilisateurs u
WHERE u.pseudo ILIKE '%ramatoulaye%'
  OR u.prenom ILIKE '%ramatoulaye%'
  AND NOT EXISTS (
    SELECT 1 FROM public.forum_posts fp 
    WHERE fp.author_id = u.id 
    AND fp.text LIKE '%Merci pour cette application%'
  );

-- 3. Vérifier les posts créés
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

-- 4. Compter les posts par utilisateur
SELECT 
  u.pseudo,
  u.prenom,
  COUNT(fp.id) as nombre_posts
FROM public.utilisateurs u
LEFT JOIN public.forum_posts fp ON u.id = fp.author_id
GROUP BY u.id, u.pseudo, u.prenom
ORDER BY nombre_posts DESC;

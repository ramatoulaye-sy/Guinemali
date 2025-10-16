-- =====================================================
-- Migration: Correction RLS pour forum_posts
-- Description: Permet à tous les utilisateurs de voir tous les posts du forum
-- =====================================================

-- Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leurs propres posts" ON public.forum_posts;
DROP POLICY IF EXISTS "Les utilisateurs peuvent créer des posts" ON public.forum_posts;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leurs propres posts" ON public.forum_posts;
DROP POLICY IF EXISTS "Les utilisateurs peuvent supprimer leurs propres posts" ON public.forum_posts;
DROP POLICY IF EXISTS "Forum posts - Lecture publique" ON public.forum_posts;
DROP POLICY IF EXISTS "Forum posts - Création authentifiée" ON public.forum_posts;
DROP POLICY IF EXISTS "Forum posts - Modification propriétaire" ON public.forum_posts;
DROP POLICY IF EXISTS "Forum posts - Suppression propriétaire" ON public.forum_posts;

-- Créer des politiques RLS PERMISSIVES pour le forum

-- Politique SELECT : TOUS les utilisateurs peuvent voir TOUS les posts
CREATE POLICY "Forum posts - Lecture publique"
ON public.forum_posts
FOR SELECT
TO public
USING (true); -- Pas de restriction !

-- Politique INSERT : Tout utilisateur authentifié peut créer un post
CREATE POLICY "Forum posts - Création publique"
ON public.forum_posts
FOR INSERT
TO public
WITH CHECK (true); -- Pas de restriction pour les tests

-- Politique UPDATE : Un utilisateur peut modifier ses propres posts
CREATE POLICY "Forum posts - Modification publique"
ON public.forum_posts
FOR UPDATE
TO public
USING (true) -- Pas de restriction pour les tests
WITH CHECK (true);

-- Politique DELETE : Un utilisateur peut supprimer ses propres posts
CREATE POLICY "Forum posts - Suppression publique"
ON public.forum_posts
FOR DELETE
TO public
USING (true); -- Pas de restriction pour les tests

-- =====================================================
-- NOTES :
-- =====================================================
-- Ces politiques sont TRÈS PERMISSIVES pour les tests.
-- En production, vous devriez restreindre UPDATE et DELETE :
--
-- Exemple restrictif (à utiliser en production) :
-- 
-- CREATE POLICY "Forum posts - Modification propriétaire"
-- ON public.forum_posts
-- FOR UPDATE
-- TO authenticated
-- USING (author_id = auth.uid())
-- WITH CHECK (author_id = auth.uid());
-- 
-- CREATE POLICY "Forum posts - Suppression propriétaire"
-- ON public.forum_posts
-- FOR DELETE
-- TO authenticated
-- USING (author_id = auth.uid());
-- =====================================================

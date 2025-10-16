-- =====================================================
-- Migration: CORRECTION COMPLÈTE RLS pour forum_posts
-- Description: Permet à TOUS les utilisateurs de voir TOUS les posts
-- Date: 2025-10-16
-- =====================================================

-- ÉTAPE 1 : Vérifier que la table existe
SELECT 'Vérification de la table forum_posts...' AS info;

-- ÉTAPE 2 : Activer RLS sur la table si ce n'est pas déjà fait
ALTER TABLE public.forum_posts ENABLE ROW LEVEL SECURITY;

-- ÉTAPE 3 : Supprimer TOUTES les anciennes politiques (peu importe leur nom)
DO $$ 
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'forum_posts'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.forum_posts', policy_record.policyname);
        RAISE NOTICE 'Politique supprimée: %', policy_record.policyname;
    END LOOP;
END $$;

-- ÉTAPE 4 : Créer UNE SEULE politique pour SELECT (lecture publique totale)
CREATE POLICY "forum_posts_select_all"
ON public.forum_posts
FOR SELECT
TO public
USING (true); -- AUCUNE restriction : tous les posts visibles par tous

-- ÉTAPE 5 : Créer UNE SEULE politique pour INSERT (création publique)
CREATE POLICY "forum_posts_insert_all"
ON public.forum_posts
FOR INSERT
TO public
WITH CHECK (true); -- Tout le monde peut créer des posts

-- ÉTAPE 6 : Créer UNE SEULE politique pour UPDATE (modification publique pour tests)
CREATE POLICY "forum_posts_update_all"
ON public.forum_posts
FOR UPDATE
TO public
USING (true)
WITH CHECK (true); -- Permissif pour les tests

-- ÉTAPE 7 : Créer UNE SEULE politique pour DELETE (suppression publique pour tests)
CREATE POLICY "forum_posts_delete_all"
ON public.forum_posts
FOR DELETE
TO public
USING (true); -- Permissif pour les tests

-- =====================================================
-- VÉRIFICATION FINALE
-- =====================================================
SELECT 
    'Politiques actives sur forum_posts :' AS info,
    policyname,
    cmd AS operation,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'forum_posts';

-- =====================================================
-- MESSAGE DE CONFIRMATION
-- =====================================================
DO $$ 
BEGIN
    RAISE NOTICE '✅ Migration RLS forum_posts terminée avec succès !';
    RAISE NOTICE '✅ Tous les utilisateurs peuvent maintenant voir TOUS les posts du forum.';
    RAISE NOTICE '⚠️ Ces politiques sont TRÈS PERMISSIVES (idéales pour les tests).';
END $$;

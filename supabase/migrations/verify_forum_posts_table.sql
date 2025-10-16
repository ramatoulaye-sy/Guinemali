-- =====================================================
-- Script de vérification : Table forum_posts
-- =====================================================

-- Vérifier que la table existe
SELECT 
    'Table forum_posts existe ?' AS question,
    EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'forum_posts'
    ) AS reponse;

-- Afficher la structure de la table
SELECT 
    'Structure de la table forum_posts :' AS info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'forum_posts'
ORDER BY ordinal_position;

-- Afficher les politiques RLS actuelles
SELECT 
    'Politiques RLS sur forum_posts :' AS info,
    policyname AS nom_politique,
    cmd AS operation,
    roles AS roles,
    qual AS using_clause,
    with_check AS with_check_clause
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'forum_posts';

-- Compter le nombre de posts
SELECT 
    'Nombre total de posts dans forum_posts :' AS info,
    COUNT(*) AS total
FROM public.forum_posts;

-- Afficher les 5 derniers posts avec leurs auteurs
SELECT 
    'Les 5 derniers posts :' AS info,
    id,
    author_id,
    author_name,
    category,
    LEFT(text, 50) AS extrait_texte,
    created_at
FROM public.forum_posts
ORDER BY created_at DESC
LIMIT 5;

-- Vérifier si RLS est activé
SELECT 
    'RLS activé sur forum_posts ?' AS question,
    relrowsecurity AS rls_active
FROM pg_class
WHERE relname = 'forum_posts'
AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

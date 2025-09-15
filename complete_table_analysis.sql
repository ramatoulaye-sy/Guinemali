-- Analyse complète de la table utilisateurs
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Structure complète de la table
SELECT 
    'STRUCTURE COMPLETE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Toutes les contraintes
SELECT 
    'TOUTES LES CONTRAINTES' as info,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.is_deferrable,
    tc.initially_deferred
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'utilisateurs' 
AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, tc.constraint_name;

-- 3. Tous les index
SELECT 
    'TOUS LES INDEX' as info,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'utilisateurs' 
AND schemaname = 'public'
ORDER BY indexname;

-- 4. Politiques RLS détaillées
SELECT 
    'POLITIQUES RLS DETAILLEES' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check,
    rowsecurity
FROM pg_policies 
WHERE tablename = 'utilisateurs' 
AND schemaname = 'public'
ORDER BY policyname;

-- 5. Vérifier si RLS est activé
SELECT 
    'RLS STATUS' as info,
    schemaname,
    tablename,
    rowsecurity,
    forcerowsecurity
FROM pg_tables 
WHERE tablename = 'utilisateurs' 
AND schemaname = 'public';

-- 6. Test d'insertion minimal
INSERT INTO utilisateurs (
    id, 
    pseudo, 
    prenom,
    pin_chiffre, 
    type_utilisateur, 
    actif
) VALUES (
    gen_random_uuid(),
    'test_analysis_' || extract(epoch from now())::text,
    'Test Analysis',
    'test_hash_123',
    'victime',
    true
) RETURNING id, pseudo, prenom, type_utilisateur, actif;

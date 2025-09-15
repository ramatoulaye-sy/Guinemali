-- Script pour interroger la structure existante de votre base de données
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Lister toutes les tables existantes
SELECT 
    'TABLES EXISTANTES' as info,
    schemaname,
    tablename,
    tableowner,
    hasindexes,
    hasrules,
    hastriggers,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. Structure détaillée de la table utilisateurs (si elle existe)
SELECT 
    'STRUCTURE UTILISATEURS' as info,
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

-- 3. Structure détaillée de la table users (si elle existe)
SELECT 
    'STRUCTURE USERS' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    numeric_precision,
    numeric_scale
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Vérifier s'il y a des tables d'authentification Supabase
SELECT 
    'TABLES AUTH SUPABASE' as info,
    schemaname,
    tablename
FROM pg_tables 
WHERE schemaname = 'auth'
ORDER BY tablename;

-- 5. Contraintes de la table utilisateurs
SELECT 
    'CONTRAINTES UTILISATEURS' as info,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
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

-- 6. Données existantes dans utilisateurs (premiers 5 enregistrements)
SELECT 
    'DONNEES EXISTANTES' as info,
    *
FROM utilisateurs 
LIMIT 5;

-- 7. Politiques RLS sur utilisateurs
SELECT 
    'POLITIQUES RLS' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'utilisateurs' 
AND schemaname = 'public'
ORDER BY policyname;

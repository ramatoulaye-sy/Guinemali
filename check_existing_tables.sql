-- =====================================================
-- VÉRIFICATION DES TABLES EXISTANTES DANS SUPABASE
-- =====================================================

-- 1. Vérifier toutes les tables existantes
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 2. Vérifier spécifiquement les tables de Guinemali
SELECT 
    table_name,
    CASE 
        WHEN table_name = 'utilisateurs' THEN '✅ Table utilisateurs existe'
        WHEN table_name = 'alertes' THEN '✅ Table alertes existe'
        WHEN table_name = 'preuves' THEN '✅ Table preuves existe'
        WHEN table_name = 'contacts_urgence' THEN '✅ Table contacts_urgence existe'
        WHEN table_name = 'forum_messages' THEN '✅ Table forum_messages existe'
        WHEN table_name = 'notifications' THEN '✅ Table notifications existe'
        ELSE '❓ Table inconnue: ' || table_name
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'utilisateurs', 
    'alertes', 
    'preuves', 
    'contacts_urgence', 
    'forum_messages', 
    'notifications'
)
ORDER BY table_name;

-- 3. Vérifier la structure de la table utilisateurs
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'utilisateurs'
ORDER BY ordinal_position;

-- 4. Vérifier les contraintes de la table utilisateurs
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' 
AND tc.table_name = 'utilisateurs'
ORDER BY tc.constraint_type, kcu.ordinal_position;

-- 5. Vérifier les extensions disponibles
SELECT 
    extname as extension_name,
    extversion as version
FROM pg_extension
WHERE extname IN ('uuid-ossp', 'pgcrypto');

-- 6. Vérifier les fonctions RPC existantes
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%login%' OR routine_name LIKE '%alert%'
ORDER BY routine_name;

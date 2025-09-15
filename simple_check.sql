-- =====================================================
-- VÉRIFICATION SIMPLE DES TABLES EXISTANTES
-- =====================================================

-- 1. Lister toutes les tables publiques
SELECT 
    'Tables existantes:' as info,
    table_name
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 2. Vérifier les tables Guinemali spécifiquement
SELECT 
    CASE 
        WHEN table_name = 'utilisateurs' THEN '✅ utilisateurs'
        WHEN table_name = 'alertes' THEN '✅ alertes'
        WHEN table_name = 'preuves' THEN '✅ preuves'
        WHEN table_name = 'contacts_urgence' THEN '✅ contacts_urgence'
        WHEN table_name = 'forum_messages' THEN '✅ forum_messages'
        WHEN table_name = 'notifications' THEN '✅ notifications'
        ELSE '❓ ' || table_name
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

-- 3. Vérifier les colonnes de la table utilisateurs
SELECT 
    'Colonnes utilisateurs:' as info,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'utilisateurs'
ORDER BY ordinal_position;

-- 4. Vérifier les extensions
SELECT 
    'Extensions:' as info,
    extname as extension_name
FROM pg_extension
WHERE extname IN ('uuid-ossp', 'pgcrypto');

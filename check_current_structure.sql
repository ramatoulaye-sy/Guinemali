-- Script pour vérifier la structure actuelle de la table utilisateurs
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Structure de la table
SELECT 
    'STRUCTURE TABLE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Contraintes de la table
SELECT 
    'CONTRAINTES' as info,
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
AND tc.table_schema = 'public';

-- 3. Index de la table
SELECT 
    'INDEX' as info,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'utilisateurs' 
AND schemaname = 'public';

-- 4. Politiques RLS actuelles
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

-- 5. Test d'insertion simple
INSERT INTO utilisateurs (
    id, 
    pseudo, 
    pin_chiffre, 
    type_utilisateur, 
    actif
) VALUES (
    gen_random_uuid(),
    'test_' || extract(epoch from now())::text,
    'test_hash',
    'victime',
    true
) RETURNING id, pseudo;

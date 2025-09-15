-- Test simple pour vérifier la structure
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier si la table utilisateurs existe
SELECT 
    'TABLE EXISTS' as info,
    EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'utilisateurs' 
        AND table_schema = 'public'
    ) as table_exists;

-- 2. Lister tous les champs de la table utilisateurs
SELECT 
    'CHAMPS UTILISATEURS' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Test d'insertion simple
INSERT INTO utilisateurs (
    id, 
    pseudo, 
    prenom,
    pin_chiffre, 
    type_utilisateur, 
    actif
) VALUES (
    gen_random_uuid(),
    'test_simple',
    'Test Simple',
    'test_hash',
    'victime',
    true
) RETURNING id, pseudo, prenom;

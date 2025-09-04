-- Script pour corriger la contrainte de clé étrangère
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la contrainte de clé étrangère actuelle
SELECT 
    'CONTRAINTE FK' as info,
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
AND tc.constraint_type = 'FOREIGN KEY';

-- 2. Supprimer la contrainte de clé étrangère si elle existe
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'utilisateurs' 
        AND constraint_name = 'utilisateurs_id_fkey'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE utilisateurs DROP CONSTRAINT utilisateurs_id_fkey;
        RAISE NOTICE 'Contrainte de clé étrangère supprimée';
    ELSE
        RAISE NOTICE 'Contrainte de clé étrangère n''existe pas';
    END IF;
END $$;

-- 3. Vérifier que la contrainte a été supprimée
SELECT 
    'CONTRAINTE FK APRES' as info,
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
AND tc.constraint_type = 'FOREIGN KEY';

-- 4. Test d'insertion directe
INSERT INTO utilisateurs (
    id, 
    pseudo, 
    prenom,
    pin_chiffre, 
    type_utilisateur, 
    actif
) VALUES (
    gen_random_uuid(),
    'test_direct_' || extract(epoch from now())::text,
    'Test Direct',
    'test_hash',
    'victime',
    true
) RETURNING id, pseudo, prenom;

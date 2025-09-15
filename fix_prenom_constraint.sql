-- Script pour corriger la contrainte NOT NULL sur la colonne prenom
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la contrainte actuelle sur prenom
SELECT 
    'CONTRAINTE PRENOM' as info,
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND column_name = 'prenom'
AND table_schema = 'public';

-- 2. Mettre à jour les enregistrements existants qui ont prenom NULL
UPDATE utilisateurs 
SET prenom = pseudo 
WHERE prenom IS NULL OR prenom = '';

-- 3. Rendre la colonne prenom obligatoire
ALTER TABLE utilisateurs ALTER COLUMN prenom SET NOT NULL;

-- 4. Vérifier que la contrainte est bien appliquée
SELECT 
    'CONTRAINTE APRES' as info,
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND column_name = 'prenom'
AND table_schema = 'public';

-- 5. Test d'insertion avec prenom
INSERT INTO utilisateurs (
    id, 
    pseudo, 
    prenom,
    pin_chiffre, 
    type_utilisateur, 
    actif
) VALUES (
    gen_random_uuid(),
    'test_prenom_' || extract(epoch from now())::text,
    'Test Prenom',
    'test_hash',
    'victime',
    true
) RETURNING id, pseudo, prenom;

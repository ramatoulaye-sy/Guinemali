-- Script de test complet pour l'authentification
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Nettoyer les données de test existantes
DELETE FROM utilisateurs WHERE pseudo LIKE 'test_%';

-- 2. Test d'inscription
INSERT INTO utilisateurs (
    id, 
    pseudo, 
    prenom,
    pin_chiffre, 
    type_utilisateur, 
    actif,
    langue,
    region
) VALUES (
    'test_user_12345',
    'test_user',
    'Test User',
    'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', -- hash de "hello"
    'victime',
    true,
    'fr',
    'Conakry'
) RETURNING id, pseudo, prenom, type_utilisateur, actif;

-- 3. Test de connexion (vérifier que l'utilisateur existe)
SELECT 
    'TEST CONNEXION' as info,
    id,
    pseudo,
    prenom,
    type_utilisateur,
    actif
FROM utilisateurs 
WHERE pseudo = 'test_user' 
AND pin_chiffre = 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'
AND actif = true;

-- 4. Vérifier la structure finale
SELECT 
    'STRUCTURE FINALE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ================================================
-- CRÉATION D'UN UTILISATEUR DE TEST POUR LA CONNEXION
-- ================================================

-- Nettoyer d'abord les utilisateurs de test existants
DELETE FROM public.utilisateurs WHERE pseudo LIKE 'test_%';

-- Créer un utilisateur de test
-- PIN: 1234 (hashé avec le salt 'guinemali_salt')
-- Hash SHA256 de '1234guinemali_salt' = 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'
INSERT INTO public.utilisateurs (
    id,
    prenom,
    pseudo,
    pin_chiffre,
    num_tel,
    langue,
    region,
    type_utilisateur,
    actif,
    date_creation,
    profil_complete
) VALUES (
    gen_random_uuid(),
    'Utilisateur Test',
    'test_user',
    'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
    '+1234567890',
    'fr',
    'Test Region',
    'victime',
    TRUE,
    NOW(),
    TRUE
);

-- Vérifier que l'utilisateur a été créé
SELECT 
    id,
    prenom,
    pseudo,
    type_utilisateur,
    actif,
    date_creation
FROM public.utilisateurs 
WHERE pseudo = 'test_user';

-- Tester la fonction de connexion
SELECT * FROM public.login_by_pseudo_hash(
    'test_user',
    'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'
);

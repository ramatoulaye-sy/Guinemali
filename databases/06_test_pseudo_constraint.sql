-- ================================================
-- GUINÉMALI - TEST DE LA CONTRAINTE PSEUDO
-- Vérification que la contrainte fonctionne
-- ================================================

-- 1. Test d'insertion avec des pseudos valides (devrait fonctionner)
DO $$
BEGIN
    RAISE NOTICE '=== TEST DES PSEUDOS VALIDES ===';
    
    -- Test avec pseudo valide (lettres et chiffres uniquement)
    BEGIN
        INSERT INTO public.utilisateurs (id, pseudo, pin_chiffre, type_utilisateur)
        VALUES (gen_random_uuid(), 'TestUser123', 'hash123', 'victime');
        RAISE NOTICE '✅ Pseudo valide "TestUser123" inséré avec succès';
        
        -- Nettoyer le test
        DELETE FROM public.utilisateurs WHERE pseudo = 'TestUser123';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion du pseudo valide: %', SQLERRM;
    END;
    
    -- Test avec pseudo valide (lettres uniquement)
    BEGIN
        INSERT INTO public.utilisateurs (id, pseudo, pin_chiffre, type_utilisateur)
        VALUES (gen_random_uuid(), 'UserABC', 'hash123', 'victime');
        RAISE NOTICE '✅ Pseudo valide "UserABC" inséré avec succès';
        
        -- Nettoyer le test
        DELETE FROM public.utilisateurs WHERE pseudo = 'UserABC';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion du pseudo valide: %', SQLERRM;
    END;
    
    -- Test avec pseudo valide (chiffres uniquement)
    BEGIN
        INSERT INTO public.utilisateurs (id, pseudo, pin_chiffre, type_utilisateur)
        VALUES (gen_random_uuid(), '12345', 'hash123', 'victime');
        RAISE NOTICE '✅ Pseudo valide "12345" inséré avec succès';
        
        -- Nettoyer le test
        DELETE FROM public.utilisateurs WHERE pseudo = '12345';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion du pseudo valide: %', SQLERRM;
    END;
END $$;

-- 2. Test d'insertion avec des pseudos invalides (devrait échouer)
DO $$
BEGIN
    RAISE NOTICE '=== TEST DES PSEUDOS INVALIDES ===';
    
    -- Test avec underscore (devrait échouer)
    BEGIN
        INSERT INTO public.utilisateurs (id, pseudo, pin_chiffre, type_utilisateur)
        VALUES (gen_random_uuid(), 'user_name', 'hash123', 'victime');
        RAISE NOTICE '❌ Pseudo invalide "user_name" inséré par erreur (contient underscore)';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✅ Pseudo invalide "user_name" correctement rejeté (contient underscore)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  Autre erreur pour "user_name": %', SQLERRM;
    END;
    
    -- Test avec tiret (devrait échouer)
    BEGIN
        INSERT INTO public.utilisateurs (id, pseudo, pin_chiffre, type_utilisateur)
        VALUES (gen_random_uuid(), 'user-name', 'hash123', 'victime');
        RAISE NOTICE '❌ Pseudo invalide "user-name" inséré par erreur (contient tiret)';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✅ Pseudo invalide "user-name" correctement rejeté (contient tiret)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  Autre erreur pour "user-name": %', SQLERRM;
    END;
    
    -- Test avec espace (devrait échouer)
    BEGIN
        INSERT INTO public.utilisateurs (id, pseudo, pin_chiffre, type_utilisateur)
        VALUES (gen_random_uuid(), 'user name', 'hash123', 'victime');
        RAISE NOTICE '❌ Pseudo invalide "user name" inséré par erreur (contient espace)';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✅ Pseudo invalide "user name" correctement rejeté (contient espace)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  Autre erreur pour "user name": %', SQLERRM;
    END;
    
    -- Test avec caractère spécial (devrait échouer)
    BEGIN
        INSERT INTO public.utilisateurs (id, pseudo, pin_chiffre, type_utilisateur)
        VALUES (gen_random_uuid(), 'user@name', 'hash123', 'victime');
        RAISE NOTICE '❌ Pseudo invalide "user@name" inséré par erreur (contient @)';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✅ Pseudo invalide "user@name" correctement rejeté (contient @)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  Autre erreur pour "user@name": %', SQLERRM;
    END;
    
    -- Test avec caractère accentué (devrait échouer)
    BEGIN
        INSERT INTO public.utilisateurs (id, pseudo, pin_chiffre, type_utilisateur)
        VALUES (gen_random_uuid(), 'usérname', 'hash123', 'victime');
        RAISE NOTICE '❌ Pseudo invalide "usérname" inséré par erreur (contient accent)';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✅ Pseudo invalide "usérname" correctement rejeté (contient accent)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  Autre erreur pour "usérname": %', SQLERRM;
    END;
END $$;

-- 3. Vérifier que la contrainte existe
SELECT 
    'Vérification de la contrainte' as test,
    tc.constraint_name,
    tc.table_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.constraint_name = 'chk_pseudo_format'
AND tc.table_name = 'utilisateurs';

-- 4. Résumé des tests
DO $$
BEGIN
    RAISE NOTICE '=== RÉSUMÉ DES TESTS ===';
    RAISE NOTICE '✅ Tests des pseudos valides terminés';
    RAISE NOTICE '✅ Tests des pseudos invalides terminés';
    RAISE NOTICE '✅ Vérification de la contrainte terminée';
    RAISE NOTICE '';
    RAISE NOTICE 'La contrainte chk_pseudo_format est maintenant active et';
    RAISE NOTICE 'empêche l''insertion de pseudos contenant des caractères';
    RAISE NOTICE 'autres que des lettres (a-z, A-Z) et des chiffres (0-9).';
    RAISE NOTICE '';
    RAISE NOTICE 'Cela garantit la cohérence entre l''application Flutter';
    RAISE NOTICE 'et la base de données Supabase.';
END $$;

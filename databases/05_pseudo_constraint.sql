-- ================================================
-- GUINÉMALI - AJOUT DE CONTRAINTE SUR LE PSEUDO
-- Contrainte pour n'accepter que lettres et chiffres
-- ================================================

-- 0. Vérifier l'état actuel des pseudos
DO $$
DECLARE
    total_count INTEGER;
    invalid_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_count FROM public.utilisateurs;
    SELECT COUNT(*) INTO invalid_count FROM public.utilisateurs WHERE pseudo !~ '^[a-zA-Z0-9]+$';
    
    RAISE NOTICE '=== ÉTAT ACTUEL ===';
    RAISE NOTICE 'Total utilisateurs: %', total_count;
    RAISE NOTICE 'Pseudos invalides: %', invalid_count;
    
    IF invalid_count > 0 THEN
        RAISE NOTICE '⚠️  Des pseudos invalides existent. Nettoyage nécessaire avant ajout de la contrainte.';
    ELSE
        RAISE NOTICE '✅ Tous les pseudos sont déjà valides.';
    END IF;
END $$;

-- 1. NETTOYER D'ABORD les pseudos existants qui ne respectent pas la règle
-- Supprimer tous les caractères non autorisés (underscores, tirets, espaces, etc.)
UPDATE public.utilisateurs 
SET pseudo = REGEXP_REPLACE(pseudo, '[^a-zA-Z0-9]', '', 'g')
WHERE pseudo !~ '^[a-zA-Z0-9]+$';

-- 2. Vérifier qu'il n'y a pas de pseudos vides après nettoyage
-- Si un pseudo devient vide après nettoyage, le remplacer par un pseudo par défaut
UPDATE public.utilisateurs 
SET pseudo = 'User' || id::text
WHERE pseudo = '' OR pseudo IS NULL;

-- 3. Vérifier qu'il n'y a pas de doublons après nettoyage
-- Si des doublons existent, ajouter un suffixe numérique
WITH duplicates AS (
    SELECT pseudo, COUNT(*) as count
    FROM public.utilisateurs 
    GROUP BY pseudo 
    HAVING COUNT(*) > 1
),
numbered AS (
    SELECT u.id, u.pseudo, 
           ROW_NUMBER() OVER (PARTITION BY u.pseudo ORDER BY u.date_creation) as rn
    FROM public.utilisateurs u
    INNER JOIN duplicates d ON u.pseudo = d.pseudo
)
UPDATE public.utilisateurs 
SET pseudo = CASE 
    WHEN n.rn = 1 THEN n.pseudo
    ELSE n.pseudo || n.rn::TEXT
END
FROM numbered n
WHERE utilisateurs.id = n.id AND n.rn > 1;

-- 4. Vérifier que tous les pseudos sont maintenant valides
DO $$
DECLARE
    total_count INTEGER;
    valid_count INTEGER;
    invalid_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_count FROM public.utilisateurs;
    SELECT COUNT(*) INTO valid_count FROM public.utilisateurs WHERE pseudo ~ '^[a-zA-Z0-9]+$';
    SELECT COUNT(*) INTO invalid_count FROM public.utilisateurs WHERE pseudo !~ '^[a-zA-Z0-9]+$';
    
    RAISE NOTICE '=== APRÈS NETTOYAGE ===';
    RAISE NOTICE 'Total utilisateurs: %', total_count;
    RAISE NOTICE 'Pseudos valides: %', valid_count;
    RAISE NOTICE 'Pseudos invalides: %', invalid_count;
    
    IF invalid_count = 0 THEN
        RAISE NOTICE '✅ Tous les pseudos sont maintenant valides. Ajout de la contrainte possible.';
    ELSE
        RAISE NOTICE '❌ Encore % pseudos invalides. Impossible d''ajouter la contrainte.', invalid_count;
        RETURN;
    END IF;
END $$;

-- 5. Maintenant ajouter la contrainte (seulement si tous les pseudos sont valides)
DO $$
BEGIN
    -- Vérifier si la contrainte existe déjà
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'chk_pseudo_format' 
        AND table_name = 'utilisateurs'
    ) THEN
        -- Vérifier une dernière fois que tous les pseudos sont valides
        IF NOT EXISTS (
            SELECT 1 FROM public.utilisateurs WHERE pseudo !~ '^[a-zA-Z0-9]+$'
        ) THEN
            -- Ajouter la contrainte CHECK pour le format du pseudo
            ALTER TABLE public.utilisateurs 
            ADD CONSTRAINT chk_pseudo_format 
            CHECK (pseudo ~ '^[a-zA-Z0-9]+$');
            
            RAISE NOTICE '✅ Contrainte chk_pseudo_format ajoutée avec succès';
        ELSE
            RAISE NOTICE '❌ Impossible d''ajouter la contrainte : des pseudos invalides persistent';
        END IF;
    ELSE
        RAISE NOTICE 'ℹ️  La contrainte chk_pseudo_format existe déjà';
    END IF;
END $$;

-- 6. Vérification finale
SELECT 
    'Vérification finale' as etape,
    COUNT(*) as total_utilisateurs,
    COUNT(CASE WHEN pseudo ~ '^[a-zA-Z0-9]+$' THEN 1 END) as pseudos_valides,
    COUNT(CASE WHEN pseudo !~ '^[a-zA-Z0-9]+$' THEN 1 END) as pseudos_invalides
FROM public.utilisateurs;

-- 7. Afficher un résumé final
DO $$
DECLARE
    total_count INTEGER;
    valid_count INTEGER;
    invalid_count INTEGER;
    constraint_exists BOOLEAN;
BEGIN
    SELECT COUNT(*) INTO total_count FROM public.utilisateurs;
    SELECT COUNT(*) INTO valid_count FROM public.utilisateurs WHERE pseudo ~ '^[a-zA-Z0-9]+$';
    SELECT COUNT(*) INTO invalid_count FROM public.utilisateurs WHERE pseudo !~ '^[a-zA-Z0-9]+$';
    
    SELECT EXISTS(
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'chk_pseudo_format' 
        AND table_name = 'utilisateurs'
    ) INTO constraint_exists;
    
    RAISE NOTICE '=== RÉSUMÉ FINAL ===';
    RAISE NOTICE 'Total utilisateurs: %', total_count;
    RAISE NOTICE 'Pseudos valides: %', valid_count;
    RAISE NOTICE 'Pseudos invalides: %', invalid_count;
    RAISE NOTICE 'Contrainte active: %', CASE WHEN constraint_exists THEN 'OUI' ELSE 'NON' END;
    
    IF invalid_count = 0 AND constraint_exists THEN
        RAISE NOTICE '🎉 SUCCÈS : Tous les pseudos respectent la contrainte et la contrainte est active !';
        RAISE NOTICE '✅ Plus de conflits d''inscription possibles';
    ELSIF invalid_count = 0 THEN
        RAISE NOTICE '⚠️  ATTENTION : Pseudos valides mais contrainte non ajoutée';
    ELSE
        RAISE NOTICE '❌ ÉCHEC : Des pseudos invalides persistent';
    END IF;
END $$;

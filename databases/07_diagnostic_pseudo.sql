-- ================================================
-- GUINÉMALI - DIAGNOSTIC DES PSEUDOS
-- Identifier les pseudos problématiques avant contrainte
-- ================================================

-- 1. Aperçu général de la table
SELECT 
    'Aperçu général' as section,
    COUNT(*) as total_utilisateurs,
    COUNT(CASE WHEN pseudo IS NULL THEN 1 END) as pseudos_nulls,
    COUNT(CASE WHEN pseudo = '' THEN 1 END) as pseudos_vides,
    COUNT(CASE WHEN pseudo !~ '^[a-zA-Z0-9]+$' THEN 1 END) as pseudos_invalides
FROM public.utilisateurs;

-- 2. Détail des pseudos invalides
SELECT 
    'Pseudos invalides' as section,
    id,
    pseudo,
    LENGTH(pseudo) as longueur,
    -- Identifier les caractères problématiques
    CASE 
        WHEN pseudo ~ '_' THEN 'Contient underscore'
        WHEN pseudo ~ '-' THEN 'Contient tiret'
        WHEN pseudo ~ ' ' THEN 'Contient espace'
        WHEN pseudo ~ '[^a-zA-Z0-9]' THEN 'Contient caractères spéciaux'
        ELSE 'Autre problème'
    END as probleme_identifie,
    -- Montrer les caractères problématiques
    REGEXP_REPLACE(pseudo, '[a-zA-Z0-9]', '', 'g') as caracteres_problematiques,
    date_creation
FROM public.utilisateurs 
WHERE pseudo !~ '^[a-zA-Z0-9]+$'
ORDER BY date_creation DESC;

-- 3. Exemples de pseudos valides pour comparaison
SELECT 
    'Pseudos valides (exemples)' as section,
    id,
    pseudo,
    LENGTH(pseudo) as longueur,
    date_creation
FROM public.utilisateurs 
WHERE pseudo ~ '^[a-zA-Z0-9]+$'
ORDER BY date_creation DESC
LIMIT 10;

-- 4. Statistiques par type de problème
WITH problem_types AS (
    SELECT 
        pseudo,
        CASE 
            WHEN pseudo ~ '_' THEN 'underscore'
            WHEN pseudo ~ '-' THEN 'tiret'
            WHEN pseudo ~ ' ' THEN 'espace'
            WHEN pseudo ~ '[^a-zA-Z0-9]' THEN 'caracteres_speciaux'
            ELSE 'autre'
        END as type_probleme
    FROM public.utilisateurs 
    WHERE pseudo !~ '^[a-zA-Z0-9]+$'
)
SELECT 
    'Statistiques par type de problème' as section,
    type_probleme,
    COUNT(*) as nombre_occurrences,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM public.utilisateurs), 2) as pourcentage
FROM problem_types
GROUP BY type_probleme
ORDER BY nombre_occurrences DESC;

-- 5. Prévisualisation des corrections
SELECT 
    'Prévisualisation des corrections' as section,
    id,
    pseudo as pseudo_actuel,
    -- Montrer ce que deviendra le pseudo après nettoyage
    REGEXP_REPLACE(pseudo, '[^a-zA-Z0-9]', '', 'g') as pseudo_apres_nettoyage,
    -- Si le pseudo devient vide, montrer le pseudo par défaut
    CASE 
        WHEN REGEXP_REPLACE(pseudo, '[^a-zA-Z0-9]', '', 'g') = '' 
        THEN 'User' || id::text
        ELSE REGEXP_REPLACE(pseudo, '[^a-zA-Z0-9]', '', 'g')
    END as pseudo_final,
    date_creation
FROM public.utilisateurs 
WHERE pseudo !~ '^[a-zA-Z0-9]+$'
ORDER BY date_creation DESC;

-- 6. Vérification des doublons potentiels après nettoyage
WITH cleaned_pseudos AS (
    SELECT 
        id,
        CASE 
            WHEN REGEXP_REPLACE(pseudo, '[^a-zA-Z0-9]', '', 'g') = '' 
            THEN 'User' || id::text
            ELSE REGEXP_REPLACE(pseudo, '[^a-zA-Z0-9]', '', 'g')
        END as pseudo_propre
    FROM public.utilisateurs
)
SELECT 
    'Doublons potentiels après nettoyage' as section,
    pseudo_propre,
    COUNT(*) as nombre_occurrences,
    STRING_AGG(id::text, ', ') as ids_utilisateurs
FROM cleaned_pseudos
GROUP BY pseudo_propre
HAVING COUNT(*) > 1
ORDER BY nombre_occurrences DESC;

-- 7. Recommandations
DO $$
DECLARE
    total_count INTEGER;
    invalid_count INTEGER;
    duplicate_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_count FROM public.utilisateurs;
    SELECT COUNT(*) INTO invalid_count FROM public.utilisateurs WHERE pseudo !~ '^[a-zA-Z0-9]+$';
    
    -- Compter les doublons potentiels
    WITH cleaned_pseudos AS (
        SELECT 
            CASE 
                WHEN REGEXP_REPLACE(pseudo, '[^a-zA-Z0-9]', '', 'g') = '' 
                THEN 'User' || id::text
                ELSE REGEXP_REPLACE(pseudo, '[^a-zA-Z0-9]', '', 'g')
            END as pseudo_propre
        FROM public.utilisateurs
    )
    SELECT COUNT(*) INTO duplicate_count
    FROM (
        SELECT pseudo_propre, COUNT(*) as cnt
        FROM cleaned_pseudos
        GROUP BY pseudo_propre
        HAVING COUNT(*) > 1
    ) as duplicates;
    
    RAISE NOTICE '=== RECOMMANDATIONS ===';
    RAISE NOTICE 'Total utilisateurs: %', total_count;
    RAISE NOTICE 'Pseudos à corriger: %', invalid_count;
    RAISE NOTICE 'Doublons potentiels après nettoyage: %', duplicate_count;
    
    IF invalid_count = 0 THEN
        RAISE NOTICE '✅ Aucune correction nécessaire. Vous pouvez ajouter la contrainte directement.';
    ELSIF invalid_count <= 10 THEN
        RAISE NOTICE '⚠️  Peu de corrections nécessaires (% pseudos). Nettoyage manuel recommandé.', invalid_count;
    ELSE
        RAISE NOTICE '🔧 Beaucoup de corrections nécessaires (% pseudos). Utilisez le script de nettoyage automatique.', invalid_count;
    END IF;
    
    IF duplicate_count > 0 THEN
        RAISE NOTICE '⚠️  Attention: % doublons potentiels après nettoyage. Résolution automatique recommandée.', duplicate_count;
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'PROCHAINES ÉTAPES:';
    IF invalid_count > 0 THEN
        RAISE NOTICE '1. Exécuter le script de nettoyage (05_pseudo_constraint.sql)';
        RAISE NOTICE '2. Vérifier que tous les pseudos sont valides';
        RAISE NOTICE '3. Ajouter la contrainte';
    ELSE
        RAISE NOTICE '1. Ajouter directement la contrainte';
    END IF;
    RAISE NOTICE '4. Tester avec le script de test (06_test_pseudo_constraint.sql)';
END $$;

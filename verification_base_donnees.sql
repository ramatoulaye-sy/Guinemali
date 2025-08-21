-- Script de vérification complète de la base de données Guinèmali
-- À exécuter dans l'éditeur SQL de Supabase

-- ========================================
-- 1. VÉRIFICATION DE LA STRUCTURE DE LA TABLE
-- ========================================

-- Structure actuelle de la table utilisateurs
SELECT 
    'STRUCTURE TABLE' as verification,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ========================================
-- 2. VÉRIFICATION DES UTILISATEURS EXISTANTS
-- ========================================

-- Nombre total d'utilisateurs
SELECT 
    'COMPTE TOTAL' as verification,
    COUNT(*) as nombre_utilisateurs
FROM utilisateurs;

-- Détail des utilisateurs existants
SELECT 
    'UTILISATEURS EXISTANTS' as verification,
    id,
    pseudo,
    prenom,
    type_utilisateur,
    actif,
    date_creation,
    derniere_connexion,
    profil_complete
FROM utilisateurs
ORDER BY date_creation DESC;

-- ========================================
-- 3. VÉRIFICATION DES DONNÉES MANQUANTES
-- ========================================

-- Utilisateurs sans prénom
SELECT 
    'SANS PRENOM' as verification,
    id,
    pseudo,
    type_utilisateur,
    actif
FROM utilisateurs 
WHERE prenom IS NULL OR prenom = '';

-- Utilisateurs sans pseudo
SELECT 
    'SANS PSEUDO' as verification,
    id,
    prenom,
    type_utilisateur,
    actif
FROM utilisateurs 
WHERE pseudo IS NULL OR pseudo = '';

-- Utilisateurs avec prénom et pseudo identiques
SELECT 
    'PRENOM = PSEUDO' as verification,
    id,
    pseudo,
    prenom,
    type_utilisateur
FROM utilisateurs 
WHERE pseudo = prenom;

-- ========================================
-- 4. VÉRIFICATION DES DOUBLONS
-- ========================================

-- Doublons de prénoms
SELECT 
    'DOUBLONS PRENOM' as verification,
    prenom,
    COUNT(*) as nombre_occurrences,
    array_agg(id) as ids_utilisateurs
FROM utilisateurs 
WHERE prenom IS NOT NULL
GROUP BY prenom 
HAVING COUNT(*) > 1;

-- Doublons de pseudos
SELECT 
    'DOUBLONS PSEUDO' as verification,
    pseudo,
    COUNT(*) as nombre_occurrences,
    array_agg(id) as ids_utilisateurs
FROM utilisateurs 
WHERE pseudo IS NOT NULL
GROUP BY pseudo 
HAVING COUNT(*) > 1;

-- ========================================
-- 5. VÉRIFICATION DES POLITIQUES RLS
-- ========================================

-- Politiques RLS actuelles
SELECT 
    'POLITIQUES RLS' as verification,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'utilisateurs';

-- ========================================
-- 6. VÉRIFICATION DES INDEX
-- ========================================

-- Index existants sur la table utilisateurs
SELECT 
    'INDEX EXISTANTS' as verification,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'utilisateurs';

-- ========================================
-- 7. VÉRIFICATION DES CONTRAINTES
-- ========================================

-- Contraintes de la table
SELECT 
    'CONTRAINTES' as verification,
    conname as nom_contrainte,
    contype as type_contrainte,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'utilisateurs'::regclass;

-- ========================================
-- 8. RÉSUMÉ DES PROBLÈMES POTENTIELS
-- ========================================

-- Résumé des vérifications
SELECT 
    'RÉSUMÉ' as verification,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun utilisateur sans prénom'
        ELSE '❌ ' || COUNT(*) || ' utilisateur(s) sans prénom'
    END as statut_prenom,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun utilisateur sans pseudo'
        ELSE '❌ ' || COUNT(*) || ' utilisateur(s) sans pseudo'
    END as statut_pseudo
FROM (
    SELECT 1 FROM utilisateurs WHERE prenom IS NULL OR prenom = ''
    UNION ALL
    SELECT 1 FROM utilisateurs WHERE pseudo IS NULL OR pseudo = ''
) as problemes;

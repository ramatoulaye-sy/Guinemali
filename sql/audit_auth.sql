-- AUDIT AUTHENTIFICATION – Guinèmali
-- À exécuter dans l'éditeur SQL de Supabase (SQL Editor)
-- Objectif: lister les tables/colonnes/contraintes/politiques et valider la logique de connexion

-- =============================
-- 0) Contexte / versions
-- =============================
SELECT 'DB VERSION' AS info, version();

-- =============================
-- 1) Tables du schéma public
-- =============================
SELECT 
  'PUBLIC TABLES' AS info,
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- =============================
-- 2) Structure de la table utilisateurs (si présente)
-- =============================
SELECT 
  'UTILISATEURS COLUMNS' AS info,
  column_name,
  data_type,
  is_nullable,
  column_default,
  character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'utilisateurs'
ORDER BY ordinal_position;

-- Contraintes
SELECT 
  'UTILISATEURS CONSTRAINTS' AS info,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
LEFT JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public' AND tc.table_name = 'utilisateurs'
ORDER BY tc.constraint_type, tc.constraint_name;

-- Index
SELECT 
  'UTILISATEURS INDEXES' AS info,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'utilisateurs'
ORDER BY indexname;

-- Politiques RLS
SELECT 
  'UTILISATEURS RLS' AS info,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'utilisateurs'
ORDER BY policyname;

-- Statut RLS (activé ?)
SELECT 
  'UTILISATEURS RLS STATUS' AS info,
  schemaname,
  tablename,
  rowsecurity,
  forcerowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'utilisateurs';

-- =============================
-- 3) Données utilisateurs – aperçu
-- =============================
SELECT 'UTILISATEURS COUNT' AS info, COUNT(*) AS total FROM utilisateurs;

SELECT 
  'UTILISATEURS SAMPLE' AS info,
  id,
  pseudo,
  prenom,
  type_utilisateur,
  actif,
  date_creation
FROM utilisateurs
ORDER BY date_creation DESC NULLS LAST
LIMIT 10;

-- Doublons potentiels
SELECT 'DUP PSEUDO' AS info, pseudo, COUNT(*) c FROM utilisateurs GROUP BY pseudo HAVING COUNT(*)>1;
SELECT 'DUP NUM_TEL' AS info, num_tel, COUNT(*) c FROM utilisateurs WHERE num_tel IS NOT NULL GROUP BY num_tel HAVING COUNT(*)>1;

-- =============================
-- 4) Validation logique de connexion
-- =============================
-- Remplacer :v_pseudo et :v_pin par vos valeurs lors de l'exécution manuelle
-- (Supabase SQL Editor ne supporte pas les variables; remplacez directement entre quotes.)

-- A) Ligne utilisateur
-- SELECT id, pseudo, pin_chiffre, actif FROM utilisateurs WHERE pseudo = ':v_pseudo';

-- B) Hash attendu (doit correspondre à la logique Flutter: sha256(pin + 'guinemali_salt'))
-- SELECT encode(digest(':v_pin' || 'guinemali_salt', 'sha256'), 'hex') AS expected_hash;

-- C) Comparaison robuste (retourne true/false)
-- SELECT COALESCE((
--   SELECT pin_chiffre FROM utilisateurs WHERE pseudo = ':v_pseudo' LIMIT 1
-- ) = (
--   SELECT encode(digest(':v_pin' || 'guinemali_salt', 'sha256'), 'hex')
-- ), false) AS pin_match;

-- =============================
-- 5) Aides au dépannage
-- =============================
-- Forcer un PIN connu (1234) pour un pseudo donné (REMPLACEZ LE PSEUDO)
-- UPDATE utilisateurs
-- SET pin_chiffre = encode(digest('1234' || 'guinemali_salt', 'sha256'), 'hex')
-- WHERE pseudo = 'PSEUDO_ICI';



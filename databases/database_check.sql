-- Script de vérification de la base de données Guinèmali
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier si la table utilisateurs existe
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'utilisateurs'
) as table_exists;

-- 2. Vérifier la structure de la table utilisateurs
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'utilisateurs'
ORDER BY ordinal_position;

-- 3. Vérifier les politiques RLS (Row Level Security)
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'utilisateurs';

-- 4. Vérifier les permissions sur la table
SELECT 
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'utilisateurs';

-- 5. Tester une insertion simple (si les permissions le permettent)
-- INSERT INTO utilisateurs (pseudo, pin_chiffre, type_utilisateur, langue, region, actif, date_creation)
-- VALUES ('test_user', 'hashed_pin_123', 'victime', 'fr', 'Conakry', true, NOW())
-- RETURNING id, pseudo, type_utilisateur;

-- 6. Vérifier le nombre d'utilisateurs existants
SELECT COUNT(*) as total_users FROM utilisateurs;

-- 7. Vérifier les types d'utilisateurs disponibles
SELECT DISTINCT type_utilisateur FROM utilisateurs;

-- 8. Vérifier la configuration de l'authentification
SELECT 
  name,
  setting
FROM pg_settings 
WHERE name LIKE '%auth%' OR name LIKE '%security%';

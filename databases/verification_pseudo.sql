-- Script de vérification et correction de la colonne pseudo
-- Exécutez ce script dans Supabase SQL Editor

-- 1. Vérifier la structure actuelle de la table
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default,
  character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes actuelles
SELECT 
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu 
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'utilisateurs' 
  AND tc.table_schema = 'public';

-- 3. Vérifier les index
SELECT 
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'utilisateurs';

-- 4. Vérifier les données existantes
SELECT 
  id,
  pseudo,
  prenom,
  type_utilisateur,
  actif,
  date_creation
FROM utilisateurs 
ORDER BY date_creation DESC 
LIMIT 5;

-- 5. Vérifier les politiques RLS
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'utilisateurs';

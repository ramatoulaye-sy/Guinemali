-- Script de correction automatique pour la colonne pseudo
-- Exécutez ce script dans Supabase SQL Editor

-- 1. Vérifier si la colonne pseudo existe et a les bonnes propriétés
DO $$
BEGIN
  -- Vérifier si la colonne pseudo existe
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'utilisateurs' 
      AND column_name = 'pseudo' 
      AND table_schema = 'public'
  ) THEN
    -- Créer la colonne pseudo si elle n'existe pas
    ALTER TABLE utilisateurs ADD COLUMN pseudo VARCHAR;
    RAISE NOTICE 'Colonne pseudo créée';
  END IF;
  
  -- Vérifier si la colonne pseudo est nullable
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'utilisateurs' 
      AND column_name = 'pseudo' 
      AND is_nullable = 'NO'
      AND table_schema = 'public'
  ) THEN
    -- Rendre la colonne nullable temporairement
    ALTER TABLE utilisateurs ALTER COLUMN pseudo DROP NOT NULL;
    RAISE NOTICE 'Contrainte NOT NULL supprimée de la colonne pseudo';
  END IF;
END $$;

-- 2. Mettre à jour les utilisateurs existants qui n'ont pas de pseudo
UPDATE utilisateurs 
SET pseudo = prenom 
WHERE pseudo IS NULL OR pseudo = '';

-- 3. Vérifier qu'il n'y a plus d'utilisateurs sans pseudo
SELECT 
  COUNT(*) as utilisateurs_sans_pseudo
FROM utilisateurs 
WHERE pseudo IS NULL OR pseudo = '';

-- 4. Maintenant, remettre la contrainte NOT NULL
ALTER TABLE utilisateurs ALTER COLUMN pseudo SET NOT NULL;

-- 5. Créer un index unique sur pseudo s'il n'existe pas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'utilisateurs' 
      AND indexname LIKE '%pseudo%'
  ) THEN
    CREATE UNIQUE INDEX idx_utilisateurs_pseudo ON utilisateurs(pseudo);
    RAISE NOTICE 'Index unique créé sur la colonne pseudo';
  END IF;
END $$;

-- 6. Vérifier la structure finale
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 7. Vérifier les données finales
SELECT 
  id,
  pseudo,
  prenom,
  type_utilisateur,
  actif
FROM utilisateurs 
ORDER BY date_creation DESC 
LIMIT 3;

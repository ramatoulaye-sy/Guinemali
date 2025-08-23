-- ================================================
-- CORRECTION DE LA BASE DE DONNÉES GUINÉMALI
-- Script à exécuter dans l'éditeur SQL de Supabase
-- ================================================

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE DE LA TABLE ALERTES
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'alertes' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. AJOUTER LA COLONNE 'description' MANQUANTE
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'alertes' 
        AND column_name = 'description'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.alertes ADD COLUMN description TEXT;
        RAISE NOTICE '✅ Colonne description ajoutée à la table alertes';
    ELSE
        RAISE NOTICE 'ℹ️ La colonne description existe déjà dans la table alertes';
    END IF;
END $$;

-- 3. VÉRIFIER LA STRUCTURE FINALE DE LA TABLE ALERTES
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_name = 'alertes' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. VÉRIFIER LES POLITIQUES RLS POUR LA TABLE ALERTES
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual
FROM pg_policies 
WHERE tablename = 'alertes'
AND schemaname = 'public';

-- 5. CRÉER OU METTRE À JOUR LES POLITIQUES RLS SI NÉCESSAIRE
-- Politique pour permettre aux utilisateurs de créer leurs propres alertes
DROP POLICY IF EXISTS "Utilisateurs peuvent créer leurs alertes" ON public.alertes;
CREATE POLICY "Utilisateurs peuvent créer leurs alertes" ON public.alertes
FOR INSERT WITH CHECK (auth.uid() = utilisateur_id);

-- Politique pour permettre aux utilisateurs de voir leurs propres alertes
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leurs alertes" ON public.alertes;
CREATE POLICY "Utilisateurs peuvent voir leurs alertes" ON public.alertes
FOR SELECT USING (auth.uid() = utilisateur_id);

-- Politique pour permettre aux utilisateurs de modifier leurs propres alertes
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leurs alertes" ON public.alertes;
CREATE POLICY "Utilisateurs peuvent modifier leurs alertes" ON public.alertes
FOR UPDATE USING (auth.uid() = utilisateur_id);

-- Politique pour permettre aux aidants de voir les alertes actives (pour les notifications)
DROP POLICY IF EXISTS "Aidants peuvent voir les alertes actives" ON public.alertes;
CREATE POLICY "Aidants peuvent voir les alertes actives" ON public.alertes
FOR SELECT USING (
    statut = 'active' 
    AND EXISTS (
        SELECT 1 FROM public.aidants_disponibles 
        WHERE utilisateur_id = auth.uid() 
        AND disponible = true
    )
);

-- 6. VÉRIFIER QUE LA TABLE EST BIEN ACTIVÉE POUR RLS
ALTER TABLE public.alertes ENABLE ROW LEVEL SECURITY;

-- 7. VÉRIFIER LES INDEX EXISTANTS
SELECT 
    indexname, 
    indexdef
FROM pg_indexes 
WHERE tablename = 'alertes'
AND schemaname = 'public';

-- 8. CRÉER DES INDEX POUR AMÉLIORER LES PERFORMANCES SI NÉCESSAIRE
-- Index sur utilisateur_id pour les requêtes par utilisateur
CREATE INDEX IF NOT EXISTS idx_alertes_utilisateur_id 
ON public.alertes(utilisateur_id);

-- Index sur statut pour filtrer les alertes actives
CREATE INDEX IF NOT EXISTS idx_alertes_statut 
ON public.alertes(statut);

-- Index sur timestamp pour l'ordre chronologique
CREATE INDEX IF NOT EXISTS idx_alertes_timestamp 
ON public.alertes(timestamp);

-- Index composite sur statut et timestamp
CREATE INDEX IF NOT EXISTS idx_alertes_statut_timestamp 
ON public.alertes(statut, timestamp);

-- 9. VÉRIFIER LES CONTRAINTES DE LA TABLE
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.alertes'::regclass;

-- 10. TESTER L'INSERTION D'UNE ALERTE (OPTIONNEL - À SUPPRIMER EN PRODUCTION)
-- INSERT INTO public.alertes (
--     utilisateur_id,
--     latitude,
--     longitude,
--     type_alerte,
--     niveau_danger,
--     statut,
--     description
-- ) VALUES (
--     '00000000-0000-0000-0000-000000000000', -- Remplacer par un vrai UUID
--     9.5370, -- Latitude de Conakry
--     -13.6785, -- Longitude de Conakry
--     'urgence',
--     5,
--     'active',
--     'Test de la colonne description'
-- );

-- 11. VÉRIFIER LES DONNÉES EXISTANTES (SI IL Y EN A)
SELECT 
    COUNT(*) as total_alertes,
    COUNT(description) as alertes_avec_description,
    COUNT(*) - COUNT(description) as alertes_sans_description
FROM public.alertes;

-- 12. MESSAGE DE CONFIRMATION
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'CORRECTION TERMINÉE AVEC SUCCÈS!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'La colonne description a été ajoutée à la table alertes';
    RAISE NOTICE 'Les politiques RLS ont été mises à jour';
    RAISE NOTICE 'Les index de performance ont été créés';
    RAISE NOTICE '========================================';
END $$;

-- ===============================================
-- CORRECTION DES POLITIQUES RLS POUR positions_alertes
-- ===============================================
-- Problème : Les positions GPS des alertes ne peuvent pas être synchronisées
-- car les politiques RLS bloquent les insertions/updates.
-- Solution : Créer des politiques permissives pour positions_alertes.

-- Supprimer toutes les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir les positions de leurs alertes" ON public.positions_alertes;
DROP POLICY IF EXISTS "Les utilisateurs peuvent ajouter des positions à leurs alertes" ON public.positions_alertes;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier les positions de leurs alertes" ON public.positions_alertes;
DROP POLICY IF EXISTS "Positions alertes - Lecture permissive" ON public.positions_alertes;
DROP POLICY IF EXISTS "Positions alertes - Insertion permissive" ON public.positions_alertes;
DROP POLICY IF EXISTS "Positions alertes - Modification permissive" ON public.positions_alertes;

-- ===============================================
-- POLITIQUES PERMISSIVES POUR positions_alertes
-- ===============================================

-- Politique SELECT : Lecture des positions
CREATE POLICY "Positions alertes - Lecture permissive"
ON public.positions_alertes
FOR SELECT
TO public
USING (true);

-- Politique INSERT : Ajout de positions
CREATE POLICY "Positions alertes - Insertion permissive"
ON public.positions_alertes
FOR INSERT
TO public
WITH CHECK (true);

-- Politique UPDATE : Modification de positions
CREATE POLICY "Positions alertes - Modification permissive"
ON public.positions_alertes
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- ===============================================
-- NOTES
-- ===============================================
-- Ces politiques sont permissives car l'app utilise un système d'auth custom.
-- Les positions sont liées aux alertes via alerte_id.

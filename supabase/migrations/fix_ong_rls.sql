-- =====================================================
-- Migration: Configuration RLS pour la table ONG
-- Description: Permet à tous les utilisateurs de voir toutes les ONG
-- =====================================================

-- Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir les ONG" ON public.ong;
DROP POLICY IF EXISTS "ONG - Lecture publique" ON public.ong;

-- Politique SELECT : Tous les utilisateurs peuvent voir toutes les ONG
CREATE POLICY "ONG - Lecture publique"
ON public.ong
FOR SELECT
TO public
USING (true); -- Pas de restriction, toutes les ONG sont visibles

-- Note: Les politiques INSERT, UPDATE, DELETE ne sont pas nécessaires 
-- car seuls les administrateurs doivent pouvoir modifier les ONG
-- Ces opérations seront gérées via la plateforme ONG séparée

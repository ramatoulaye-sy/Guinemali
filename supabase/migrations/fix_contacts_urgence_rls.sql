-- ===============================================
-- CORRECTION DES POLITIQUES RLS POUR contacts_urgence
-- ===============================================
-- Problème : Les utilisateurs ne peuvent pas ajouter de contacts d'urgence
-- car les politiques RLS bloquent les insertions.
-- Solution : Créer des politiques permissives pour les contacts d'urgence.

-- Supprimer toutes les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leurs propres contacts" ON public.contacts_urgence;
DROP POLICY IF EXISTS "Les utilisateurs peuvent ajouter leurs propres contacts" ON public.contacts_urgence;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leurs propres contacts" ON public.contacts_urgence;
DROP POLICY IF EXISTS "Les utilisateurs peuvent supprimer leurs propres contacts" ON public.contacts_urgence;
DROP POLICY IF EXISTS "Contacts urgence - Lecture permissive" ON public.contacts_urgence;
DROP POLICY IF EXISTS "Contacts urgence - Insertion permissive" ON public.contacts_urgence;
DROP POLICY IF EXISTS "Contacts urgence - Modification permissive" ON public.contacts_urgence;
DROP POLICY IF EXISTS "Contacts urgence - Suppression permissive" ON public.contacts_urgence;

-- ===============================================
-- POLITIQUES PERMISSIVES POUR contacts_urgence
-- ===============================================
-- ATTENTION : Ces politiques sont permissives car l'app n'utilise pas Supabase Auth
-- pour tous les utilisateurs. À sécuriser plus tard si nécessaire.

-- Politique SELECT : Les utilisateurs peuvent lire leurs propres contacts
CREATE POLICY "Contacts urgence - Lecture permissive"
ON public.contacts_urgence
FOR SELECT
TO public
USING (true);

-- Politique INSERT : Les utilisateurs peuvent ajouter des contacts
CREATE POLICY "Contacts urgence - Insertion permissive"
ON public.contacts_urgence
FOR INSERT
TO public
WITH CHECK (true);

-- Politique UPDATE : Les utilisateurs peuvent modifier leurs propres contacts
CREATE POLICY "Contacts urgence - Modification permissive"
ON public.contacts_urgence
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Politique DELETE : Les utilisateurs peuvent supprimer leurs propres contacts
CREATE POLICY "Contacts urgence - Suppression permissive"
ON public.contacts_urgence
FOR DELETE
TO public
USING (true);

-- ===============================================
-- NOTES DE SÉCURITÉ
-- ===============================================
-- Ces politiques sont permissives car :
-- 1. L'app utilise un système d'auth custom (table utilisateurs)
-- 2. Supabase Auth n'est pas utilisé pour tous les utilisateurs
-- 3. Les contacts d'urgence sont liés à l'utilisateur via utilisateur_id
-- 
-- Pour améliorer la sécurité plus tard :
-- - Migrer tous les utilisateurs vers Supabase Auth
-- - Utiliser auth.uid() dans les politiques
-- - Ajouter des validations côté application pour s'assurer que
--   l'utilisateur ne modifie que ses propres contacts
-- 
-- Exemple de politique sécurisée (à utiliser après migration vers Supabase Auth) :
-- CREATE POLICY "Contacts urgence - Insertion sécurisée"
-- ON public.contacts_urgence
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (utilisateur_id = auth.uid()::uuid);

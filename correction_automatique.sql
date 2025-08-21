-- Script de correction automatique de la base de données Guinèmali
-- À exécuter APRÈS le script de vérification

-- ========================================
-- 1. CORRECTION DES DONNÉES MANQUANTES
-- ========================================

-- Copier le pseudo vers le prénom si le prénom est vide
UPDATE utilisateurs 
SET prenom = pseudo 
WHERE (prenom IS NULL OR prenom = '') AND pseudo IS NOT NULL;

-- Copier le prénom vers le pseudo si le pseudo est vide
UPDATE utilisateurs 
SET pseudo = prenom 
WHERE (pseudo IS NULL OR pseudo = '') AND prenom IS NOT NULL;

-- ========================================
-- 2. CRÉATION DE L'INDEX UNIQUE SUR PRENOM
-- ========================================

-- Supprimer l'index s'il existe déjà
DROP INDEX IF EXISTS idx_utilisateurs_prenom_unique;

-- Créer un nouvel index unique sur prenom
CREATE UNIQUE INDEX idx_utilisateurs_prenom_unique 
ON utilisateurs(prenom);

-- ========================================
-- 3. MISE À JOUR DES POLITIQUES RLS
-- ========================================

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Inscription publique" ON utilisateurs;
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leur profil" ON utilisateurs;
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leur profil" ON utilisateurs;

-- Créer de nouvelles politiques optimisées
CREATE POLICY "Inscription publique" ON utilisateurs
FOR INSERT WITH CHECK (true);

CREATE POLICY "Utilisateurs peuvent voir leur profil" ON utilisateurs
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Utilisateurs peuvent modifier leur profil" ON utilisateurs
FOR UPDATE USING (auth.uid() = id);

-- ========================================
-- 4. VÉRIFICATION POST-CORRECTION
-- ========================================

-- Vérifier que tous les utilisateurs ont un prénom
SELECT 
    'VÉRIFICATION POST-CORRECTION' as verification,
    COUNT(*) as total_utilisateurs,
    COUNT(CASE WHEN prenom IS NOT NULL AND prenom != '' THEN 1 END) as avec_prenom,
    COUNT(CASE WHEN pseudo IS NOT NULL AND pseudo != '' THEN 1 END) as avec_pseudo
FROM utilisateurs;

-- Afficher les utilisateurs corrigés
SELECT 
    'UTILISATEURS CORRIGÉS' as verification,
    id,
    pseudo,
    prenom,
    type_utilisateur,
    actif,
    date_creation
FROM utilisateurs
ORDER BY date_creation DESC;

-- ========================================
-- 5. MESSAGE DE CONFIRMATION
-- ========================================

SELECT 
    '✅ CORRECTION TERMINÉE' as statut,
    'La base de données a été mise à jour avec succès!' as message,
    'Vous pouvez maintenant tester l''application.' as prochaine_etape;

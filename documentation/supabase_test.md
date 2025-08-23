# Guide de Test Supabase - Guinèmali

## Problème Identifié
L'utilisateur ne peut pas s'inscrire - "rien ne se passe" quand il clique sur "S'inscrire".

## Diagnostic Étape par Étape

### 1. Test de Connexion de Base
- [ ] Vérifier que l'application se lance sans erreur
- [ ] Vérifier que Supabase est initialisé dans les logs
- [ ] Tester le bouton "Test Connexion Supabase" dans l'écran d'inscription

### 2. Vérification de la Configuration
- [ ] URL Supabase: `https://yhviixdwqkydmdzhzobv.supabase.co`
- [ ] Clé anonyme: Vérifier qu'elle est valide
- [ ] Projet ID: `yhviixdwqkydmdzhzobv`

### 3. Test de la Base de Données
Exécuter le script `database_check.sql` dans l'éditeur SQL de Supabase pour vérifier:
- [ ] La table `utilisateurs` existe
- [ ] La structure de la table est correcte
- [ ] Les permissions RLS sont configurées
- [ ] L'utilisateur anonyme peut lire/écrire

### 4. Problèmes Potentiels Identifiés

#### A. Table `utilisateurs` manquante
**Symptôme**: Erreur "relation 'utilisateurs' does not exist"
**Solution**: Créer la table avec la structure appropriée

#### B. Permissions RLS trop restrictives
**Symptôme**: Erreur d'autorisation lors de l'insertion
**Solution**: Ajuster les politiques RLS pour permettre l'inscription

#### C. Structure de table incorrecte
**Symptôme**: Erreur de colonne manquante
**Solution**: Vérifier que toutes les colonnes requises existent

#### D. Clé API expirée ou invalide
**Symptôme**: Erreur d'authentification
**Solution**: Régénérer la clé API dans Supabase

### 5. Structure de Table Attendue
```sql
CREATE TABLE utilisateurs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pseudo VARCHAR(50) UNIQUE NOT NULL,
  pin_chiffre VARCHAR(255) NOT NULL,
  num_tel VARCHAR(20),
  langue VARCHAR(10) DEFAULT 'fr',
  region VARCHAR(100),
  type_utilisateur VARCHAR(20) NOT NULL,
  actif BOOLEAN DEFAULT true,
  date_creation TIMESTAMP DEFAULT NOW(),
  derniere_connexion TIMESTAMP
);
```

### 6. Politiques RLS Requises
```sql
-- Permettre la lecture publique des utilisateurs actifs
CREATE POLICY "Utilisateurs visibles publiquement" ON utilisateurs
  FOR SELECT USING (actif = true);

-- Permettre l'inscription de nouveaux utilisateurs
CREATE POLICY "Inscription autorisée" ON utilisateurs
  FOR INSERT WITH CHECK (true);

-- Permettre la mise à jour de son propre profil
CREATE POLICY "Mise à jour de son profil" ON utilisateurs
  FOR UPDATE USING (auth.uid() = id);
```

### 7. Test de l'Application
1. Lancer l'application en mode debug
2. Aller à l'écran d'inscription
3. Cliquer sur "Test Connexion Supabase"
4. Vérifier les logs dans la console
5. Tenter une inscription complète
6. Observer les erreurs exactes

### 8. Logs à Surveiller
- `🔌 Test de connexion Supabase...`
- `✅ Instance Supabase récupérée`
- `✅ Connexion Supabase réussie`
- `❌ Erreur de connexion Supabase: [détails]`

## Actions Immédiates
1. **Exécuter le script de diagnostic** dans Supabase
2. **Tester la connexion** avec le bouton de test
3. **Vérifier les logs** pour identifier l'erreur exacte
4. **Corriger la configuration** selon le problème identifié

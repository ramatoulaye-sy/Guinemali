# 🗄️ Mise à Jour de la Base de Données Supabase

## 📋 Résumé des Changements

Votre application Guinèmali a été mise à jour pour utiliser **"prénom"** au lieu de **"pseudo"**. Cette modification nécessite une mise à jour de votre base de données Supabase.

## ⚠️ Problèmes Potentiels Identifiés

### 1. **Colonne manquante**
- ❌ La table `utilisateurs` n'a pas de colonne `prenom`
- ❌ Le code essaie d'insérer dans une colonne inexistante

### 2. **Emails en conflit**
- ❌ Plusieurs utilisateurs avec le même prénom = emails identiques
- ❌ Erreurs d'authentification Supabase

## 🛠️ Solution : Mise à Jour de la Base de Données

### Étape 1 : Accéder à Supabase
1. Ouvrez votre projet Supabase
2. Allez dans **SQL Editor** (éditeur SQL)
3. Créez un nouveau script

### Étape 2 : Exécuter le Script de Mise à Jour

Copiez et exécutez ce script SQL :

```sql
-- Script de mise à jour de la base de données Guinèmali
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure actuelle de la table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Ajouter la colonne 'prenom' si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utilisateurs' 
        AND column_name = 'prenom'
    ) THEN
        ALTER TABLE utilisateurs ADD COLUMN prenom VARCHAR(50);
    END IF;
END $$;

-- 3. Mettre à jour les données existantes (si des utilisateurs existent déjà)
UPDATE utilisateurs 
SET prenom = pseudo 
WHERE prenom IS NULL AND pseudo IS NOT NULL;

-- 4. Rendre la colonne 'prenom' obligatoire
ALTER TABLE utilisateurs ALTER COLUMN prenom SET NOT NULL;

-- 5. Ajouter un index unique sur 'prenom' pour éviter les doublons
CREATE UNIQUE INDEX IF NOT EXISTS idx_utilisateurs_prenom_unique 
ON utilisateurs(prenom);

-- 6. Mettre à jour les politiques RLS pour inclure 'prenom'
-- Supprimer l'ancienne politique d'inscription
DROP POLICY IF EXISTS "Inscription publique" ON utilisateurs;

-- Créer une nouvelle politique d'inscription avec 'prenom'
CREATE POLICY "Inscription publique" ON utilisateurs
FOR INSERT WITH CHECK (true);

-- Mettre à jour la politique de sélection
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leur profil" ON utilisateurs;
CREATE POLICY "Utilisateurs peuvent voir leur profil" ON utilisateurs
FOR SELECT USING (auth.uid() = id);

-- Mettre à jour la politique de modification
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leur profil" ON utilisateurs;
CREATE POLICY "Utilisateurs peuvent modifier leur profil" ON utilisateurs
FOR UPDATE USING (auth.uid() = id);

-- 7. Vérifier les politiques actuelles
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'utilisateurs';

-- 8. Vérifier la structure finale
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'utilisateurs' 
AND table_schema = 'public'
ORDER BY ordinal_position;
```

### Étape 3 : Vérifier les Résultats

Après l'exécution, vous devriez voir :
- ✅ Nouvelle colonne `prenom` dans la table
- ✅ Index unique sur `prenom`
- ✅ Politiques RLS mises à jour

## 🔧 Améliorations Apportées au Code

### 1. **Emails Uniques**
- ✅ Chaque utilisateur aura un email unique
- ✅ Format : `prenom_timestamp@gmail.com`
- ✅ Pas de conflits entre utilisateurs

### 2. **Validation Renforcée**
- ✅ Vérification de disponibilité du prénom
- ✅ Index unique en base de données
- ✅ Messages d'erreur clairs

## 🧪 Test de l'Application

Après la mise à jour de la base de données :

1. **Recompiler l'application** :
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

2. **Tester l'inscription** :
   - Entrez un prénom unique
   - Entrez un PIN à 4 chiffres
   - Cliquez sur "S'inscrire"
   - L'utilisateur devrait être créé avec succès

## 📱 Fonctionnalités Disponibles

- ✅ **Inscription** avec prénom unique
- ✅ **Connexion** avec prénom + PIN
- ✅ **Gestion des profils** utilisateur
- ✅ **SOS Button** avec géolocalisation
- ✅ **Enregistrement automatique** des preuves
- ✅ **Notifications** d'urgence

## 🆘 En Cas de Problème

Si vous rencontrez des erreurs :

1. **Vérifiez la connexion Supabase** dans l'application
2. **Exécutez le script SQL** étape par étape
3. **Vérifiez les politiques RLS** dans Supabase
4. **Consultez les logs** de l'application

## 📞 Support

Pour toute question technique, vérifiez :
- Les logs de l'application
- La console Supabase
- Les politiques RLS de votre table

---

**🎯 Objectif** : Votre application Guinèmali sera maintenant 100% fonctionnelle avec une base de données optimisée !

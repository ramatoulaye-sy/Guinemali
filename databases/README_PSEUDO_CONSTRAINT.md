# 🔒 Contrainte sur le Pseudo - Guinèmali

## 📋 Vue d'ensemble

Ce dossier contient les scripts SQL nécessaires pour ajouter une contrainte sur le champ `pseudo` dans la table `utilisateurs` de Supabase. Cette contrainte garantit que seuls les pseudos contenant des **lettres (a-z, A-Z) et des chiffres (0-9)** sont acceptés.

## 🎯 Objectif

Éviter les conflits lors de l'inscription en s'assurant que :
- ✅ L'application Flutter n'accepte que des lettres et chiffres
- ✅ La base de données Supabase rejette les pseudos invalides
- ✅ Cohérence totale entre l'application et la base de données

## 📁 Fichiers

### 1. `05_pseudo_constraint.sql`
**Script principal** à exécuter en premier. Il :
- Ajoute la contrainte `chk_pseudo_format` sur la table `utilisateurs`
- Nettoie les pseudos existants qui ne respectent pas la règle
- Résout les conflits de doublons après nettoyage
- Affiche un rapport des modifications

### 2. `06_test_pseudo_constraint.sql`
**Script de test** à exécuter après le premier. Il :
- Teste l'insertion de pseudos valides (devrait fonctionner)
- Teste l'insertion de pseudos invalides (devrait échouer)
- Vérifie que la contrainte est active
- Affiche un résumé des tests

## 🚀 Comment appliquer

### Étape 1 : Exécuter le script principal
```sql
-- Dans l'éditeur SQL de Supabase
-- Copier-coller le contenu de 05_pseudo_constraint.sql
-- Exécuter le script
```

### Étape 2 : Vérifier avec le script de test
```sql
-- Dans l'éditeur SQL de Supabase
-- Copier-coller le contenu de 06_test_pseudo_constraint.sql
-- Exécuter le script
```

### Étape 3 : Vérifier les résultats
- ✅ Tous les pseudos existants respectent la nouvelle règle
- ✅ La contrainte `chk_pseudo_format` est active
- ✅ Les tests passent (pseudos valides acceptés, invalides rejetés)

## 🔍 Détails techniques

### Contrainte ajoutée
```sql
ALTER TABLE public.utilisateurs 
ADD CONSTRAINT chk_pseudo_format 
CHECK (pseudo ~ '^[a-zA-Z0-9]+$');
```

### Regex utilisée
- `^` : début de chaîne
- `[a-zA-Z0-9]` : lettres minuscules, majuscules et chiffres uniquement
- `+` : au moins un caractère
- `$` : fin de chaîne

### Caractères acceptés
- ✅ `a-z` : lettres minuscules
- ✅ `A-Z` : lettres majuscules  
- ✅ `0-9` : chiffres

### Caractères rejetés
- ❌ `_` (underscore)
- ❌ `-` (tiret)
- ❌ ` ` (espace)
- ❌ `@`, `#`, `$`, etc. (caractères spéciaux)
- ❌ `é`, `à`, `ç`, etc. (accents)

## ⚠️ Important

1. **Sauvegarde** : Faites une sauvegarde de votre base avant d'exécuter ces scripts
2. **Test** : Testez d'abord sur un environnement de développement
3. **Production** : Exécutez pendant les heures creuses pour minimiser l'impact
4. **Vérification** : Vérifiez que tous les tests passent après application

## 🔗 Liens utiles

- [Documentation Supabase SQL Editor](https://supabase.com/docs/guides/database/sql-editor)
- [PostgreSQL CHECK Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-CHECK)
- [Regex PostgreSQL](https://www.postgresql.org/docs/current/functions-matching.html#FUNCTIONS-POSIX-REGEXP)

## 📞 Support

En cas de problème lors de l'application de ces scripts, vérifiez :
1. Les logs d'erreur dans Supabase
2. Que vous avez les droits d'administration sur la base
3. Que la table `utilisateurs` existe et est accessible

# 🚀 RÉSOLUTION DU PROBLÈME D'INSCRIPTION

## 📋 ÉTAPES OBLIGATOIRES

### **ÉTAPE 1: Exécuter le schéma SQL dans Supabase**

1. **Ouvrir Supabase Dashboard**
   - Aller sur https://supabase.com/dashboard
   - Sélectionner votre projet Guinemali

2. **Accéder à l'éditeur SQL**
   - Cliquer sur "SQL Editor" dans le menu de gauche
   - Cliquer sur "New query"

3. **Exécuter le schéma complet**
   - Copier tout le contenu de `supabase_schema.sql`
   - Coller dans l'éditeur SQL
   - Cliquer sur "Run" (ou Ctrl+Enter)

4. **Vérifier la création des tables**
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('utilisateurs', 'alertes', 'preuves', 'contacts_urgence', 'forum_messages');
   ```

### **ÉTAPE 2: Vérifier les fonctions RPC**

```sql
-- Vérifier que la fonction existe
SELECT routine_name FROM information_schema.routines 
WHERE routine_name = 'login_by_pseudo_hash';
```

### **ÉTAPE 3: Tester l'application**

1. **Lancer l'application**
   ```bash
   flutter run -d chrome --web-port=8080
   ```

2. **Tester l'inscription**
   - Aller sur la page d'inscription
   - Remplir le formulaire
   - Cliquer sur "S'inscrire"

3. **Vérifier les logs**
   - Ouvrir la console du navigateur (F12)
   - Regarder les messages dans l'onglet Console

## 🔧 SOLUTIONS ALTERNATIVES

### **Solution A: Désactiver RLS temporairement**

Si l'inscription échoue à cause des politiques RLS :

```sql
-- Dans Supabase Dashboard > SQL Editor
ALTER TABLE utilisateurs DISABLE ROW LEVEL SECURITY;
ALTER TABLE alertes DISABLE ROW LEVEL SECURITY;
ALTER TABLE preuves DISABLE ROW LEVEL SECURITY;
ALTER TABLE contacts_urgence DISABLE ROW LEVEL SECURITY;
ALTER TABLE forum_messages DISABLE ROW LEVEL SECURITY;
```

### **Solution B: Mode test temporaire**

Si le problème persiste, activer temporairement le mode test :

```dart
// Dans lib/core/constants/app_constants.dart
static const bool enableTestMode = true; // Temporairement
```

### **Solution C: Vérifier les clés API**

1. **Aller dans Supabase Dashboard**
2. **Settings > API**
3. **Copier l'URL et la clé anon**
4. **Mettre à jour `lib/core/config/supabase_config.dart`**

## 🚨 ERREURS COURANTES ET SOLUTIONS

### **Erreur: "relation does not exist"**
- **Cause:** Tables non créées
- **Solution:** Exécuter le schéma SQL

### **Erreur: "function does not exist"**
- **Cause:** Fonctions RPC manquantes
- **Solution:** Exécuter la partie RPC du schéma

### **Erreur: "row-level security policy"**
- **Cause:** Politiques RLS trop restrictives
- **Solution:** Désactiver RLS temporairement

### **Erreur: "Invalid API key"**
- **Cause:** Clés Supabase incorrectes
- **Solution:** Vérifier les clés dans supabase_config.dart

## 📞 SUPPORT

Si le problème persiste après ces étapes :

1. **Fournir les logs d'erreur** de la console
2. **Indiquer quelle étape a échoué**
3. **Préciser le message d'erreur exact**

## ✅ VÉRIFICATION FINALE

L'inscription fonctionne si :
- ✅ Le schéma SQL est exécuté
- ✅ Les tables sont créées
- ✅ Les fonctions RPC existent
- ✅ L'inscription crée un utilisateur
- ✅ La connexion fonctionne après inscription

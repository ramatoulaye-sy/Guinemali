# 🔍 DIAGNOSTIC - PROBLÈME D'INSCRIPTION

## 📋 ÉTAPES DE DIAGNOSTIC

### 1. **Vérifier le schéma Supabase**
```sql
-- Dans Supabase Dashboard > SQL Editor, exécuter :
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('utilisateurs', 'alertes', 'preuves', 'contacts_urgence', 'forum_messages');
```

### 2. **Vérifier la fonction RPC**
```sql
-- Vérifier que la fonction existe :
SELECT routine_name FROM information_schema.routines 
WHERE routine_name = 'login_by_pseudo_hash';
```

### 3. **Tester l'inscription manuelle**
```sql
-- Tester l'insertion directe :
INSERT INTO utilisateurs (
    pseudo, 
    prenom, 
    pin_chiffre, 
    type_utilisateur, 
    langue, 
    region
) VALUES (
    'test_manual',
    'Test Manuel',
    'test_pin_hash',
    'victime',
    'fr',
    'Conakry'
);
```

### 4. **Vérifier les logs d'erreur**
- Ouvrir la console du navigateur (F12)
- Regarder les erreurs dans l'onglet Console
- Vérifier l'onglet Network pour les requêtes échouées

## 🚨 ERREURS COURANTES

### **Erreur 1: Table n'existe pas**
```
Error: relation "utilisateurs" does not exist
```
**Solution:** Exécuter le schéma SQL dans Supabase Dashboard

### **Erreur 2: Fonction RPC manquante**
```
Error: function login_by_pseudo_hash does not exist
```
**Solution:** Exécuter la partie RPC du schéma SQL

### **Erreur 3: Permissions RLS**
```
Error: new row violates row-level security policy
```
**Solution:** Vérifier les politiques RLS ou les désactiver temporairement

### **Erreur 4: Connexion Supabase**
```
Error: Failed to connect to Supabase
```
**Solution:** Vérifier les clés API dans `lib/core/services/supabase_service.dart`

## 🔧 SOLUTIONS RAPIDES

### **Solution 1: Désactiver RLS temporairement**
```sql
-- Dans Supabase Dashboard > SQL Editor :
ALTER TABLE utilisateurs DISABLE ROW LEVEL SECURITY;
```

### **Solution 2: Vérifier les clés API**
```dart
// Dans lib/core/services/supabase_service.dart
// Vérifier que les clés sont correctes :
static const String supabaseUrl = 'VOTRE_URL_SUPABASE';
static const String supabaseAnonKey = 'VOTRE_CLE_ANON';
```

### **Solution 3: Mode test temporaire**
```dart
// Dans lib/core/constants/app_constants.dart
static const bool enableTestMode = true; // Temporairement
```

## 📞 SUPPORT

Si le problème persiste, fournir :
1. **Logs d'erreur** de la console
2. **Capture d'écran** de l'erreur
3. **URL Supabase** (sans la clé)
4. **Version Flutter** : `flutter --version`

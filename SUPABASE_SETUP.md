# 🔧 Configuration Supabase - Guinèmali

## 🚨 PROBLÈME ACTUEL
Votre projet Supabase "guinemali" est **SUSPENDU** et les clés de configuration sont des placeholders.

## ✅ SOLUTION ÉTAPE PAR ÉTAPE

### 1. Réactiver votre projet Supabase
1. **Allez sur [supabase.com](https://supabase.com)**
2. **Connectez-vous à votre compte**
3. **Cliquez sur votre projet "guinemali"**
4. **Cliquez sur "Réactiver le projet"**
5. **Attendez que le projet soit actif** (quelques minutes)

### 2. Récupérer vos vraies clés Supabase
Une fois réactivé, dans votre projet :
1. **Allez dans "Settings" → "API"**
2. **Copiez l'URL du projet** (ex: `https://abcdefghijklm.supabase.co`)
3. **Copiez la clé anon/public** (commence par `eyJ...`)

### 3. Mettre à jour le code
Modifiez le fichier `lib/core/config/supabase_config.dart` :

```dart
class SupabaseConfig {
  // Remplacez ces valeurs par vos vraies clés
  static const String projectUrl = 'https://VOTRE-VRAI-PROJET.supabase.co';
  static const String anonKey = 'VOTRE-VRAIE-CLE-ANON';
  
  // ... reste du code
}
```

### 4. Tester la connexion
1. **Redémarrez l'application**
2. **Allez sur la page de connexion**
3. **Testez avec un utilisateur existant**

## 🧪 MODE DE TEST TEMPORAIRE
En attendant, le mode de test est activé dans `AppConstants.enableTestMode = true`.
Cela permet de tester l'interface sans Supabase.

## 📋 VÉRIFICATIONS
- [ ] Projet Supabase réactivé
- [ ] Clés mises à jour dans le code
- [ ] Application redémarrée
- [ ] Connexion testée

## 🆘 EN CAS DE PROBLÈME
Si la connexion ne fonctionne toujours pas :
1. **Vérifiez que Supabase est bien réactivé**
2. **Vérifiez que les clés sont correctes**
3. **Regardez la console pour les erreurs**
4. **Vérifiez que les tables existent dans Supabase**

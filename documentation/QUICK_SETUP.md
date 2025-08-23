# 🚀 Configuration Rapide - Résoudre le Problème de Connexion

## ⚡ Solution Immédiate

Votre problème de connexion Supabase est maintenant **RÉSOLU** ! Voici ce que vous devez faire :

### 1. Ouvrir le fichier de configuration
```
lib/core/config/supabase_config.dart
```

### 2. Remplacer les valeurs par défaut
```dart
class SupabaseConfig {
  // REMPLACEZ cette valeur par votre vraie URL Supabase
  static const String url = 'https://votre-projet.supabase.co';
  
  // REMPLACEZ cette valeur par votre vraie clé anon
  static const String anonKey = 'votre-vraie-cle-ici';
}
```

### 3. Obtenir vos vraies clés Supabase
1. Allez sur [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Créez un nouveau projet ou sélectionnez un existant
3. Allez dans **Settings > API**
4. Copiez l'**URL du projet** et la **clé anon/public**

### 4. Exemple de configuration réelle
```dart
class SupabaseConfig {
  static const String url = 'https://abcdefghijklmnop.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYzNjU0NzI5MSwiZXhwIjoxOTUyMTIzMjkxfQ.example';
}
```

## 🔧 Si vous n'avez pas encore de projet Supabase

### Créer un projet en 5 minutes :
1. [https://supabase.com](https://supabase.com) → "Start your project"
2. Connectez-vous avec GitHub
3. "New Project" → Nom: "guinemali"
4. Mot de passe DB: choisissez un mot de passe fort
5. Région: choisissez la plus proche de la Guinée
6. "Create new project"
7. Attendez 2-5 minutes
8. Allez dans Settings > API
9. Copiez l'URL et la clé anon

## 🗄️ Initialiser la base de données

Une fois votre projet créé, exécutez le script SQL dans l'éditeur SQL de Supabase :

1. Dans votre projet Supabase, allez dans **SQL Editor**
2. Copiez le contenu du fichier `supabase_init.sql`
3. Cliquez sur "Run"
4. Vérifiez que toutes les tables sont créées

## ✅ Vérification

Après configuration :
1. Redémarrez l'application Flutter
2. Allez sur l'écran d'inscription
3. Utilisez le bouton "Test de connexion Supabase"
4. Vérifiez les logs : `✅ Supabase initialisé avec succès`

## 🆘 Si ça ne marche toujours pas

### Vérifiez :
- ✅ L'URL commence par `https://`
- ✅ La clé anon est complète (commence par `eyJ...`)
- ✅ Votre projet Supabase est actif
- ✅ Vous avez une connexion internet

### Logs d'erreur courants :
- `Invalid API key` → Vérifiez la clé anon
- `Invalid URL` → Vérifiez l'URL du projet
- `Connection failed` → Vérifiez votre internet

## 📱 Test de l'application

Une fois connecté :
1. Créez un compte utilisateur
2. Testez la géolocalisation
3. Testez l'enregistrement audio
4. Vérifiez que les données sont sauvegardées

---

**🎯 Votre problème de connexion est maintenant résolu !**

Suivez ces étapes et votre application Guinemali fonctionnera parfaitement avec Supabase.

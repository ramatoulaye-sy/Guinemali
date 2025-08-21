# Guide de déploiement - Guinèmali 🚀

Ce document détaille les étapes pour déployer l'application Guinèmali en production.

## 📋 Prérequis

### Comptes et services
- [ ] Projet Supabase configuré
- [ ] Compte Google Cloud (pour Firebase/FCM)
- [ ] Clés de signature Android
- [ ] Certificats SSL pour le domaine

### Outils de développement
- [ ] Flutter SDK 3.8.1+
- [ ] Android Studio avec SDK Android 33+
- [ ] Git configuré
- [ ] Accès aux repositories

## 🗄️ Configuration base de données

### 1. Création du projet Supabase

1. Créer un nouveau projet sur [Supabase](https://supabase.com)
2. Noter l'URL et la clé anonyme du projet
3. Configurer la région la plus proche (Europe West pour la Guinée)

### 2. Exécution des scripts SQL

Exécuter dans l'ordre dans l'éditeur SQL de Supabase :

```bash
# 1. Création des tables et structures
databases/01_create_tables.sql

# 2. Politiques de sécurité (RLS)
databases/02_security_policies.sql

# 3. Index et fonctions
databases/03_indexes_and_functions.sql

# 4. Configuration de déploiement
databases/04_deployment_setup.sql
```

### 3. Configuration des buckets Storage

Les buckets sont automatiquement créés par le script `04_deployment_setup.sql` :
- `evidence` : Preuves chiffrées (privé)
- `avatars` : Photos de profil (public)
- `public-resources` : Ressources partagées (public)

### 4. Création de l'administrateur initial

⚠️ **IMPORTANT** : Décommenter et exécuter UNE SEULE FOIS :

```sql
SELECT create_admin_user(
    'admin@guinemali.org', 
    'VotreMotDePasseSecurise123!', 
    'admin_guinemali'
);
```

**Puis commenter à nouveau cette ligne !**

## 📱 Configuration mobile

### 1. Configuration des constantes

Mettre à jour `lib/core/constants/app_constants.dart` :

```dart
// PRODUCTION - À personnaliser
static const String supabaseUrl = 'https://votre-projet.supabase.co';
static const String supabaseAnonKey = 'votre-cle-anonyme';

// Désactiver le debug en production
static const bool enableDebugMode = false;
static const bool enableLogging = false; // Ou true pour les logs production
```

### 2. Configuration Android

#### Permissions
Les permissions sont déjà configurées dans `android/app/src/main/AndroidManifest.xml`

#### Signature de l'APK
1. Créer une clé de signature :
```bash
keytool -genkey -v -keystore guinemali-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias guinemali
```

2. Créer `android/key.properties` :
```properties
storePassword=votre-mot-de-passe
keyPassword=votre-mot-de-passe
keyAlias=guinemali
storeFile=../guinemali-release-key.jks
```

3. Configurer `android/app/build.gradle.kts` (déjà fait si utilisation du template)

### 3. Configuration des notifications

#### Firebase Setup
1. Créer un projet Firebase
2. Ajouter l'app Android avec le package name
3. Télécharger `google-services.json` dans `android/app/`
4. Configurer FCM dans Supabase

#### Configuration Supabase
Dans le dashboard Supabase > Authentication > Settings :
- Ajouter la clé serveur FCM
- Configurer les templates de notifications

## 🚀 Build et déploiement

### 1. Tests pré-déploiement

```bash
# Tests unitaires
flutter test

# Analyse du code
flutter analyze

# Tests d'intégration (si disponibles)
flutter test integration_test/
```

### 2. Build de production Android

```bash
# Clean
flutter clean
flutter pub get

# Build APK de production
flutter build apk --release --split-per-abi

# Ou build AAB pour Google Play
flutter build appbundle --release
```

Les fichiers sont générés dans :
- `build/app/outputs/flutter-apk/` (APK)
- `build/app/outputs/bundle/release/` (AAB)

### 3. Vérifications post-build

- [ ] Taille de l'APK < 50MB
- [ ] Toutes les permissions nécessaires sont présentes
- [ ] L'icône et le nom de l'app sont corrects
- [ ] Test sur device physique avec données de production

## 📊 Monitoring et maintenance

### 1. Configuration des logs

#### Supabase
- Activer les logs de performance
- Configurer les alertes sur les erreurs
- Monitorer l'utilisation du stockage

#### Application
- Intégrer Crashlytics (Firebase)
- Configurer Sentry pour le monitoring d'erreurs
- Logs d'analytics pour l'usage

### 2. Métriques importantes

À surveiller :
- Nombre d'alertes créées/résolues
- Temps de réponse des notifications
- Utilisation du stockage (preuves)
- Erreurs d'authentification
- Performance des requêtes

### 3. Maintenance régulière

#### Hebdomadaire
- Vérifier les logs d'erreur
- Analyser les métriques d'usage
- Backup des données critiques

#### Mensuelle
- Nettoyage des données anciennes (`cleanup_old_data()`)
- Mise à jour des dépendances
- Tests de sécurité

#### Trimestrielle
- Audit de sécurité complet
- Optimisation des performances
- Mise à jour Flutter/Android

## 🔒 Sécurité en production

### 1. Checklist sécurité

- [ ] RLS activé sur toutes les tables
- [ ] Politiques de sécurité testées
- [ ] Chiffrement des données sensibles
- [ ] HTTPS activé partout
- [ ] Clés d'API sécurisées
- [ ] Logs de sécurité activés

### 2. Gestion des secrets

**Ne jamais commiter :**
- Clés de signature Android
- Tokens d'API
- Mots de passe base de données
- Certificats SSL privés

**Utiliser des variables d'environnement ou des services de secrets.**

### 3. Plan de réponse aux incidents

1. **Détection** : Monitoring automatique + rapports utilisateurs
2. **Évaluation** : Gravité de l'incident (1-4)
3. **Réponse** : Procédures selon la gravité
4. **Communication** : Utilisateurs + partenaires
5. **Post-mortem** : Analyse et améliorations

## 🆘 Incidents et rollback

### 1. Plan de rollback

En cas de problème critique :

```bash
# 1. Arrêter le déploiement en cours
# 2. Restaurer la version précédente

# Base de données
pg_restore --host=host --port=5432 --username=postgres --dbname=postgres backup_pre_deploy.sql

# Application
# Redéployer la version précédente validée
```

### 2. Contacts d'urgence

- **Tech Lead** : +224 XXX XX XX XX
- **DevOps** : +224 XXX XX XX XX  
- **Product Owner** : +224 XXX XX XX XX
- **Support Supabase** : support@supabase.io

## 📈 Mise à l'échelle

### Prévisions de charge

| Métrique | Mois 1 | Mois 6 | Mois 12 |
|----------|--------|--------|---------|
| Utilisateurs actifs | 100 | 1,000 | 5,000 |
| Alertes/jour | 5 | 50 | 200 |
| Stockage (GB) | 1 | 10 | 50 |
| Requêtes/jour | 1,000 | 10,000 | 50,000 |

### Optimisations préventives

- **Base de données** : Index supplémentaires, partitioning
- **Stockage** : CDN pour les ressources statiques
- **API** : Rate limiting, cache Redis
- **Mobile** : Optimisation des images, lazy loading

## ✅ Checklist finale de déploiement

### Pré-déploiement
- [ ] Tests passent tous
- [ ] Configuration production vérifiée
- [ ] Backup de la base de données actuelle
- [ ] Équipe prévenue du déploiement

### Déploiement
- [ ] Scripts SQL exécutés avec succès
- [ ] APK signé et testé
- [ ] Monitoring activé
- [ ] Documentation mise à jour

### Post-déploiement
- [ ] Tests de fumée OK
- [ ] Métriques dans les seuils normaux
- [ ] Première alerte test fonctionnelle
- [ ] Équipe informée du succès

---

**Support technique** : tech@guinemali.org
**Dernière mise à jour** : [Date du déploiement]

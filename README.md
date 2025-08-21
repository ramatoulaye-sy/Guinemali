# Guinèmali 🛡️

**Application mobile sécurisée pour la protection des femmes et jeunes filles en Guinée**

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

## 📱 À propos

Guinèmali est une application mobile développée en Flutter qui vise à restaurer un sentiment de sécurité pour les femmes et jeunes filles en Guinée. L'application offre une assistance en temps réel et permet de documenter les incidents de façon fiable grâce à un réseau de soutien communautaire.

### 🎯 Objectifs

- **Alerte rapide** : Déclenchement d'alertes discrètes en cas de danger
- **Géolocalisation** : Partage de localisation en temps réel
- **Preuves sécurisées** : Enregistrement automatique audio/vidéo chiffré
- **Réseau solidaire** : Connexion avec une communauté d'aidants (ONG, proches, volontaires)
- **Fonctionnement hors ligne** : Stockage local et synchronisation différée

## 🏗️ Architecture

### Types d'utilisateurs
- **👤 Victimes** : Femmes et jeunes filles cherchant protection
- **🤝 Aidants** : Bénévoles disponibles pour assistance d'urgence
- **🏢 ONG** : Organisations de soutien aux femmes
- **⚙️ Administrateurs** : Gestionnaires de la plateforme

### Technologies utilisées
- **Frontend** : Flutter 3.8+ avec Material Design 3
- **Backend** : Supabase (PostgreSQL + API REST + Auth + Storage)
- **État** : Provider pattern
- **Navigation** : GoRouter
- **Stockage local** : SharedPreferences + SQLite
- **Chiffrement** : Crypto + Encrypt packages
- **Géolocalisation** : Geolocator
- **Médias** : Camera + Record packages

## 📁 Structure du projet

```
lib/
├── core/                    # Composants centraux
│   ├── constants/          # Constantes et thèmes
│   ├── models/             # Modèles de données
│   ├── services/           # Services (Auth, Storage, etc.)
│   ├── utils/              # Utilitaires
│   └── widgets/            # Widgets réutilisables
├── victim/                 # Interface victimes
│   ├── screens/            # Écrans spécifiques victimes
│   └── widgets/            # Widgets pour victimes
├── ong/                    # Interface ONG
├── admin/                  # Interface administrateurs
├── helper/                 # Interface aidants
├── shared/                 # Composants partagés
│   ├── screens/            # Écrans communs (welcome, login)
│   ├── services/           # Services partagés
│   └── widgets/            # Widgets communs
└── databases/              # Scripts SQL Supabase
```

## 🚀 Installation

### Prérequis
- Flutter SDK 3.8.1+
- Dart SDK 3.0+
- Android Studio / VS Code
- Compte Supabase

### Configuration

1. **Cloner le repository**
```bash
git clone https://github.com/votre-org/guinemali.git
cd guinemali
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configuration Supabase**
   - Créer un projet sur [Supabase](https://supabase.com)
   - Exécuter les scripts SQL dans `/databases/`
   - Mettre à jour les constantes dans `lib/core/constants/app_constants.dart`:

```dart
static const String supabaseUrl = 'VOTRE_SUPABASE_URL';
static const String supabaseAnonKey = 'VOTRE_SUPABASE_ANON_KEY';
```

4. **Configuration Android**
   - Ajouter les permissions dans `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

5. **Lancer l'application**
```bash
flutter run
```

## 🗄️ Base de données

La base de données Supabase comprend les tables principales :

- **utilisateurs** : Profils des utilisateurs avec chiffrement PIN
- **alertes** : Alertes d'urgence avec géolocalisation
- **preuves** : Fichiers multimédias chiffrés
- **contacts_urgence** : Contacts prioritaires (max 3)
- **messages_forum** : Forum communautaire modéré
- **ressources** : Guides et contacts utiles
- **aidants_disponibles** : Réseau de soutien géolocalisé

### Politiques de sécurité (RLS)
- Isolation des données par utilisateur
- Chiffrement des informations sensibles
- Audit trail complet
- Modération des contenus publics

## 🔒 Sécurité

### Fonctionnalités de sécurité
- **Chiffrement** : PIN hashé + données sensibles chiffrées
- **Mode furtif** : Activation discrète via boutons volume
- **Stockage sécurisé** : Isolation des preuves locales
- **Row Level Security** : Contrôle d'accès granulaire
- **Audit complet** : Journalisation de toutes les actions

### Scénario d'utilisation

> Fatoumata se sent suivie en rentrant chez elle. Elle active discrètement le mode furtif via un double clic sur le bouton volume. L'app :
> - 🎤 Enregistre l'audio ambiant en arrière-plan
> - 📍 Capture sa position GPS
> - 🔐 Chiffre et envoie les données à Supabase
> - 📱 Notifie ses 3 contacts de confiance et les aidants proches
> - 📶 Envoie un SMS via Twilio si la connexion est faible

## 🎨 Interface utilisateur

### Thème et couleurs
- **Primaire** : `#945ACB` (Violet)
- **Secondaire** : `#EE82EE` (Violet clair)
- **Accent** : `#FFFFFF` (Blanc)

### Fonctionnalités UI
- Animations fluides avec Flutter Animate
- Design Material 3
- Mode sombre/clair
- Accessibilité optimisée
- Responsive design

### Écrans principaux

#### 👤 Interface Victime
- **Accueil** : Bouton SOS central animé
- **ONG** : Liste des organisations d'aide
- **Mes contacts** : Gestion des contacts d'urgence (max 3)
- **Menu** : Communauté, Preuves, Paramètres, Historique

#### 🤝 Interface Aidant
- **Alertes** : Notifications temps réel des urgences proximité
- **Disponibilité** : Gestion du statut et zone d'intervention
- **Historique** : Interventions passées et évaluations

#### 🏢 Interface ONG
- **Dashboard** : Statistiques et alertes actives
- **Ressources** : Gestion des guides et contacts
- **Modération** : Forum communautaire

## 📦 Dépendances principales

```yaml
dependencies:
  # Backend et authentification
  supabase_flutter: ^2.8.0
  
  # Interface utilisateur
  flutter_animate: ^4.5.0
  go_router: ^14.6.2
  provider: ^6.1.2
  
  # Géolocalisation et permissions
  geolocator: ^13.0.2
  permission_handler: ^11.3.1
  
  # Enregistrement multimédia
  camera: ^0.11.0+2
  record: ^5.1.2
  
  # Stockage et cryptographie
  shared_preferences: ^2.3.3
  sqflite: ^2.4.1
  crypto: ^3.0.6
  encrypt: ^5.0.3
```

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

## 📱 Build et déploiement

### Android
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release --split-per-abi
```

### Configuration de production
1. Désactiver le mode debug dans `app_constants.dart`
2. Configurer les clés de signature Android
3. Mettre à jour les URLs de production Supabase

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

### Standards de code
- Suivre les conventions Dart/Flutter
- Commenter le code en français
- Tester les nouvelles fonctionnalités
- Respecter l'architecture en place

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir le fichier `LICENSE` pour plus d'informations.

## 📞 Support

- **Email** : support@guinemali.org
- **Documentation** : [docs.guinemali.org](https://docs.guinemali.org)
- **Issues** : [GitHub Issues](https://github.com/votre-org/guinemali/issues)

## 🙏 Remerciements

- Communauté Flutter pour les packages open source
- Supabase pour la plateforme backend
- Organisations partenaires en Guinée
- Toutes les contributoires et contributrices

---

**Guinèmali** - *Votre sécurité, notre priorité* 🛡️

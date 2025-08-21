# Guide de développement - Guinèmali 🚀

## 🎯 État actuel du projet

### ✅ Composants implémentés

#### 🏗️ Architecture de base
- [x] Structure des dossiers organisée par type d'utilisateur
- [x] Configuration Flutter avec dependencies
- [x] Thème Material Design 3 avec couleurs Guinèmali
- [x] Navigation avec GoRouter
- [x] Gestion d'état avec Provider

#### 🗄️ Base de données et backend
- [x] Scripts SQL Supabase complets
- [x] Tables avec Row Level Security (RLS)
- [x] Modèles de données Dart
- [x] Service Supabase configuré
- [x] Authentification sécurisée avec PIN

#### 🔐 Sécurité et authentification
- [x] Service d'authentification complet
- [x] Chiffrement des PIN avec salt
- [x] Stockage local sécurisé
- [x] Politiques de sécurité RLS

#### 📱 Interface utilisateur
- [x] Écran de bienvenue animé
- [x] Écran de connexion avec validation
- [x] Écran d'inscription multi-étapes
- [x] Écrans temporaires pour chaque type d'utilisateur

#### 📄 Documentation
- [x] README détaillé
- [x] Guide de déploiement
- [x] Permissions Android configurées

### 🚧 Prochaines étapes à implémenter

#### Priorité 1 - Interface Victime
- [ ] Écran d'accueil avec bouton SOS animé
- [ ] Système d'alerte d'urgence
- [ ] Enregistrement audio/vidéo automatique
- [ ] Géolocalisation en temps réel
- [ ] Gestion des contacts d'urgence

#### Priorité 2 - Fonctionnalités core
- [ ] Service de géolocalisation
- [ ] Service d'enregistrement multimédia
- [ ] Notifications push
- [ ] Stockage local SQLite
- [ ] Synchronisation hors ligne

#### Priorité 3 - Interfaces spécialisées
- [ ] Interface Aidant avec alertes proximité
- [ ] Interface ONG avec dashboard
- [ ] Interface Admin avec modération
- [ ] Forum communautaire

## 🛠️ Configuration du développement

### 1. Installation rapide

```bash
# Cloner et installer
git clone [votre-repo]
cd guinemali
flutter pub get

# Lancer l'app
flutter run
```

### 2. Configuration Supabase (pour tests)

⚠️ **Important** : Avant de pouvoir tester l'authentification, vous devez :

1. Créer un projet sur [Supabase.com](https://supabase.com)
2. Exécuter les scripts SQL dans `/databases/`
3. Mettre à jour `lib/core/constants/app_constants.dart` :

```dart
static const String supabaseUrl = 'VOTRE_URL_SUPABASE';
static const String supabaseAnonKey = 'VOTRE_CLE_ANON';
```

### 3. Test de l'application actuelle

L'application peut être lancée et testée avec les fonctionnalités suivantes :

#### ✅ Fonctionnel
- Écran de bienvenue avec animations
- Navigation vers inscription/connexion
- Inscription complète avec validation
- Connexion avec pseudo/PIN
- Redirection vers interfaces temporaires

#### ⚠️ Limitations actuelles
- Authentification Supabase nécessite configuration
- Pas encore de bouton SOS fonctionnel
- Interfaces utilisateur basiques

## 🎨 Guide de style

### Couleurs
```dart
// Couleurs principales
Primary: #945ACB    // Violet principal
Secondary: #EE82EE  // Violet clair  
White: #FFFFFF      // Blanc

// Couleurs d'état
Error: #D32F2F      // Rouge erreur
Success: #4CAF50    // Vert succès
Warning: #FF9800    // Orange alerte
```

### Typography
- **Material Design 3** avec thèmes personnalisés
- Police système avec fallbacks
- Tailles cohérentes définies dans `AppConstants`

### Animations
- **Flutter Animate** pour les transitions
- Durées : Fast (200ms), Medium (400ms), Slow (800ms)
- Courbes : `Curves.easeOut`, `Curves.elasticOut`

## 🧪 Tests et debug

### Tests actuels
```bash
# Tests unitaires
flutter test

# Analyse du code
flutter analyze

# Build test
flutter build apk --debug
```

### Debug et logs
- Logs activés en mode debug dans `AppConstants.enableLogging`
- Messages d'erreur en français
- Gestion d'erreur centralisée

## 📱 Fonctionnalités à développer

### 1. Bouton SOS animé (Priorité 1)

```dart
// Localisation: lib/victim/widgets/sos_button.dart
class SOSButton extends StatefulWidget {
  // Animation pulsante
  // Double-tap ou long press pour activation
  // Feedback haptic
  // État d'urgence visuel
}
```

### 2. Service d'alerte (Priorité 1)

```dart
// Localisation: lib/core/services/alert_service.dart
class AlertService {
  // Créer une alerte avec géolocalisation
  // Notifier les contacts d'urgence
  // Démarrer l'enregistrement automatique
  // Envoyer à Supabase en temps réel
}
```

### 3. Enregistrement multimédia (Priorité 1)

```dart
// Localisation: lib/core/services/recording_service.dart
class RecordingService {
  // Enregistrement audio en arrière-plan
  // Capture vidéo/photo discrète
  // Chiffrement des fichiers
  // Upload vers Supabase Storage
}
```

### 4. Géolocalisation (Priorité 1)

```dart
// Localisation: lib/core/services/location_service.dart
class LocationService {
  // Position en temps réel
  // Tracking en arrière-plan
  // Gestion des permissions
  // Historique des positions
}
```

## 🚀 Roadmap de développement

### Phase 1 - MVP Victime (2-3 semaines)
1. **Bouton SOS fonctionnel**
   - Animation et interactions
   - Activation discrète (volume buttons)
   - Feedback utilisateur

2. **Système d'alerte de base**
   - Géolocalisation
   - Notification contacts d'urgence
   - Sauvegarde locale

3. **Enregistrement preuves**
   - Audio automatique
   - Stockage chiffré local
   - Upload différé

### Phase 2 - Réseau de soutien (3-4 semaines)
1. **Interface Aidant**
   - Réception d'alertes
   - Géolocalisation proximité
   - Statut disponibilité

2. **Notifications temps réel**
   - Firebase/FCM setup
   - Push notifications
   - SMS de secours

3. **Interface ONG**
   - Dashboard alertes
   - Gestion ressources
   - Statistiques

### Phase 3 - Fonctionnalités avancées (4-5 semaines)
1. **Forum communautaire**
   - Messages modérés
   - Partage d'expériences
   - Soutien psychologique

2. **Optimisations**
   - Performance hors ligne
   - Synchronisation robuste
   - Sécurité avancée

3. **Interface Admin**
   - Modération globale
   - Analytics détaillées
   - Gestion utilisateurs

## 🤝 Contribution

### Standards de code
- Suivre les conventions Dart/Flutter
- Commenter en français
- Tests unitaires pour les services
- Documentation des API

### Workflow Git
```bash
# Créer une branche feature
git checkout -b feature/sos-button

# Développer et tester
# Commit avec messages clairs

# Push et Pull Request
git push origin feature/sos-button
```

### Code Review
- Sécurité : Vérifier les données sensibles
- Performance : Tester sur devices faibles
- UI/UX : Cohérence avec le design system
- Tests : Couverture des cas critiques

## 📞 Support développement

### Resources utiles
- [Documentation Flutter](https://docs.flutter.dev/)
- [Supabase Docs](https://supabase.com/docs)
- [Material Design 3](https://m3.material.io/)

### Contacts équipe
- **Tech Lead** : [email]
- **UI/UX Designer** : [email]
- **Product Owner** : [email]

---

**Statut** : 🟡 En développement actif
**Dernière mise à jour** : [Date]

# 📚 Documentation du Forum Communautaire Guinemali

## 🎯 Vue d'ensemble

Le Forum Communautaire de Guinemali est un espace d'échange sécurisé et bienveillant où les utilisatrices peuvent partager leurs expériences, demander conseils, et s'entraider. Basé sur 30 ans d'expérience en développement mobile, cette fonctionnalité a été conçue avec un focus particulier sur la sécurité, la confidentialité et l'expérience utilisateur.

## 🏗️ Architecture Technique

### 📁 Structure des fichiers

```
lib/
├── protected_person/
│   ├── models/
│   │   ├── forum_post_model.dart      # Modèle pour les posts
│   │   └── forum_comment_model.dart   # Modèle pour les commentaires
│   ├── screens/
│   │   └── victim_forum_screen.dart   # Écran principal du forum
│   └── widgets/
│       ├── forum_post_card.dart       # Carte d'affichage des posts
│       └── forum_create_post_modal.dart # Modal de création de post
└── core/
    └── services/
        └── forum_service.dart         # Service centralisé du forum
```

### 🔧 Services implémentés

#### ForumService
- **Gestion des posts** : Création, lecture, mise à jour, suppression
- **Gestion des commentaires** : Ajout, récupération, likes
- **Filtrage et recherche** : Par catégorie, tags, contenu
- **Cache local** : Optimisation des performances
- **Gestion des permissions** : Vérification des droits utilisateur

## 🎨 Interface Utilisateur

### Écran Principal (VictimForumScreen)

#### 🎯 Fonctionnalités principales
- **Liste des posts** : Affichage chronologique avec pagination
- **Recherche** : Barre de recherche en temps réel
- **Filtres** : Par catégorie avec badges interactifs
- **Actualisation** : Pull-to-refresh pour mettre à jour le contenu
- **Création** : Bouton flottant pour créer un nouveau post

#### 🎨 Design
- **Couleurs** : Respect de la charte graphique (primaire, secondaire, fond blanc)
- **Animations** : Transitions fluides avec flutter_animate
- **Responsive** : Adaptation à différentes tailles d'écran
- **Accessibilité** : Contrastes appropriés et tailles de police lisibles

### Carte de Post (ForumPostCard)

#### 📋 Informations affichées
- **Auteur** : Nom ou "Anonyme" selon le choix
- **Avatar** : Initiale ou icône générique
- **Titre et contenu** : Avec limitation de lignes
- **Tags** : Affichage des hashtags associés
- **Métadonnées** : Date, likes, commentaires, vues
- **Catégorie** : Badge coloré selon le type

#### 🎯 Interactions
- **Tap** : Navigation vers le détail du post
- **Like** : Toggle du statut "j'aime"
- **Partage** : Fonctionnalité en développement

### Modal de Création (ForumCreatePostModal)

#### 📝 Champs disponibles
- **Titre** : Obligatoire, max 100 caractères
- **Contenu** : Obligatoire, max 1000 caractères
- **Catégorie** : Sélection dans une liste prédéfinie
- **Tags** : Ajout/suppression dynamique
- **Anonymat** : Toggle pour publier anonymement

#### 🎨 Interface
- **Modal bottom sheet** : 90% de la hauteur d'écran
- **Validation** : En temps réel avec messages d'erreur
- **Tags populaires** : Suggestions cliquables
- **Prévisualisation** : Aperçu avant publication

## 📊 Modèles de Données

### ForumPost

```dart
class ForumPost {
  final String id;                    // UUID unique
  final String authorId;              // ID de l'auteur
  final String authorName;            // Nom d'affichage
  final String authorAvatar;          // URL de l'avatar
  final String title;                 // Titre du post
  final String content;               // Contenu principal
  final DateTime createdAt;           // Date de création
  final DateTime updatedAt;           // Date de modification
  final List<String> tags;            // Tags associés
  final int likesCount;               // Nombre de likes
  final int commentsCount;            // Nombre de commentaires
  final int viewsCount;               // Nombre de vues
  final bool isPinned;                // Post épinglé
  final bool isAnonymous;             // Publication anonyme
  final String category;              // Catégorie du post
  final List<String> likedBy;         // Liste des utilisateurs qui ont liké
  final List<String> images;          // Images attachées
  final String status;                // Statut (active, moderated, deleted)
}
```

### ForumComment

```dart
class ForumComment {
  final String id;                    // UUID unique
  final String postId;                // ID du post parent
  final String authorId;              // ID de l'auteur
  final String authorName;            // Nom d'affichage
  final String content;               // Contenu du commentaire
  final DateTime createdAt;           // Date de création
  final int likesCount;               // Nombre de likes
  final List<String> likedBy;         // Liste des utilisateurs qui ont liké
  final bool isAnonymous;             // Commentaire anonyme
  final String status;                // Statut
  final String? parentCommentId;      // ID du commentaire parent (réponses)
}
```

## 🏷️ Catégories et Tags

### 📂 Catégories disponibles
- **Général** : Discussions générales
- **Conseils de sécurité** : Astuces et bonnes pratiques
- **Soutien d'urgence** : Aide immédiate
- **Conseils juridiques** : Questions légales
- **Ressources** : Liens et informations utiles
- **Témoignages** : Partage d'expériences
- **Questions** : Demandes d'aide

### 🏷️ Tags populaires
- `sécurité`, `urgence`, `conseils`, `soutien`
- `légal`, `ressources`, `témoignage`, `question`
- `aide`, `protection`

## 🔒 Sécurité et Confidentialité

### 🛡️ Mesures de protection
- **Anonymat** : Option de publication anonyme
- **Modération** : Système de modération des contenus
- **Validation** : Vérification des entrées utilisateur
- **Permissions** : Contrôle d'accès basé sur les rôles

### 🔐 Données sensibles
- **Chiffrement** : Données sensibles chiffrées
- **Rétention** : Politique de conservation des données
- **Suppression** : Droit à l'oubli implémenté

## 🚀 Fonctionnalités Futures

### 📋 Roadmap
- [ ] **Système de commentaires** : Réponses et discussions
- [ ] **Modération** : Interface de modération pour les admins
- [ ] **Notifications** : Alertes pour nouveaux posts/commentaires
- [ ] **Partage** : Partage de posts sur réseaux sociaux
- [ ] **Images** : Upload et gestion d'images
- [ ] **Recherche avancée** : Filtres multiples et recherche sémantique
- [ ] **Statistiques** : Analytics pour les utilisateurs
- [ ] **Export** : Export des données personnelles

### 🔧 Améliorations techniques
- [ ] **Base de données** : Intégration complète avec Supabase
- [ ] **Cache** : Optimisation du cache local
- [ ] **Performance** : Lazy loading et pagination
- [ ] **Offline** : Support hors ligne
- [ ] **Tests** : Tests unitaires et d'intégration

## 🐛 Dépannage

### ❌ Problèmes courants

#### Posts ne se chargent pas
1. Vérifier la connexion internet
2. Redémarrer l'application
3. Vider le cache de l'application

#### Erreur de création de post
1. Vérifier que tous les champs obligatoires sont remplis
2. S'assurer que l'utilisateur est connecté
3. Vérifier les permissions de l'utilisateur

#### Interface non responsive
1. Vérifier la taille de l'écran
2. Redémarrer l'application
3. Mettre à jour Flutter

### 🔧 Solutions techniques

#### Réinitialisation du cache
```dart
await ForumService.instance.clearCache();
await ForumService.instance.refresh();
```

#### Vérification des permissions
```dart
final userId = await StorageService.instance.getString(AppConstants.keyUserId);
if (userId == null) {
  // Rediriger vers la connexion
}
```

## 📈 Métriques et Analytics

### 📊 Données collectées
- **Posts créés** : Nombre et types de posts
- **Engagement** : Likes, commentaires, vues
- **Utilisateurs actifs** : Fréquence d'utilisation
- **Catégories populaires** : Tendances par catégorie
- **Recherches** : Termes les plus recherchés

### 📈 KPIs
- **Taux d'engagement** : Posts avec interactions
- **Temps de session** : Durée moyenne d'utilisation
- **Taux de rétention** : Utilisateurs récurrents
- **Satisfaction** : Feedback utilisateur

## 🤝 Contribution

### 🛠️ Développement
1. Fork du projet
2. Créer une branche feature
3. Implémenter les changements
4. Ajouter les tests
5. Soumettre une pull request

### 📝 Documentation
- Maintenir cette documentation à jour
- Ajouter des commentaires dans le code
- Créer des guides utilisateur

### 🧪 Tests
- Tests unitaires pour les modèles
- Tests d'intégration pour les services
- Tests UI pour les écrans

## 📞 Support

### 🆘 Contact
- **Email** : support@guinemali.app
- **Documentation** : Cette page
- **Issues** : GitHub Issues

### 📚 Ressources
- [Guide utilisateur](USER_GUIDE.md)
- [API Documentation](API_DOCS.md)
- [Changelog](CHANGELOG.md)

---

*Documentation créée avec ❤️ pour la communauté Guinemali*

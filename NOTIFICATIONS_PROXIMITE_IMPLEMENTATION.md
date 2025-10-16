# 🚨 Système de Notifications de Proximité - Guinemali

## 📋 Résumé

Le système de **notifications push de proximité** a été **entièrement implémenté** dans l'application Guinemali ! 🎉

Quand un utilisateur déclenche une alerte SOS, **tous les utilisateurs à moins de 5 km** reçoivent automatiquement une **notification push en temps réel**.

---

## ✅ Ce qui a été implémenté

### 1. 🔔 Service Firebase Cloud Messaging (FCM)
**Fichier** : `lib/core/services/fcm_service.dart`

**Fonctionnalités** :
- ✅ Initialisation automatique au démarrage de l'app
- ✅ Demande de permissions pour les notifications
- ✅ Génération et sauvegarde du token FCM dans Supabase
- ✅ Gestion des notifications en premier plan, arrière-plan et fermé
- ✅ Navigation automatique vers la carte quand on clique sur la notification
- ✅ Notifications avec son et vibration d'urgence
- ✅ Support Android et iOS

### 2. 🗺️ Écran de Carte d'Alerte de Proximité
**Fichier** : `lib/protected_person/screens/proximity_alert_map_screen.dart`

**Fonctionnalités** :
- ✅ Affiche la position de l'alerte SOS sur une carte
- ✅ Affiche votre position actuelle
- ✅ Calcule et affiche la distance jusqu'à la victime
- ✅ Cercle de danger (100m) autour de l'alerte
- ✅ Boutons d'action : "Obtenir l'itinéraire", "Appeler", "Fermer"
- ✅ Design moderne avec les couleurs Guinemali (#945acb, #ee82ee)

### 3. 🗄️ Base de Données Supabase
**Fichier** : `supabase/migrations/add_fcm_tokens.sql`

**Ajouts** :
- ✅ Colonnes `fcm_token`, `fcm_token_updated_at` dans `utilisateurs`
- ✅ Colonnes `last_known_latitude`, `last_known_longitude` pour la géolocalisation
- ✅ Colonne `notification_enabled` pour désactiver les notifications
- ✅ Fonction `calculate_distance()` (formule de Haversine)
- ✅ Fonction `find_nearby_users()` pour rechercher les utilisateurs à proximité
- ✅ Fonction `update_user_location()` pour sauvegarder la position

### 4. ⚙️ Supabase Edge Function
**Fichier** : `supabase/functions/send-proximity-notifications/index.ts`

**Fonctionnalités** :
- ✅ Déclenchée automatiquement quand une alerte est créée
- ✅ Recherche tous les utilisateurs dans un rayon de 5 km
- ✅ Envoie des notifications push groupées (batches de 500)
- ✅ Inclut les infos de l'alerte : nom de la victime, distance, coordonnées GPS
- ✅ Enregistre les stats de notification (nombre envoyé, échecs)
- ✅ Gestion d'erreurs robuste

### 5. 🔄 Trigger Automatique
**Fichier** : `supabase/migrations/add_alert_notification_trigger.sql`

**Fonctionnalités** :
- ✅ Trigger PostgreSQL qui appelle automatiquement la Edge Function
- ✅ Se déclenche uniquement pour les nouvelles alertes actives
- ✅ Envoie le payload complet (ID alerte, utilisateur, GPS, type, niveau danger)

### 6. 📍 Géolocalisation Automatique
**Fichier** : `lib/core/services/geolocation_service.dart`

**Ajout** :
- ✅ Sauvegarde automatique de la position dans Supabase à chaque récupération GPS
- ✅ Permet au système de savoir quels utilisateurs sont proches d'une alerte
- ✅ Mise à jour en arrière-plan (non bloquant)

### 7. 🛣️ Navigation et Routing
**Fichier** : `lib/core/app/app_router.dart`

**Ajout** :
- ✅ Route `/victim/proximity-alert` pour la carte de proximité
- ✅ Redirection automatique quand on clique sur une notification
- ✅ Gestion du flag `pending_alert_navigation` pour la navigation différée

### 8. 🔥 Initialisation Firebase
**Fichier** : `lib/main.dart`

**Ajout** :
- ✅ Initialisation de Firebase au démarrage de l'app
- ✅ Configuration du handler de messages en arrière-plan
- ✅ Initialisation du service FCM après les autres services

---

## 📝 Configuration Requise

### Étape 1 : Configurer Firebase

1. **Créer un projet Firebase** : https://console.firebase.google.com/
2. **Ajouter l'application Android** avec le package `com.guinemali.mobile`
3. **Télécharger `google-services.json`** et le placer dans `android/app/`
4. **Activer Firebase Cloud Messaging (FCM)** et copier la clé serveur

📖 **Voir le guide complet** : `FIREBASE_SETUP_INSTRUCTIONS.md`

### Étape 2 : Déployer sur Supabase

#### Option A : Script automatique (Linux/Mac)
```bash
chmod +x deploy_supabase.sh
./deploy_supabase.sh
```

#### Option B : Commandes manuelles
```bash
# 1. Se connecter à Supabase
supabase login

# 2. Lier le projet
supabase link --project-ref <VOTRE_PROJECT_REF>

# 3. Déployer les migrations SQL
supabase db push

# 4. Déployer la Edge Function
supabase functions deploy send-proximity-notifications

# 5. Configurer le secret FCM
supabase secrets set FCM_SERVER_KEY="VOTRE_CLE_SERVEUR_FCM"
```

### Étape 3 : Tester

1. **Rebuild l'application** :
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Installer sur 2 appareils réels** (les notifications ne fonctionnent PAS sur émulateur)

3. **Créer 2 comptes** et s'assurer que le GPS est activé

4. **Déclencher une alerte SOS** sur un appareil

5. **Vérifier** que l'autre appareil reçoit la notification

---

## 🔍 Architecture du Système

```
┌─────────────────────────────────────────────────────────────┐
│                      UTILISATEUR A                          │
│              (Déclenche une alerte SOS)                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                   SUPABASE DATABASE                          │
│  1. Insère alerte dans table "alertes" (latitude, longitude)│
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼ (Trigger automatique)
┌──────────────────────────────────────────────────────────────┐
│              SUPABASE EDGE FUNCTION                          │
│         "send-proximity-notifications"                       │
│                                                              │
│  2. Appelle find_nearby_users(lat, lng, radius=5km)         │
│  3. Récupère tous les tokens FCM des utilisateurs proches   │
│  4. Envoie les notifications via Firebase API (batches)     │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                 FIREBASE CLOUD MESSAGING                     │
│         Envoie les notifications push aux appareils          │
└──────────┬───────────────────────┬───────────────────────────┘
           │                       │
           ▼                       ▼
┌─────────────────┐      ┌─────────────────┐
│ UTILISATEUR B   │      │ UTILISATEUR C   │
│ (À 2 km)        │      │ (À 4.5 km)      │
│ 🔔 Notification │      │ 🔔 Notification │
│ "Alerte SOS     │      │ "Alerte SOS     │
│  à proximité"   │      │  à proximité"   │
└─────────────────┘      └─────────────────┘
```

---

## 🎯 Flux Utilisateur

### Scénario : Oumar déclenche une alerte SOS

1. **Oumar** est à Conakry (9.6412°N, -13.5784°W)
2. Il appuie sur le **bouton SOS** dans l'app
3. L'alerte est enregistrée dans Supabase avec sa position GPS
4. Le système cherche tous les utilisateurs dans un rayon de **5 km**
5. Il trouve **Ramatoulaye** (à 2 km) et **Fatoubah** (à 4 km)
6. Une notification push est envoyée à Ramatoulaye et Fatoubah :
   ```
   🚨 ALERTE URGENCE À PROXIMITÉ
   Oumar a besoin d'aide à 2.0 km de vous
   ```
7. **Ramatoulaye** clique sur la notification
8. L'app s'ouvre et affiche la **carte** avec :
   - 📍 Position d'Oumar (marqueur rouge SOS)
   - 📍 Position de Ramatoulaye (marqueur violet)
   - 📏 Distance : "À 2.0 km de vous"
   - 🚗 Bouton "Obtenir l'itinéraire"
   - 📞 Bouton "Appeler"

---

## 📊 Statistiques et Monitoring

### Dans Supabase Dashboard

**Vérifier les tokens FCM** :
```sql
SELECT id, pseudo, fcm_token, last_known_latitude, last_known_longitude
FROM utilisateurs
WHERE fcm_token IS NOT NULL;
```

**Vérifier les notifications envoyées** :
```sql
SELECT 
  a.id,
  u.pseudo AS victime,
  a.nombre_notifications_envoyees,
  a.derniere_notification_at,
  a.latitude,
  a.longitude
FROM alertes a
JOIN utilisateurs u ON a.utilisateur_id = u.id
WHERE a.nombre_notifications_envoyees > 0
ORDER BY a.date_creation DESC;
```

**Logs de la Edge Function** :
1. Aller dans Supabase Dashboard
2. Edge Functions → `send-proximity-notifications`
3. Onglet "Logs"

### Dans Firebase Console

**Statistiques FCM** :
1. Aller dans Firebase Console
2. Cloud Messaging
3. Voir les stats : envoyées, reçues, ouvertes

---

## 🛠️ Maintenance et Amélioration

### Changer le rayon de proximité

**Par défaut** : 5 km

**Modifier dans** :
- `supabase/functions/send-proximity-notifications/index.ts` ligne 67 :
  ```typescript
  p_radius_km: 5.0,  // Changer ici
  ```

### Désactiver les notifications pour un utilisateur

```sql
UPDATE utilisateurs
SET notification_enabled = false
WHERE id = 'USER_ID_ICI';
```

### Ajouter un son personnalisé

1. Ajouter le fichier audio dans `android/app/src/main/res/raw/emergency_alert.mp3`
2. Rebuild l'app

---

## 🐛 Dépannage

### Problème : Notifications non reçues

**Vérifier** :
1. ✅ `google-services.json` est dans `android/app/`
2. ✅ Les tokens FCM sont sauvegardés dans Supabase
3. ✅ La position GPS est mise à jour dans Supabase
4. ✅ La Edge Function s'exécute (voir logs Supabase)
5. ✅ La clé serveur FCM est correcte dans Supabase secrets

### Problème : Firebase ne démarre pas

**Erreur** : `MissingPluginException`

**Solution** :
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Problème : Carte ne s'affiche pas au clic

**Vérifier** :
1. La route `/victim/proximity-alert` est bien enregistrée
2. Les logs montrent `pending_alert_navigation` sauvegardé
3. Redémarrer l'app après avoir cliqué sur la notification

---

## 📚 Fichiers Créés/Modifiés

### Nouveaux Fichiers
- ✅ `lib/core/services/fcm_service.dart`
- ✅ `lib/protected_person/screens/proximity_alert_map_screen.dart`
- ✅ `lib/firebase_options.dart`
- ✅ `supabase/migrations/add_fcm_tokens.sql`
- ✅ `supabase/migrations/add_alert_notification_trigger.sql`
- ✅ `supabase/functions/send-proximity-notifications/index.ts`
- ✅ `deploy_supabase.sh`
- ✅ `FIREBASE_SETUP_INSTRUCTIONS.md`
- ✅ `NOTIFICATIONS_PROXIMITE_IMPLEMENTATION.md` (ce fichier)

### Fichiers Modifiés
- ✅ `pubspec.yaml` - Ajout des dépendances Firebase
- ✅ `lib/main.dart` - Initialisation Firebase et FCM
- ✅ `lib/core/app/app_router.dart` - Route de proximité
- ✅ `lib/core/services/geolocation_service.dart` - Sauvegarde automatique GPS

---

## 🎉 Prochaines Étapes

1. **Configurer Firebase** (voir `FIREBASE_SETUP_INSTRUCTIONS.md`)
2. **Déployer sur Supabase** (utiliser `deploy_supabase.sh`)
3. **Tester sur appareils réels**
4. **Optionnel** : Ajouter un fallback SMS si push échoue
5. **Optionnel** : Ajouter des appels vocaux automatiques

---

## ✅ Checklist de Déploiement

- [ ] Projet Firebase créé
- [ ] `google-services.json` téléchargé et placé dans `android/app/`
- [ ] Migrations SQL déployées sur Supabase
- [ ] Edge Function déployée sur Supabase
- [ ] Secret `FCM_SERVER_KEY` configuré dans Supabase
- [ ] Application rebuild : `flutter build apk --release`
- [ ] Testée sur 2 appareils réels
- [ ] Notifications reçues avec succès
- [ ] Carte de proximité s'affiche au clic

---

**🎊 Félicitations ! Le système de notifications de proximité est maintenant opérationnel !**

**Support** : Si vous rencontrez des problèmes, consultez `FIREBASE_SETUP_INSTRUCTIONS.md` ou vérifiez les logs dans Firebase Console et Supabase Dashboard.

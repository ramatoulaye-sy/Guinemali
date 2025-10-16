# 🔥 Instructions de Configuration Firebase pour Guinemali

## 📋 Étape 1 : Créer un Projet Firebase

1. **Aller sur Firebase Console** : https://console.firebase.google.com/
2. **Cliquer sur "Ajouter un projet"**
3. **Nom du projet** : `Guinemali` (ou tout autre nom)
4. **Activer Google Analytics** : Optionnel (recommandé pour les stats)
5. **Créer le projet**

---

## 📱 Étape 2 : Ajouter l'Application Android

1. Dans la console Firebase, cliquer sur l'icône **Android** 
2. **Nom du package Android** : `com.guinemali.mobile`
   - ⚠️ **IMPORTANT** : Doit correspondre à `applicationId` dans `android/app/build.gradle.kts`
3. **Nom de l'app** (optionnel) : `Guinemali`
4. **Certificat de signature SHA-1** (optionnel pour FCM)
5. **Cliquer sur "Enregistrer l'application"**

---

## 📥 Étape 3 : Télécharger le Fichier de Configuration

1. Firebase génère automatiquement le fichier **`google-services.json`**
2. **Télécharger** ce fichier
3. **Copier** `google-services.json` dans le dossier :
   ```
   android/app/google-services.json
   ```
4. ⚠️ **NE PAS** commiter ce fichier dans Git (déjà dans `.gitignore`)

---

## ⚙️ Étape 4 : Activer Firebase Cloud Messaging (FCM)

1. Dans Firebase Console, aller dans **"Paramètres du projet"** ⚙️
2. Onglet **"Cloud Messaging"**
3. Sous **"API Cloud Messaging (héritée)"**, activer l'API
4. Copier la **"Clé du serveur"** (Server Key)
5. **Sauvegarder cette clé**, elle sera nécessaire pour Supabase

---

## 🔧 Étape 5 : Configurer Supabase Edge Function

### 5.1. Installer Supabase CLI (si pas déjà fait)
```bash
npm install -g supabase
```

### 5.2. Se connecter à Supabase
```bash
supabase login
```

### 5.3. Lier votre projet
```bash
supabase link --project-ref <VOTRE_PROJECT_REF>
```

### 5.4. Déployer la migration SQL
```bash
supabase db push
```

### 5.5. Déployer la Edge Function
```bash
supabase functions deploy send-proximity-notifications
```

### 5.6. Configurer les secrets
```bash
# Ajouter la clé serveur FCM (copiée à l'étape 4)
supabase secrets set FCM_SERVER_KEY="VOTRE_CLE_SERVEUR_FCM"

# Vérifier que les autres secrets sont déjà configurés
supabase secrets list
```

Vous devriez voir :
- `SUPABASE_URL` ✅
- `SUPABASE_SERVICE_ROLE_KEY` ✅
- `FCM_SERVER_KEY` ✅ (nouveau)

---

## 🚀 Étape 6 : Tester le Système

### 6.1. Rebuild l'Application
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 6.2. Installer sur un Appareil Réel
⚠️ **IMPORTANT** : Les notifications push ne fonctionnent PAS sur l'émulateur !
```bash
flutter install
```

### 6.3. Test de Notification

1. **Inscription** : Créer un compte dans l'app
2. **Permissions** : Accepter les notifications quand demandé
3. **Localisation** : S'assurer que le GPS est activé
4. **Créer 2 comptes** sur 2 téléphones différents (ou utiliser 2 appareils)
5. **Rapprocher les 2 appareils** (moins de 5 km)
6. **Déclencher une alerte SOS** sur un des appareils
7. **Vérifier** que l'autre appareil reçoit la notification push

### 6.4. Vérifier les Logs

Dans Supabase Dashboard :
1. Aller dans **"Edge Functions"**
2. Cliquer sur `send-proximity-notifications`
3. Onglet **"Logs"**
4. Vérifier que la fonction s'exécute bien quand une alerte est créée

---

## 🔍 Debugging

### Problème : Notifications non reçues

**Vérifier :**
1. ✅ `google-services.json` est bien dans `android/app/`
2. ✅ Le token FCM est bien sauvegardé dans Supabase :
   ```sql
   SELECT id, pseudo, fcm_token FROM utilisateurs WHERE fcm_token IS NOT NULL;
   ```
3. ✅ La localisation est mise à jour :
   ```sql
   SELECT id, pseudo, last_known_latitude, last_known_longitude 
   FROM utilisateurs 
   WHERE last_known_latitude IS NOT NULL;
   ```
4. ✅ Les logs de la Edge Function ne montrent pas d'erreur
5. ✅ La clé serveur FCM est correcte dans Supabase

### Problème : Firebase ne démarre pas

**Erreur typique** : `MissingPluginException: No implementation found for method Firebase#initializeApp`

**Solution** :
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 📊 Monitoring des Notifications

### Dashboard Firebase
1. Aller dans **"Cloud Messaging"**
2. Vous verrez les stats :
   - Notifications envoyées
   - Taux de réception
   - Taux d'ouverture

### Dashboard Supabase
```sql
-- Nombre de notifications envoyées par alerte
SELECT 
  id,
  utilisateur_id,
  nombre_notifications_envoyees,
  derniere_notification_at
FROM alertes
WHERE nombre_notifications_envoyees > 0
ORDER BY derniere_notification_at DESC;
```

---

## 🎯 Prochaines Étapes Optionnelles

### 1. Ajouter iOS Support
- Créer un projet iOS dans Firebase
- Télécharger `GoogleService-Info.plist`
- Placer dans `ios/Runner/`

### 2. SMS de Secours (via Twilio)
- S'inscrire sur Twilio
- Acheter un numéro
- Configurer l'envoi de SMS si push échoue

### 3. Appels Vocaux Automatiques
- Intégrer Twilio Voice
- Enregistrer un message vocal d'urgence

---

## ✅ Checklist Finale

- [ ] Projet Firebase créé
- [ ] Application Android ajoutée
- [ ] `google-services.json` téléchargé et placé dans `android/app/`
- [ ] FCM activé et clé serveur copiée
- [ ] Migrations SQL déployées sur Supabase
- [ ] Edge Function déployée
- [ ] Secret `FCM_SERVER_KEY` configuré dans Supabase
- [ ] Application rebuild et testée sur appareil réel
- [ ] Notifications push reçues avec succès

---

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifier les logs Firebase Console
2. Vérifier les logs Supabase Edge Functions
3. Vérifier que les tokens FCM sont bien sauvegardés dans la base
4. Tester avec `flutter run` pour voir les logs en temps réel

**Bon déploiement ! 🚀**

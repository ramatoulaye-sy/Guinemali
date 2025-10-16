# 🔥 GUIDE VISUEL : Configuration Firebase pour Guinemali

## ✅ ÉTAPES COMPLÉTÉES AUTOMATIQUEMENT

J'ai déjà configuré automatiquement :
- ✅ Ajout du plugin Google Services dans `android/build.gradle.kts`
- ✅ Application du plugin dans `android/app/build.gradle.kts`
- ✅ Ajout des dépendances Firebase (BOM, Messaging, Analytics)

---

## 📋 CE QUE TU DOIS FAIRE MAINTENANT

### **ÉTAPE 1 : Aller sur Firebase Console**

1. Ouvre ton navigateur
2. Va sur : **https://console.firebase.google.com/**
3. Connecte-toi avec ton compte Google

---

### **ÉTAPE 2 : Créer le Projet**

1. **Clique sur "Ajouter un projet"**
   
   ```
   ┌─────────────────────────────────────┐
   │  ➕ Ajouter un projet               │
   │                                     │
   │  [  Cliquez ici  ]                 │
   └─────────────────────────────────────┘
   ```

2. **Entre le nom** : `Guinemali`
   
   ```
   Nom du projet : [Guinemali        ]
   
   [ Continuer ]
   ```

3. **Google Analytics** (optionnel) :
   - ✅ Je recommande de l'activer
   - Choisis un compte existant ou crée-en un nouveau
   s
   ```
   Activer Google Analytics ?
   ○ Non
   ● Oui  ← Recommandé
   
   Compte : [Sélectionner...]
   
   [ Créer le projet ]
   ```

4. **Attends** que Firebase crée le projet (30 secondes environ)

---

### **ÉTAPE 3 : Ajouter l'Application Android**

1. Une fois le projet créé, **clique sur l'icône Android** 🤖
   
   ```
   Bienvenue dans Guinemali
   
   Commencez en ajoutant Firebase à votre application
   
   [ 🍎 iOS ]  [ 🤖 Android ]  [ 🌐 Web ]
                    ↑
              Clique ici
   ```

2. **Remplis le formulaire** :
   
   ```
   ┌───────────────────────────────────────────┐
   │ Enregistrez votre application              │
   ├───────────────────────────────────────────┤
   │                                            │
   │ Nom du package Android (obligatoire)      │
   │ [com.guinemali.mobile              ]      │
   │    ⚠️ IMPORTANT : Copie exactement ça !   │
   │                                            │
   │ Surnom de l'app (optionnel)               │
   │ [Guinemali                         ]      │
   │                                            │
   │ Certificat SHA-1 (optionnel)              │
   │ [                                  ]      │
   │    Laisse vide pour l'instant             │
   │                                            │
   │              [ Enregistrer l'application ] │
   └───────────────────────────────────────────┘
   ```

3. **Clique sur "Enregistrer l'application"**

---

### **ÉTAPE 4 : Télécharger google-services.json**

1. Firebase va te montrer une page avec **"Télécharger google-services.json"**
   
   ```
   ┌───────────────────────────────────────────┐
   │ 2. Téléchargez le fichier de configuration│
   ├───────────────────────────────────────────┤
   │                                            │
   │  📄 google-services.json                   │
   │                                            │
   │      [ Télécharger google-services.json ] │
   │           ↑                                │
   │      Clique ici                            │
   │                                            │
   │ Déplacez ce fichier dans le dossier :     │
   │ android/app/                               │
   │                                            │
   │              [ Suivant ]                   │
   └───────────────────────────────────────────┘
   ```

2. **Clique sur "Télécharger google-services.json"**
   - Le fichier sera téléchargé dans ton dossier Téléchargements

3. **TRÈS IMPORTANT** : Copie ce fichier dans le bon dossier
   
   **Sur Windows** :
   - Ouvre l'Explorateur de fichiers
   - Va dans ton dossier Téléchargements
   - Copie le fichier `google-services.json`
   - Va dans : `C:\Users\USER\Desktop\Guinemali\android\app\`
   - Colle le fichier ici
   
   **Structure finale** :
   ```
   Guinemali/
   └── android/
       └── app/
           ├── src/
           ├── build.gradle.kts
           └── google-services.json  ← Le fichier doit être ici !
   ```

4. **Clique sur "Suivant"** dans Firebase Console (tu peux ignorer les étapes suivantes, je les ai déjà faites)

5. **Clique sur "Continuer vers la console"**

---

### **ÉTAPE 5 : Récupérer la Clé Serveur FCM**

1. Dans Firebase Console, **clique sur l'icône ⚙️** (roue dentée) en haut à gauche

2. **Clique sur "Paramètres du projet"**
   
   ```
   ┌──────────────────┐
   │  ⚙️ Paramètres   │
   │                  │
   │  ▶ Paramètres    │ ← Clique ici
   │    du projet     │
   │                  │
   │  Utilisateurs    │
   │  et autorisations│
   └──────────────────┘
   ```

3. **Va dans l'onglet "Cloud Messaging"**
   
   ```
   [ Général ] [ Comptes de service ] [ Cloud Messaging ] [ Intégrations ]
                                           ↑
                                      Clique ici
   ```

4. Si tu vois **"API Cloud Messaging (héritée) est désactivée"** :
   
   ```
   ⚠️ API Cloud Messaging (héritée) est désactivée
   
   [ Activer l'API Cloud Messaging (héritée) ]
        ↑
   Clique ici
   ```
   
   - Clique sur **"Activer"**
   - Firebase va te rediriger vers Google Cloud Console
   - Clique sur **"Activer"** dans Google Cloud
   - Retourne dans Firebase Console

5. **Copie la "Clé du serveur"** (Server Key)
   
   ```
   ┌────────────────────────────────────────────┐
   │ API Cloud Messaging (héritée)              │
   ├────────────────────────────────────────────┤
   │                                             │
   │ Clé du serveur (héritée)                   │
   │ AAAAxxxxx:APA91bFxxxxxxxxxxxxxxxxxxxx...   │
   │                                     [📋]    │
   │                                      ↑      │
   │                              Clique ici     │
   │                                             │
   └────────────────────────────────────────────┘
   ```
   
   - Clique sur l'icône **📋** (copier)
   - La clé est maintenant dans ton presse-papiers
   - **GARDE CETTE CLÉ**, tu en auras besoin pour Supabase !

---

### **ÉTAPE 6 : Vérifier que tout est OK**

Une fois que tu as copié `google-services.json`, reviens ici et tape cette commande dans le terminal :

```powershell
Test-Path "android\app\google-services.json"
```

**Résultat attendu** : `True`

Si tu vois `True`, c'est parfait ! ✅

Si tu vois `False`, le fichier n'est pas au bon endroit. ❌

---

## 🎯 RÉCAPITULATIF

### Ce que tu dois avoir maintenant :

1. ✅ Un projet Firebase créé (nom : `Guinemali`)
2. ✅ Une application Android ajoutée (package : `com.guinemali.mobile`)
3. ✅ Le fichier `google-services.json` téléchargé et copié dans `android/app/`
4. ✅ La clé serveur FCM copiée dans ton presse-papiers ou notée quelque part

---

## 📞 Besoin d'aide ?

**Problème 1** : Je ne trouve pas le fichier `google-services.json` téléchargé
- Regarde dans ton dossier Téléchargements
- Le fichier s'appelle exactement `google-services.json`

**Problème 2** : Je ne vois pas "Cloud Messaging" dans Firebase
- Assure-toi d'avoir créé une application Android d'abord
- Rafraîchis la page

**Problème 3** : L'API Cloud Messaging est désactivée
- Clique sur "Activer l'API"
- Accepte dans Google Cloud Console
- Retourne dans Firebase

---

## ✅ PROCHAINE ÉTAPE

Une fois que tu as :
- ✅ Copié `google-services.json` dans `android/app/`
- ✅ Copié la clé serveur FCM

**Dis-moi "C'est fait !"** et je t'aiderai avec la configuration Supabase ! 🚀

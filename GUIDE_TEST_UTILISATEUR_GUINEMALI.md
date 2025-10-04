# 📱 GUIDE DE TEST - APPLICATION GUINEMALI
## Version 0.2.0 - Tests Utilisateurs

---

## 🎯 **OBJECTIF DU TEST**
Tester l'application Guinemali pour s'assurer qu'elle fonctionne parfaitement avant la mise en production. Ce guide vous aidera à vérifier toutes les fonctionnalités importantes.

---

## 📋 **PRÉPARATION DU TEST**

### **Matériel nécessaire :**
- ✅ Téléphone Android avec l'APK Guinemali installé
- ✅ Connexion Internet (WiFi ou données mobiles)
- ✅ 15-20 minutes de temps libre

### **Informations de test :**
- **Version :** 0.2.0
- **Plateforme :** Android uniquement
- **Langues :** Français et English

---

## 🔐 **TEST 1 : INSCRIPTION ET CONNEXION**

### **1.1 - Inscription (Nouveau compte)**

**✅ À tester :**
1. Ouvrir l'application Guinemali
2. Cliquer sur "S'inscrire" ou "Créer un compte"
3. Remplir le formulaire d'inscription :

| Champ | Valeur de test | Validation |
|-------|----------------|------------|
| **Pseudo** | `testuser2024` | ✅ Doit être unique |
| **Prénom** | `Test` | ✅ Obligatoire |
| **Téléphone** | `621123456` | ⚪ Optionnel |
| **Code PIN** | `1234` | ✅ 4-6 chiffres |
| **Confirmer PIN** | `1234` | ✅ Doit correspondre |
| **Langue** | `Français` | ✅ Sélectionner |
| **Région** | `Conakry` | ⚪ Optionnel |

4. ✅ Cocher "J'accepte les conditions d'utilisation"
5. ✅ Cliquer sur "Créer mon compte"
6. ✅ Vérifier le message de bienvenue
7. ✅ Vérifier la redirection vers le tableau de bord

**❌ Tests d'erreur :**
- Pseudo déjà utilisé → Doit afficher "Ce pseudo est déjà utilisé"
- PIN trop court → Doit afficher erreur de validation
- PIN de confirmation différent → Doit afficher erreur
- Conditions non cochées → Doit empêcher l'inscription

---

### **1.2 - Connexion (Compte existant)**

**✅ À tester :**
1. Sur l'écran de connexion
2. Entrer le pseudo : `testuser2024`
3. Entrer le PIN : `1234`
4. Cliquer sur "Se connecter"
5. ✅ Vérifier la connexion réussie
6. ✅ Vérifier la redirection vers le tableau de bord

**❌ Tests d'erreur :**
- Pseudo incorrect → Doit afficher "Identifiants incorrects"
- PIN incorrect → Doit afficher "Identifiants incorrects"

---

## 🏠 **TEST 2 : TABLEAU DE BORD PRINCIPAL**

### **2.1 - Interface générale**

**✅ À vérifier :**
1. **En-tête :** Photo de profil et nom d'utilisateur affichés
2. **Statuts :** WiFi, GPS, Microphone visibles et cliquables
3. **Bouton SOS :** Grand bouton rouge au centre
4. **Boutons rapides :** GPS et Actions rapides visibles en bas
5. **Navigation footer :** 4 icônes (Accueil, Contacts, Forum, Menu)

### **2.2 - Boutons de statut**

**✅ À tester :**
1. **WiFi :** Cliquer → Doit afficher statut de connexion
2. **GPS :** Cliquer → Doit demander permissions si nécessaire
3. **Microphone :** Cliquer → Doit afficher statut des permissions

---

## 🚨 **TEST 3 : FONCTIONNALITÉ SOS (CRITIQUE)**

### **3.1 - Déclenchement d'alerte**

**⚠️ ATTENTION : Testez en mode sécurisé !**

**✅ À tester :**
1. Cliquer sur le grand bouton rouge SOS
2. ✅ Confirmer l'alerte dans la popup
3. ✅ Vérifier l'affichage de l'écran d'alerte active
4. ✅ Vérifier que l'alerte est créée en base de données

**🔍 À vérifier :**
- Message de confirmation
- Redirection vers l'écran d'alerte active
- Indicateurs visuels (bouton pulsant, couleurs)
- Pas de crash de l'application

### **3.2 - Écran d'alerte active**

**✅ À tester :**
1. **Bouton retour :** Cliquer → Doit retourner au tableau de bord
2. **"Je suis en sécurité" :**
   - Cliquer → Confirmer dans la popup
   - ✅ Vérifier l'arrêt de l'alerte
   - ✅ Vérifier le retour au tableau de bord
3. **"Annuler l'alerte" :**
   - Cliquer → Confirmer dans la popup
   - ✅ Vérifier l'annulation de l'alerte
   - ✅ Vérifier le retour au tableau de bord

---

## 👥 **TEST 4 : NAVIGATION ET MENUS**

### **4.1 - Navigation footer**

**✅ À tester :**
1. **Accueil :** Cliquer → Doit rester sur le tableau de bord
2. **Contacts :** Cliquer → Doit ouvrir la liste des contacts
3. **Forum :** Cliquer → Doit ouvrir le forum communautaire
4. **Menu :** Cliquer → Doit ouvrir le menu modal

### **4.2 - Menu modal**

**✅ À tester :**
1. Ouvrir le menu (icône hamburger)
2. Tester chaque option :
   - **Paramètres** → Doit ouvrir les paramètres
   - **Preuves** → Doit ouvrir la liste des preuves
   - **Sécurité** → Doit ouvrir les paramètres de sécurité
   - **Permissions** → Doit ouvrir la gestion des permissions
   - **Historique** → Doit ouvrir l'historique des alertes
   - **ONG** → Doit ouvrir la liste des ONG
   - **Plan d'urgence** → Doit ouvrir le plan d'urgence
3. ✅ Vérifier que chaque écran s'ouvre correctement
4. ✅ Vérifier le bouton retour sur chaque écran

### **4.3 - Forum communautaire**

**✅ À tester :**
1. Accéder au forum via la navigation
2. **En-tête :** Vérifier que tous les boutons sont cliquables :
   - Titre "Communauté" → Doit afficher un message
   - Bouton recherche → Doit afficher "En développement"
   - Bouton notifications → Doit être cliquable
   - Bouton profil → Doit être cliquable
3. ✅ Vérifier l'affichage des posts/commentaires
4. ✅ Tester le scroll vertical

---

## 📱 **TEST 5 : FONCTIONNALITÉS AVANCÉES**

### **5.1 - Permissions**

**✅ À tester :**
1. Aller dans Menu → Permissions
2. Vérifier les permissions :
   - **Localisation** → Doit être demandée si nécessaire
   - **Microphone** → Doit être demandée si nécessaire
   - **Caméra** → Doit être demandée si nécessaire
   - **Stockage** → Doit être demandée si nécessaire

### **5.2 - Paramètres**

**✅ À tester :**
1. Aller dans Menu → Paramètres
2. Vérifier les options disponibles
3. Tester les modifications de paramètres
4. ✅ Vérifier la sauvegarde des préférences

### **5.3 - Plan d'urgence**

**✅ À tester :**
1. Aller dans Menu → Plan d'urgence
2. ✅ Vérifier l'affichage du plan
3. ✅ Vérifier qu'il n'y a pas d'overflow dans l'en-tête
4. Tester l'édition du plan si disponible

---

## 🔍 **TEST 6 : GESTION DES ERREURS**

### **6.1 - Connexion réseau**

**✅ À tester :**
1. Couper la connexion WiFi/données
2. Essayer d'utiliser l'application
3. ✅ Vérifier les messages d'erreur appropriés
4. Remettre la connexion
5. ✅ Vérifier que l'application fonctionne à nouveau

### **6.2 - Permissions refusées**

**✅ À tester :**
1. Refuser les permissions de localisation
2. Essayer de déclencher une alerte SOS
3. ✅ Vérifier que l'alerte se crée quand même (avec coordonnées 0,0)
4. ✅ Vérifier les messages informatifs

---

## 📊 **TEST 7 : PERFORMANCE ET STABILITÉ**

### **7.1 - Performance**

**✅ À vérifier :**
1. **Temps de démarrage :** Application doit se lancer en moins de 5 secondes
2. **Fluidité :** Navigation doit être fluide, pas de lag
3. **Mémoire :** Pas de fuite mémoire visible
4. **Batterie :** Consommation normale

### **7.2 - Stabilité**

**✅ À tester :**
1. **Navigation rapide :** Changer rapidement entre les écrans
2. **Retour système :** Utiliser le bouton retour Android
3. **Rotation :** Faire tourner l'écran (si supporté)
4. **Fermeture/ouverture :** Fermer et rouvrir l'application

---

## 🚨 **PROBLÈMES CRITIQUES À SIGNALER**

### **❌ Bloquants (doivent être corrigés) :**
- Application qui crash
- Bouton SOS qui ne fonctionne pas
- Impossible de se connecter
- Écran d'alerte active qui ne s'affiche pas
- Navigation qui ne fonctionne pas

### **⚠️ Importants (à corriger si possible) :**
- Boutons non cliquables
- Textes invisibles (blanc sur blanc)
- Messages d'erreur confus
- Performance lente

### **💡 Suggestions (améliorations) :**
- Interface plus intuitive
- Messages plus clairs
- Animations plus fluides

---

## 📝 **RAPPORT DE TEST**

### **Informations à noter :**

**📱 Appareil de test :**
- Modèle : _______________
- Version Android : _______________
- Opérateur : _______________

**📊 Résultats :**
- [ ] Tests d'inscription : ✅ Réussi / ❌ Échec
- [ ] Tests de connexion : ✅ Réussi / ❌ Échec
- [ ] Tests SOS : ✅ Réussi / ❌ Échec
- [ ] Tests navigation : ✅ Réussi / ❌ Échec
- [ ] Tests permissions : ✅ Réussi / ❌ Échec
- [ ] Tests performance : ✅ Réussi / ❌ Échec

**🐛 Problèmes rencontrés :**
1. _________________________
2. _________________________
3. _________________________

**📸 Captures d'écran :**
- Prendre des captures des problèmes rencontrés
- Noter les étapes pour reproduire les bugs

**⭐ Note globale :** ___/10

---

## 📞 **CONTACT ET SUPPORT**

**Pour signaler des problèmes :**
- 📧 Email : [votre-email]
- 📱 WhatsApp : [votre-numéro]
- 💬 Discord : [votre-serveur]

**Merci pour votre participation aux tests !**
Votre feedback est essentiel pour améliorer Guinemali et assurer la sécurité des utilisateurs. 🙏

---

*Document créé le : $(date)*
*Version de l'app : 0.2.0*
*Dernière mise à jour : $(date)*

# 🎙️ **GUIDE DE DÉPANNAGE - ENREGISTREMENT DES PREUVES**

## 🚨 **Problème Identifié**
**Date :** $(Get-Date -Format "dd/MM/yyyy HH:mm")
**Statut :** 🔧 **EN COURS DE RÉSOLUTION**

---

## 1. 📋 **Description du Problème**

### **Symptômes Observés**
- ❌ **Enregistrement audio** : Ne fonctionne pas lors du déclenchement d'alerte SOS
- ❌ **Enregistrement vidéo** : Ne démarre pas automatiquement
- ❌ **Permissions** : Problèmes potentiels avec les permissions microphone/caméra
- ❌ **Services multiples** : Confusion entre EvidenceService et AudioRecordingService

### **Services Impliqués**
1. **EvidenceService** : Service principal pour l'enregistrement des preuves
2. **AudioRecordingService** : Service alternatif pour l'enregistrement audio
3. **AlertService** : Déclenche l'enregistrement lors d'une alerte SOS

---

## 2. 🔍 **Diagnostic et Tests**

### **Test 1 : Vérification des Permissions**
```dart
// Test des permissions microphone
final micStatus = await Permission.microphone.request();
if (micStatus.isGranted) {
  print('✅ Permission microphone accordée');
} else {
  print('❌ Permission microphone refusée');
}
```

### **Test 2 : Initialisation du Service**
```dart
// Test d'initialisation EvidenceService
try {
  await EvidenceService.instance.initialize();
  print('✅ EvidenceService initialisé');
} catch (e) {
  print('❌ Erreur initialisation: $e');
}
```

### **Test 3 : Enregistrement Audio Simple**
```dart
// Test d'enregistrement audio direct
try {
  await EvidenceService.instance.startAudioRecording('test-alert-123');
  await Future.delayed(Duration(seconds: 3));
  await EvidenceService.instance.stopAudioRecording();
  print('✅ Enregistrement audio test réussi');
} catch (e) {
  print('❌ Erreur enregistrement: $e');
}
```

---

## 3. 🔧 **Solutions Appliquées**

### **Solution 1 : Bouton de Test dans l'Interface**
- ✅ **Ajouté** : Bouton "Test Enregistrement Audio" dans l'écran de profil
- ✅ **Localisation** : Section "Statistiques" du profil utilisateur
- ✅ **Fonctionnalité** : Test direct de l'enregistrement audio

### **Solution 2 : Amélioration de la Gestion des Erreurs**
```dart
/// Test de l'enregistrement des preuves
Future<void> _testEvidenceRecording() async {
  try {
    // Message de début
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎙️ Test d\'enregistrement en cours...')),
    );

    // Test simple d'enregistrement audio
    await EvidenceService.instance.initialize();
    await EvidenceService.instance.startAudioRecording('test-alert-123');
    await Future.delayed(Duration(seconds: 3));
    await EvidenceService.instance.stopAudioRecording();
    
    // Message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Test réussi !')),
    );
  } catch (e) {
    // Message d'erreur détaillé
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Erreur: $e')),
    );
    print('❌ Erreur détaillée: $e');
  }
}
```

### **Solution 3 : Vérification des Permissions**
```dart
// Vérification améliorée des permissions
if (!await Permission.microphone.isGranted) {
  final status = await Permission.microphone.request();
  if (!status.isGranted) {
    throw Exception('Permission microphone requise pour enregistrer l\'audio');
  }
}

if (await _audioRecorder.hasPermission()) {
  // Procéder à l'enregistrement
} else {
  throw Exception('Permission microphone refusée par l\'enregistreur');
}
```

---

## 4. 📱 **Instructions de Test**

### **Étapes pour Tester l'Enregistrement**

1. **Ouvrir l'Application**
   - Lancer l'application Guinemali
   - Se connecter avec un compte utilisateur

2. **Accéder au Profil**
   - Aller dans "Mon Profil"
   - Descendre jusqu'à la section "Statistiques"

3. **Tester l'Enregistrement**
   - Cliquer sur le bouton "Test Enregistrement Audio"
   - Observer les messages de statut
   - Vérifier les logs dans la console

4. **Vérifier les Résultats**
   - Message de succès : "✅ Test d'enregistrement audio terminé avec succès !"
   - Message d'erreur : "❌ Erreur lors du test: [détails]"

### **Logs à Surveiller**
```
🎙️ Test d'enregistrement en cours...
✅ EvidenceService initialisé
✅ Enregistrement audio démarré: [chemin_fichier]
✅ Enregistrement audio arrêté: [chemin_fichier]
✅ Test d'enregistrement audio terminé avec succès !
```

---

## 5. 🛠️ **Corrections Techniques**

### **Problème 1 : Services Non Coordonnés**
**Cause :** EvidenceService et AudioRecordingService fonctionnent indépendamment
**Solution :** Utiliser uniquement EvidenceService pour l'enregistrement des preuves

### **Problème 2 : Permissions Non Vérifiées**
**Cause :** Les permissions ne sont pas vérifiées avant l'enregistrement
**Solution :** Ajouter une vérification complète des permissions

### **Problème 3 : Gestion d'Erreurs Insuffisante**
**Cause :** Les erreurs ne sont pas correctement capturées et affichées
**Solution :** Améliorer la gestion d'erreurs avec des messages détaillés

---

## 6. 🔄 **Prochaines Étapes**

### **Tests à Effectuer**
1. ✅ **Test d'enregistrement audio simple** (implémenté)
2. 🔄 **Test d'enregistrement vidéo**
3. 🔄 **Test d'enregistrement lors d'alerte SOS**
4. 🔄 **Test de sauvegarde des preuves**

### **Améliorations Prévues**
1. **Interface de Test** : Ajouter plus d'options de test
2. **Logs Détaillés** : Améliorer les messages de débogage
3. **Gestion d'État** : Afficher le statut d'enregistrement en temps réel
4. **Permissions** : Interface pour gérer les permissions

---

## 7. 📞 **Support et Dépannage**

### **En Cas de Problème**
1. **Vérifier les Permissions** : Aller dans les paramètres de l'appareil
2. **Redémarrer l'App** : Fermer et relancer l'application
3. **Vérifier les Logs** : Consulter la console pour les erreurs détaillées
4. **Tester sur Différents Appareils** : Vérifier la compatibilité

### **Messages d'Erreur Courants**
- `Permission microphone refusée` : Aller dans Paramètres > Applications > Guinemali > Permissions
- `Caméra non initialisée` : Redémarrer l'application
- `Enregistrement déjà en cours` : Attendre ou redémarrer l'application

---

**Note :** Ce guide sera mis à jour au fur et à mesure de la résolution des problèmes d'enregistrement.

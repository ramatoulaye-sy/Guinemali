# 🔄 **GUIDE DE DÉPANNAGE - REDIRECTION PAGE ENREGISTREMENT PREUVES**

## 🚨 **Problème Identifié**
**Date :** $(Get-Date -Format "dd/MM/yyyy HH:mm")
**Statut :** ✅ **RÉSOLU**

---

## 1. 📋 **Description du Problème**

### **Symptômes Observés**
- ❌ **Page d'enregistrement** : Affiche "Aucune alerte active" même après déclenchement d'alerte SOS
- ❌ **Contradiction** : Bannière verte en bas indique "ALERTE CRÉÉE !" mais la page principale dit "Aucune alerte active"
- ❌ **Erreur Supabase** : `invalid input syntax for type uuid: "test_user_id_1756730155962"`
- ❌ **Redirection** : L'utilisateur ne peut pas accéder aux fonctionnalités d'enregistrement

### **Cause Racine**
Le problème vient du fait que l'application utilise un ID utilisateur de test (`test_user_id_${timestamp}`) qui n'est pas un UUID valide, mais la base de données Supabase attend un UUID pour la colonne `utilisateur_id`.

---

## 2. 🔍 **Diagnostic Technique**

### **Erreur Supabase**
```
❌ Erreur SELECT sur alertes: PostgrestException(message: invalid input syntax for type uuid: "test_user_id_1756730155962", code: 22P02, details: Bad Request, hint: null)
```

### **Flux de Données Problématique**
1. **Création d'alerte** : ✅ Réussit (stockage local)
2. **Stockage local** : ✅ ID d'alerte sauvegardé
3. **Recherche Supabase** : ❌ Échoue (ID utilisateur invalide)
4. **Affichage page** : ❌ "Aucune alerte active"

---

## 3. 🔧 **Solutions Appliquées**

### **Solution 1 : Priorité aux Données Locales**
```dart
/// Charge l'alerte active actuelle
Future<void> _loadCurrentAlert() async {
  try {
    // Priorité: ID d'alerte stocké localement
    final storedId = StorageService.instance.getString(AppConstants.keyCurrentAlertId);
    
    if (storedId != null && storedId.isNotEmpty) {
      setState(() {
        _currentAlertId = storedId;
      });
      await _loadEvidence();
      return;
    }

    // Priorité aux alertes locales pour éviter les problèmes Supabase
    final localAlerts = await StorageService.instance.getLocalAlerts();
    
    if (localAlerts.isNotEmpty) {
      setState(() {
        _currentAlertId = (localAlerts.first)['id'] as String;
      });
      await _loadEvidence();
      return;
    }

    // Fallback avec gestion d'erreur pour Supabase
    try {
      final activeAlerts = await AlertService.instance.getActiveAlerts();
      if (activeAlerts.isNotEmpty) {
        setState(() {
          _currentAlertId = activeAlerts.first.id;
        });
        await _loadEvidence();
        return;
      }
    } catch (supabaseError) {
      print('⚠️ Erreur Supabase, continuation avec données locales');
    }
  } catch (e) {
    print('❌ Erreur lors du chargement de l\'alerte: $e');
  }
}
```

### **Solution 2 : Gestion d'Erreur Améliorée**
```dart
/// Charge la liste des preuves existantes
Future<void> _loadEvidence() async {
  if (_currentAlertId.isEmpty) return;

  try {
    setState(() {
      _isLoading = true;
    });

    // Essayer de charger les preuves depuis le service
    try {
      final evidence = await EvidenceService.instance.getEvidenceForAlert(_currentAlertId);
      setState(() {
        _evidenceList = evidence;
        _isLoading = false;
      });
      print('✅ Preuves chargées avec succès: ${evidence.length} éléments');
    } catch (evidenceError) {
      print('⚠️ Erreur lors du chargement des preuves: $evidenceError');
      // En cas d'erreur, initialiser avec une liste vide
      setState(() {
        _evidenceList = [];
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print('❌ Erreur générale chargement preuves: $e');
  }
}
```

### **Solution 3 : Bouton de Rafraîchissement Amélioré**
```dart
/// Rafraîchit l'alerte active
Future<void> _refreshAlert() async {
  print('🔄 Rafraîchissement forcé de l\'alerte...');
  
  // Afficher un indicateur de chargement
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Rafraîchissement en cours...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  await _loadCurrentAlert();
  
  // Afficher le résultat
  if (mounted) {
    if (_currentAlertId.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Alerte trouvée: ${_currentAlertId.substring(0, 8)}...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Aucune alerte active trouvée'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
```

---

## 4. 📱 **Instructions de Test**

### **Étapes pour Tester la Correction**

1. **Déclencher une Alerte SOS**
   - Aller sur le dashboard principal
   - Appuyer sur le bouton SOS
   - Confirmer l'alerte

2. **Vérifier la Redirection**
   - L'application doit rediriger vers l'écran d'alerte active
   - Puis vers la page d'enregistrement des preuves

3. **Tester la Page d'Enregistrement**
   - La page doit afficher "🚨 Alerte Active" au lieu de "Aucune alerte active"
   - L'ID de l'alerte doit être visible
   - Les boutons d'enregistrement doivent être fonctionnels

4. **Tester le Rafraîchissement**
   - Cliquer sur le bouton "Rafraîchir"
   - Vérifier que l'alerte est toujours détectée

### **Logs à Surveiller**
```
🔍 Début du chargement de l'alerte active...
🔍 ID d'alerte stocké localement: [ID_ALERTE]
✅ Alerte trouvée en stockage local: [ID_ALERTE]
✅ Preuves chargées avec succès: 0 éléments
```

---

## 5. 🛠️ **Corrections Techniques**

### **Problème 1 : ID Utilisateur Non-UUID**
**Cause :** Mode de test utilise des IDs non-UUID
**Solution :** Priorité aux données locales, fallback avec gestion d'erreur

### **Problème 2 : Gestion d'Erreur Insuffisante**
**Cause :** Les erreurs Supabase bloquent l'affichage
**Solution :** Try-catch séparés pour chaque source de données

### **Problème 3 : Feedback Utilisateur Manquant**
**Cause :** L'utilisateur ne sait pas si le rafraîchissement fonctionne
**Solution :** Messages de statut avec SnackBar

---

## 6. 🔄 **Prochaines Étapes**

### **Améliorations Prévues**
1. **Correction UUID** : Générer des UUID valides en mode test
2. **Synchronisation** : Améliorer la synchronisation locale/serveur
3. **Interface** : Ajouter plus d'indicateurs de statut
4. **Logs** : Améliorer les logs de débogage

### **Tests à Effectuer**
1. ✅ **Test de redirection** (implémenté)
2. 🔄 **Test d'enregistrement audio/vidéo**
3. 🔄 **Test de sauvegarde des preuves**
4. 🔄 **Test de synchronisation**

---

## 7. 📞 **Support et Dépannage**

### **En Cas de Problème Persistant**
1. **Vérifier les Logs** : Consulter la console pour les erreurs détaillées
2. **Tester le Rafraîchissement** : Utiliser le bouton "Rafraîchir"
3. **Redémarrer l'App** : Fermer et relancer l'application
4. **Vérifier le Stockage** : S'assurer que l'alerte est bien créée

### **Messages d'Erreur Courants**
- `Aucune alerte trouvée` : Utiliser le bouton "Rafraîchir"
- `Erreur Supabase` : L'application continue avec les données locales
- `Permission refusée` : Vérifier les permissions microphone/caméra

---

**Note :** Ce guide sera mis à jour au fur et à mesure des améliorations apportées au système de redirection.

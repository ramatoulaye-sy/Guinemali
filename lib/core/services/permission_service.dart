import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'error_service.dart';

/// Service centralisé pour la gestion des permissions de l'application
/// Basé sur 30 ans d'expérience en développement mobile
class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();
  
  PermissionService._();

  /// Demande les permissions essentielles pour l'application
  static Future<Map<Permission, PermissionStatus>> requestEssentialPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.location,
      Permission.storage,
      Permission.camera,
    ];

    final results = <Permission, PermissionStatus>{};
    
    for (final permission in permissions) {
      final status = await permission.request();
      results[permission] = status;
    }
    
    return results;
  }

  /// Vérifie et demande une permission spécifique
  static Future<PermissionStatus> requestPermission(Permission permission) async {
    final status = await permission.status;
    
    if (status.isGranted) {
      return status;
    }
    
    if (status.isDenied) {
      return await permission.request();
    }
    
    if (status.isPermanentlyDenied) {
      // Ouvrir les paramètres de l'application
      await openAppSettings();
      return await permission.status;
    }
    
    return status;
  }

  /// Vérifie si une permission est accordée
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Vérifie les permissions pour l'enregistrement audio
  static Future<bool> checkAudioPermissions() async {
    final microphoneStatus = await requestPermission(Permission.microphone);
    final storageStatus = await requestPermission(Permission.storage);
    
    return microphoneStatus.isGranted && storageStatus.isGranted;
  }

  /// Vérifie les permissions pour l'enregistrement vidéo
  static Future<bool> checkVideoPermissions() async {
    final cameraStatus = await requestPermission(Permission.camera);
    final microphoneStatus = await requestPermission(Permission.microphone);
    final storageStatus = await requestPermission(Permission.storage);
    
    return cameraStatus.isGranted && microphoneStatus.isGranted && storageStatus.isGranted;
  }

  /// Vérifie les permissions pour la localisation
  static Future<bool> checkLocationPermissions() async {
    final locationStatus = await requestPermission(Permission.location);
    return locationStatus.isGranted;
  }

  /// Vérifie les permissions pour l'accès aux fichiers
  static Future<bool> checkStoragePermissions() async {
    final storageStatus = await requestPermission(Permission.storage);
    return storageStatus.isGranted;
  }

  /// Demande toutes les permissions nécessaires pour l'application
  static Future<Map<String, bool>> requestAllPermissions(BuildContext context) async {
    final results = <String, bool>{};
    
    try {
      // Permissions audio
      results['microphone'] = await checkAudioPermissions();
      
      // Permissions vidéo
      results['camera'] = await checkVideoPermissions();
      
      // Permissions de localisation
      results['location'] = await checkLocationPermissions();
      
      // Permissions de stockage
      results['storage'] = await checkStoragePermissions();
      
      // Afficher un résumé des permissions
      _showPermissionSummary(context, results);
      
    } catch (e) {
      ErrorService.handleError(context, e, customMessage: 'Erreur lors de la vérification des permissions');
    }
    
    return results;
  }

  /// Affiche un résumé des permissions accordées/refusées
  static void _showPermissionSummary(BuildContext context, Map<String, bool> results) {
    final granted = results.entries.where((e) => e.value).length;
    final total = results.length;
    
    if (granted == total) {
      ErrorService.showSuccess(context, 'Toutes les permissions ont été accordées');
    } else {
      final deniedPermissions = results.entries
          .where((e) => !e.value)
          .map((e) => _getPermissionDisplayName(e.key))
          .join(', ');
      
      ErrorService.showWarning(
        context, 
        '$granted/$total permissions accordées. Permissions manquantes: $deniedPermissions'
      );
    }
  }

  /// Retourne le nom d'affichage d'une permission
  static String _getPermissionDisplayName(String permission) {
    switch (permission) {
      case 'microphone':
        return 'Microphone';
      case 'camera':
        return 'Caméra';
      case 'location':
        return 'Localisation';
      case 'storage':
        return 'Stockage';
      default:
        return permission;
    }
  }

  /// Vérifie si toutes les permissions essentielles sont accordées
  static Future<bool> areEssentialPermissionsGranted() async {
    final permissions = [
      Permission.microphone,
      Permission.location,
      Permission.storage,
    ];

    for (final permission in permissions) {
      if (!await isPermissionGranted(permission)) {
        return false;
      }
    }
    
    return true;
  }

  /// Ouvre les paramètres de l'application avec un message explicatif
  static Future<void> openSettingsWithExplanation(BuildContext context) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions requises'),
        content: const Text(
          'Certaines permissions sont nécessaires pour le bon fonctionnement de l\'application. '
          'Voulez-vous ouvrir les paramètres pour les configurer ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      await openAppSettings();
    }
  }

  /// Vérifie les permissions de manière silencieuse (sans demander)
  static Future<Map<String, bool>> checkPermissionsSilently() async {
    final results = <String, bool>{};
    
    results['microphone'] = await isPermissionGranted(Permission.microphone);
    results['camera'] = await isPermissionGranted(Permission.camera);
    results['location'] = await isPermissionGranted(Permission.location);
    results['storage'] = await isPermissionGranted(Permission.storage);
    
    return results;
  }

  /// Demande une permission spécifique avec gestion d'erreur
  static Future<bool> requestPermissionWithErrorHandling(
    BuildContext context, 
    Permission permission,
    String permissionName,
  ) async {
    try {
      final status = await requestPermission(permission);
      
      if (status.isGranted) {
        ErrorService.showSuccess(context, 'Permission $permissionName accordée');
        return true;
      } else if (status.isPermanentlyDenied) {
        ErrorService.showError(
          context, 
          'Permission $permissionName refusée définitivement. Veuillez l\'activer dans les paramètres.',
        );
        await openSettingsWithExplanation(context);
        return false;
      } else {
        ErrorService.showWarning(context, 'Permission $permissionName refusée');
        return false;
      }
    } catch (e) {
      ErrorService.handleError(context, e, customMessage: 'Erreur lors de la demande de permission $permissionName');
      return false;
    }
  }

  /// Vérifie les permissions critiques pour les fonctionnalités d'urgence
  static Future<bool> checkEmergencyPermissions(BuildContext context) async {
    final criticalPermissions = [
      Permission.microphone,
      Permission.location,
    ];

    bool allGranted = true;
    
    for (final permission in criticalPermissions) {
      if (!await isPermissionGranted(permission)) {
        allGranted = false;
        break;
      }
    }

    if (!allGranted) {
      ErrorService.showWarning(
        context,
        'Certaines permissions critiques sont manquantes pour les fonctionnalités d\'urgence',
      );
    }

    return allGranted;
  }
}

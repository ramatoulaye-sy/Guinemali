import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// Service de navigation centralisé pour éliminer les redondances
/// Basé sur 30 ans d'expérience en développement mobile
class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();
  
  NavigationService._();

  /// Navigue vers une route avec gestion d'erreur standardisée
  static Future<void> navigateTo(BuildContext context, String route, {
    Map<String, dynamic>? extra,
    bool replace = false,
    String? errorMessage,
  }) async {
    try {
      // Feedback haptique pour l'expérience utilisateur
      HapticFeedback.lightImpact();
      
      if (replace) {
        context.go(route, extra: extra);
      } else {
        context.push(route, extra: extra);
      }
      
      if (AppConstants.enableLogging) {
        debugPrint('✅ Navigation réussie vers: $route');
      }
    } catch (e) {
      _showErrorSnackBar(context, errorMessage ?? 'Erreur de navigation: $e');
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur navigation vers $route: $e');
      }
    }
  }

  /// Retourne à l'écran précédent
  static void goBack(BuildContext context, {String? errorMessage}) {
    try {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar(context, errorMessage ?? 'Erreur de retour: $e');
    }
  }

  /// Navigue vers le dashboard principal
  static Future<void> goToDashboard(BuildContext context, UserType userType) async {
    String route;
    switch (userType) {
      case UserType.victime:
        route = AppConstants.routeVictimDashboard;
        break;
      case UserType.aidant:
        route = AppConstants.routeHelperHome;
        break;
      case UserType.ong:
        route = AppConstants.routeONGHome;
        break;
      case UserType.admin:
        route = AppConstants.routeAdminHome;
        break;
    }
    
    await navigateTo(context, route, replace: true);
  }

  /// Navigue vers l'écran de connexion
  static Future<void> goToLogin(BuildContext context) async {
    await navigateTo(context, AppConstants.routeLogin);
  }

  /// Navigue vers l'écran d'inscription
  static Future<void> goToRegister(BuildContext context) async {
    await navigateTo(context, AppConstants.routeRegister);
  }

  /// Navigue vers l'écran d'accueil
  static Future<void> goToWelcome(BuildContext context) async {
    await navigateTo(context, AppConstants.routeWelcome, replace: true);
  }

  /// Navigue vers le profil utilisateur
  static Future<void> goToProfile(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimProfile);
  }

  /// Navigue vers les paramètres
  static Future<void> goToSettings(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimSettings);
  }

  /// Navigue vers les contacts
  static Future<void> goToContacts(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimContacts);
  }

  /// Navigue vers les preuves
  static Future<void> goToEvidence(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimEvidence);
  }

  /// Navigue vers l'enregistrement de preuves
  static Future<void> goToRecordEvidence(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimRecordEvidence);
  }

  /// Navigue vers le plan d'urgence
  static Future<void> goToEmergencyPlan(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimEmergencyPlan);
  }

  /// Navigue vers l'alerte active
  static Future<void> goToActiveAlert(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimActiveAlert);
  }

  /// Navigue vers les actions rapides
  static Future<void> goToQuickActions(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimQuickActions);
  }

  /// Navigue vers l'aide
  static Future<void> goToHelp(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimHelp);
  }

  /// Navigue vers l'historique
  static Future<void> goToHistory(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimHistory);
  }

  /// Navigue vers le forum
  static Future<void> goToForum(BuildContext context) async {
    await navigateTo(context, AppConstants.routeVictimForum);
  }

  /// Affiche un SnackBar d'erreur standardisé
  static void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppConstants.errorColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Affiche un SnackBar de succès standardisé
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppConstants.successColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Affiche un SnackBar d'information standardisé
  static void showInfoSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppConstants.primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Affiche un SnackBar d'avertissement standardisé
  static void showWarningSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppConstants.warningColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Affiche une boîte de dialogue de confirmation standardisée
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color confirmColor = AppConstants.primaryColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Affiche une boîte de dialogue d'erreur standardisée
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppConstants.errorColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

/// Enum pour les types d'utilisateur
enum UserType {
  victime,
  aidant,
  ong,
  admin,
}

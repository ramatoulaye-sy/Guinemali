import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// Service centralisé pour la gestion des erreurs et des messages utilisateur
/// Basé sur 30 ans d'expérience en développement mobile
class ErrorService {
  static ErrorService? _instance;
  static ErrorService get instance => _instance ??= ErrorService._();
  
  ErrorService._();

  /// Affiche un message de succès standardisé
  static void showSuccess(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $message'),
          backgroundColor: AppConstants.successColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Affiche un message d'erreur standardisé
  static void showError(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 5),
    bool hapticFeedback = true,
  }) {
    if (context.mounted) {
      if (hapticFeedback) {
        HapticFeedback.mediumImpact();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: AppConstants.errorColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Fermer',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Affiche un message d'avertissement standardisé
  static void showWarning(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $message'),
          backgroundColor: AppConstants.warningColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Affiche un message d'information standardisé
  static void showInfo(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ℹ️ $message'),
          backgroundColor: AppConstants.primaryColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Affiche un message de chargement
  static void showLoading(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppConstants.primaryColor,
          duration: const Duration(seconds: 30), // Longue durée pour le chargement
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Cache le message de chargement actuel
  static void hideLoading(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  /// Gère les erreurs de manière centralisée
  static void handleError(BuildContext context, dynamic error, {
    String? customMessage,
    bool showToUser = true,
  }) {
    String message = customMessage ?? _extractErrorMessage(error);
    
    if (showToUser && context.mounted) {
      showError(context, message);
    }
  }

  /// Extrait le message d'erreur d'une exception
  static String _extractErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    } else if (error is Exception) {
      String errorStr = error.toString();
      // Enlever "Exception: " du début si présent
      if (errorStr.startsWith('Exception: ')) {
        return errorStr.substring(11);
      }
      return errorStr;
    } else {
      return error?.toString() ?? 'Erreur inconnue';
    }
  }

  /// Valide une réponse d'API et gère les erreurs
  static bool validateApiResponse(BuildContext context, Map<String, dynamic> response, {
    String? successMessage,
    String? errorMessage,
  }) {
    if (response['status'] == 'success') {
      if (successMessage != null) {
        showSuccess(context, successMessage);
      }
      return true;
    } else {
      String message = errorMessage ?? response['message'] ?? 'Erreur de l\'API';
      showError(context, message);
      return false;
    }
  }
}

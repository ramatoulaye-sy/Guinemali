import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Service centralisé pour la gestion des configurations et constantes
/// Basé sur 30 ans d'expérience en développement mobile
class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance => _instance ??= ConfigService._();
  
  ConfigService._();

  // Configuration de l'application
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String environment = 'production'; // 'development', 'staging', 'production'
  
  // Configuration des timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration recordingTimeout = Duration(minutes: 5);
  
  // Configuration des enregistrements
  static const int maxRecordingDuration = 300; // 5 minutes en secondes
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
  static const List<String> allowedAudioFormats = ['m4a', 'wav', 'mp3'];
  static const List<String> allowedVideoFormats = ['mp4', 'mov', 'avi'];
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'heic'];
  
  // Configuration de la sécurité
  static const int maxLoginAttempts = 3;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const int pinMinLength = 4;
  static const int pinMaxLength = 8;
  
  // Configuration des alertes
  static const Duration alertConfirmationTimeout = Duration(seconds: 15);
  static const Duration alertCancellationTimeout = Duration(seconds: 10);
  static const int maxActiveAlerts = 1;
  static const int alertHistoryLimit = 100;
  
  // Configuration de la géolocalisation
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const double locationAccuracy = 10.0; // mètres
  static const Duration locationTimeout = Duration(seconds: 10);
  
  // Configuration du cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB
  
  // Configuration des notifications
  static const Duration notificationTimeout = Duration(seconds: 5);
  static const int maxNotificationRetries = 3;
  
  /// Retourne la configuration selon l'environnement
  static Map<String, dynamic> getEnvironmentConfig() {
    switch (environment) {
      case 'development':
        return {
          'apiUrl': 'http://localhost:3000',
          'debugMode': true,
          'logLevel': 'debug',
          'enableAnalytics': false,
        };
      case 'staging':
        return {
          'apiUrl': 'https://staging-api.guinemali.com',
          'debugMode': true,
          'logLevel': 'info',
          'enableAnalytics': true,
        };
      case 'production':
        return {
          'apiUrl': 'https://api.guinemali.com',
          'debugMode': false,
          'logLevel': 'error',
          'enableAnalytics': true,
        };
      default:
        return {
          'apiUrl': 'https://api.guinemali.com',
          'debugMode': false,
          'logLevel': 'error',
          'enableAnalytics': true,
        };
    }
  }

  /// Retourne la configuration des couleurs selon le thème
  static Map<String, Color> getThemeColors(bool isDarkMode) {
    if (isDarkMode) {
      return {
        'primary': AppConstants.primaryColor,
        'secondary': AppConstants.secondaryColor,
        'background': const Color(0xFF121212),
        'surface': const Color(0xFF1E1E1E),
        'text': Colors.white,
        'textSecondary': Colors.grey[300]!,
        'error': AppConstants.errorColor,
        'success': AppConstants.successColor,
        'warning': AppConstants.warningColor,
      };
    } else {
      return {
        'primary': AppConstants.primaryColor,
        'secondary': AppConstants.secondaryColor,
        'background': AppConstants.backgroundColor,
        'surface': AppConstants.whiteColor,
        'text': AppConstants.blackColor,
        'textSecondary': Colors.grey[600]!,
        'error': AppConstants.errorColor,
        'success': AppConstants.successColor,
        'warning': AppConstants.warningColor,
      };
    }
  }

  /// Retourne la configuration des animations
  static Map<String, Duration> getAnimationConfig() {
    return {
      'fast': AppConstants.animationDurationFast,
      'medium': AppConstants.animationDurationMedium,
      'slow': AppConstants.animationDurationSlow,
      'bounce': const Duration(milliseconds: 600),
      'elastic': const Duration(milliseconds: 800),
    };
  }

  /// Retourne la configuration des espacements
  static Map<String, double> getSpacingConfig() {
    return {
      'xs': AppConstants.paddingSmall / 2,
      'sm': AppConstants.paddingSmall,
      'md': AppConstants.paddingMedium,
      'lg': AppConstants.paddingLarge,
      'xl': AppConstants.paddingLarge * 1.5,
      'xxl': AppConstants.paddingLarge * 2,
    };
  }

  /// Retourne la configuration des rayons de bordure
  static Map<String, double> getBorderRadiusConfig() {
    return {
      'xs': AppConstants.borderRadiusSmall,
      'sm': AppConstants.borderRadiusMedium,
      'md': AppConstants.borderRadiusLarge,
      'lg': AppConstants.borderRadiusLarge * 1.5,
      'xl': AppConstants.borderRadiusLarge * 2,
      'full': 999,
    };
  }

  /// Retourne la configuration des tailles d'icônes
  static Map<String, double> getIconSizeConfig() {
    return {
      'xs': AppConstants.iconSizeSmall,
      'sm': AppConstants.iconSizeMedium,
      'md': AppConstants.iconSizeLarge,
      'lg': AppConstants.iconSizeLarge * 1.5,
      'xl': AppConstants.iconSizeLarge * 2,
    };
  }

  /// Retourne la configuration des tailles de police
  static Map<String, double> getFontSizeConfig() {
    return {
      'xs': 10,
      'sm': 12,
      'md': 14,
      'lg': 16,
      'xl': 18,
      'xxl': 20,
      'title': 24,
      'headline': 28,
    };
  }

  /// Retourne la configuration des limites de l'application
  static Map<String, int> getLimitsConfig() {
    return {
      'maxContacts': 10,
      'maxEmergencyContacts': 5,
      'maxAlertsPerDay': 10,
      'maxEvidencePerAlert': 10,
      'maxFileSize': maxFileSize,
      'maxRecordingDuration': maxRecordingDuration,
      'maxLoginAttempts': maxLoginAttempts,
      'alertHistoryLimit': alertHistoryLimit,
    };
  }

  /// Retourne la configuration des formats de fichier supportés
  static Map<String, List<String>> getFileFormatsConfig() {
    return {
      'audio': allowedAudioFormats,
      'video': allowedVideoFormats,
      'image': allowedImageFormats,
      'document': ['pdf', 'doc', 'docx', 'txt'],
    };
  }

  /// Retourne la configuration des timeouts
  static Map<String, Duration> getTimeoutConfig() {
    return {
      'api': apiTimeout,
      'connection': connectionTimeout,
      'recording': recordingTimeout,
      'alertConfirmation': alertConfirmationTimeout,
      'alertCancellation': alertCancellationTimeout,
      'location': locationTimeout,
      'notification': notificationTimeout,
    };
  }

  /// Vérifie si une fonctionnalité est activée
  static bool isFeatureEnabled(String feature) {
    final enabledFeatures = [
      'audio_recording',
      'video_recording',
      'location_tracking',
      'emergency_alerts',
      'contact_management',
      'evidence_storage',
      'push_notifications',
      'analytics',
    ];
    
    return enabledFeatures.contains(feature);
  }

  /// Retourne la configuration de sécurité
  static Map<String, dynamic> getSecurityConfig() {
    return {
      'pinMinLength': pinMinLength,
      'pinMaxLength': pinMaxLength,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDuration': lockoutDuration,
      'sessionTimeout': const Duration(hours: 24),
      'requireBiometric': false,
      'encryptLocalData': true,
      'secureStorage': true,
    };
  }

  /// Retourne la configuration de performance
  static Map<String, dynamic> getPerformanceConfig() {
    return {
      'enableCaching': true,
      'cacheExpiration': cacheExpiration,
      'maxCacheSize': maxCacheSize,
      'imageCompression': true,
      'audioCompression': true,
      'videoCompression': true,
      'lazyLoading': true,
      'preloadData': true,
    };
  }

  /// Retourne la configuration de débogage
  static Map<String, dynamic> getDebugConfig() {
    final envConfig = getEnvironmentConfig();
    return {
      'debugMode': envConfig['debugMode'],
      'logLevel': envConfig['logLevel'],
      'enableCrashReporting': true,
      'enablePerformanceMonitoring': true,
      'enableNetworkLogging': envConfig['debugMode'],
      'enableDatabaseLogging': envConfig['debugMode'],
    };
  }

  /// Retourne la configuration des régions supportées
  static List<String> getSupportedRegions() {
    return AppConstants.guineanRegions;
  }

  /// Retourne la configuration des langues supportées
  static Map<String, String> getSupportedLanguages() {
    return {
      'fr': 'Français',
      'en': 'English',
      'ff': 'Fulani',
    };
  }

  /// Retourne la configuration des types d'utilisateur
  static Map<String, String> getUserTypes() {
    return {
      'victime': 'Personne à protéger',
      'aidant': 'Aidant',
      'ong': 'Organisation',
      'admin': 'Administrateur',
    };
  }

  /// Vérifie si l'application est en mode développement
  static bool isDevelopmentMode() {
    return environment == 'development';
  }

  /// Vérifie si l'application est en mode production
  static bool isProductionMode() {
    return environment == 'production';
  }

  /// Retourne la version complète de l'application
  static String getFullVersion() {
    return '$appVersion+$buildNumber';
  }

  /// Retourne la configuration des métadonnées de l'application
  static Map<String, String> getAppMetadata() {
    return {
      'name': AppConstants.appName,
      'version': appVersion,
      'buildNumber': buildNumber,
      'environment': environment,
      'fullVersion': getFullVersion(),
      'slogan': AppConstants.appSlogan,
      'description': 'Application de sécurité pour les personnes vulnérables',
    };
  }
}

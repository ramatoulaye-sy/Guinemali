import 'package:flutter/material.dart';

/// Constantes principales de l'application
class AppConstants {
  // Informations de l'application
  static const String appName = 'Guinemali';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appSlogan = 'Votre sécurité est notre priorité';
  static const String logoPath = 'assets/images/logo.png';
  static const String defaultLanguage = 'fr';
  
  // Mode debug et logging
  static const bool enableDebugMode = true;
  static const bool enableLogging = true;
  
  // Routes de navigation
  static const String routeWelcome = '/welcome';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeVictimHome = '/victim/home';
  static const String routeVictimDashboard = '/victim/dashboard'; // Nouvelle route dashboard
  static const String routeVictimActiveAlert = '/victim/active-alert';
  static const String routeVictimContacts = '/victim/contacts';
  static const String routeHelperHome = '/helper/home';
  static const String routeONGHome = '/ong/home';
  static const String routeAdminHome = '/admin/home';
  
  // Clés de stockage
  static const String keyCurrentAlertId = 'current_alert_id';
  static const String keyUserToken = 'user_token';
  static const String keyUserProfile = 'user_profile';
  static const String keyAppSettings = 'app_settings';
  static const String keyUserId = 'user_id';
  static const String keyUserPrenom = 'user_prenom';
  static const String keyUserType = 'user_type';
  static const String keyIsLoggedIn = 'is_logged_in';
  
  // Configuration Supabase
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // Couleurs principales
  static const Color primaryColor = Color(0xFF945acb);
  static const Color secondaryColor = Color(0xFFee82ee);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color whiteColor = Colors.white;
  static const Color blackColor = Colors.black;
  static const Color errorColor = Color(0xFFDC3545);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color successColor = Color(0xFF28A745);
  static const Color infoColor = Color(0xFF17A2B8);
  static const Color alertActiveColor = Color(0xFFFF0000);
  
  // Espacement
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 32.0;
  
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;
  
  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusExtraLarge = 24.0;
  
  // Tailles de police
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeExtraLarge = 18.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeHeadline = 32.0;
  
  // Tailles d'icônes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;
  
  // Tailles de boutons
  static const double sosButtonMaxSize = 420.0;
  static const double sosButtonMinSize = 240.0;
  
  // Durées d'animation
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationNormal = Duration(milliseconds: 300);
  static const Duration animationDurationMedium = Duration(milliseconds: 400);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  
  // Timeouts
  static const Duration timeoutShort = Duration(seconds: 10);
  static const Duration timeoutMedium = Duration(seconds: 30);
  static const Duration timeoutLong = Duration(seconds: 60);
  
  // Limites
  static const int maxRetryAttempts = 3;
  static const int maxFileSizeMB = 10;
  static const int maxImageDimension = 1024;
  static const int pinMinLength = 4;
  static const int pinMaxLength = 6;
  static const int maxEmergencyContacts = 3;
  static const int cacheExpirationHours = 24;
  
  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Patterns de validation
  static const String prenomPattern = r'^[a-zA-ZÀ-ÿ\s]{2,50}$';
  static const String pinPattern = r'^[0-9]{4,6}$';
  static const String phoneNumberPattern = r'^[0-9+\-\s\(\)]{8,15}$';
  
  // Messages d'erreur
  static const String errorGeneric = 'Une erreur est survenue';
  static const String errorNetwork = 'Erreur de connexion réseau';
  static const String errorPermission = 'Permission refusée';
  static const String errorTimeout = 'Délai d\'attente dépassé';
  
  // Messages de succès
  static const String successSaved = 'Données sauvegardées';
  static const String successDeleted = 'Élément supprimé';
  static const String successUpdated = 'Mise à jour réussie';
  
  // Messages d'information
  static const String infoLoading = 'Chargement en cours...';
  static const String infoNoData = 'Aucune donnée disponible';
  static const String infoEmpty = 'Liste vide';
  
  // Régions de Guinée
  static const List<String> guineanRegions = [
    'Boké',
    'Conakry',
    'Dabola',
    'Dalaba',
    'Dinguiraye',
    'Dubreka',
    'Faranah',
    'Forecariah',
    'Fria',
    'Gaoual',
    'Gueckedou',
    'Kankan',
    'Kerouane',
    'Kindia',
    'Kissidougou',
    'Koubia',
    'Koundara',
    'Kouroussa',
    'Labe',
    'Lelouma',
    'Lola',
    'Macenta',
    'Mali',
    'Mamou',
    'Mandiana',
    'Nzerekore',
    'Pita',
    'Siguiri',
    'Telimele',
    'Tougue',
    'Yomou'
  ];
}

/// Constantes pour le padding responsive
class ResponsivePadding {
  static const EdgeInsets mobile = EdgeInsets.all(16.0);
  static const EdgeInsets tablet = EdgeInsets.all(24.0);
  static const EdgeInsets desktop = EdgeInsets.all(32.0);
  static const EdgeInsets extraLarge = EdgeInsets.all(48.0);
}

/// Constantes pour les couleurs
class AppColors {
  static const Color primaryColor = Color(0xFF945acb);
  static const Color secondaryColor = Color(0xFFee82ee);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color whiteColor = Colors.white;
  static const Color errorColor = Color(0xFFDC3545);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color successColor = Color(0xFF28A745);
  static const Color infoColor = Color(0xFF17A2B8);
  static const Color alertActiveColor = Color(0xFFFF0000);
}

/// Constantes pour les breakpoints responsive
class ResponsiveBreakpoints {
  static const double mobile = 600.0;
  static const double tablet = 900.0;
  static const double desktop = 1200.0;
  static const double watch = 300.0;
}

/// Constantes pour les animations
class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// Constantes pour les thèmes
class ThemeConstants {
  static const double cardElevation = 2.0;
  static const double buttonElevation = 1.0;
  static const double appBarElevation = 4.0;
  static const double borderRadius = 8.0;
  static const double iconSize = 24.0;
  static const double buttonHeight = 48.0;
}

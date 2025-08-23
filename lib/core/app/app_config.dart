import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Configuration centralisée de l'application Guinèmali
class AppConfig {
  // Configuration des orientations d'écran
  static const List<DeviceOrientation> supportedOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  // Configuration des styles système
  static const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  // Configuration des couleurs système
  static const SystemUiOverlayStyle lightSystemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle darkSystemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  /// Applique la configuration système
  static void configureSystemUI() {
    SystemChrome.setPreferredOrientations(supportedOrientations);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  /// Obtient le thème approprié selon le mode
  static ThemeData getTheme({bool isDarkMode = false}) {
    return isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  /// Configuration des localisations
  static List<Locale> getSupportedLocales() {
    return const [
      Locale('fr', 'GN'), // Français - Guinée
      Locale('en', 'GN'), // Anglais - Guinée
      Locale('ff', 'GN'), // Fulani - Guinée
    ];
  }

  /// Configuration des delegates de localisation
  static List<LocalizationsDelegate<dynamic>> getLocalizationDelegates() {
    return AppLocalizations.localizationsDelegates;
  }

  /// Configuration des routes initiales
  static const String initialRoute = '/welcome';

  /// Configuration des routes d'erreur
  static const String errorRoute = '/error';

  /// Configuration des routes protégées (nécessitent une authentification)
  static const List<String> protectedRoutes = [
    '/victim/home',
    '/victim/active-alert',
    '/victim/evidence',
    '/victim/contacts',
    '/victim/profile',
    '/victim/settings',
    '/victim/history',
    '/victim/emergency-plan',
    '/victim/help',
    '/helper/home',
    '/ong/home',
    '/admin/home',
  ];

  /// Configuration des routes publiques (accessibles sans authentification)
  static const List<String> publicRoutes = [
    '/welcome',
    '/login',
    '/register',
    '/error',
  ];

  /// Vérifie si une route est protégée
  static bool isProtectedRoute(String route) {
    return protectedRoutes.any((protectedRoute) => route.startsWith(protectedRoute));
  }

  /// Vérifie si une route est publique
  static bool isPublicRoute(String route) {
    return publicRoutes.any((publicRoute) => route.startsWith(publicRoute));
  }
}

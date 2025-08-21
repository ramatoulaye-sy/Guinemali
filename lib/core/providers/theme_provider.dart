import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Enum pour les modes de thème
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Provider pour la gestion des thèmes
class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;
  static ThemeProvider get instance => _instance;
  ThemeProvider._internal();

  AppThemeMode _currentMode = AppThemeMode.system;
  bool _isDarkMode = false;

  AppThemeMode get currentMode => _currentMode;
  bool get isDarkMode => _isDarkMode;

  /// Initialiser le provider
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('theme_mode') ?? 'system';
      
      switch (savedMode) {
        case 'light':
          _currentMode = AppThemeMode.light;
          _isDarkMode = false;
          break;
        case 'dark':
          _currentMode = AppThemeMode.dark;
          _isDarkMode = true;
          break;
        default:
          _currentMode = AppThemeMode.system;
          _isDarkMode = _getSystemTheme();
          break;
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du thème: $e');
    }
  }

  /// Changer le mode de thème
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_currentMode == mode) return;

    _currentMode = mode;
    
    switch (mode) {
      case AppThemeMode.light:
        _isDarkMode = false;
        break;
      case AppThemeMode.dark:
        _isDarkMode = true;
        break;
      case AppThemeMode.system:
        _isDarkMode = _getSystemTheme();
        break;
    }

    // Sauvegarder la préférence
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode.name);
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde du thème: $e');
    }

    notifyListeners();
  }

  /// Basculer entre mode clair et sombre
  Future<void> toggleTheme() async {
    if (_currentMode == AppThemeMode.system) {
      await setThemeMode(_isDarkMode ? AppThemeMode.light : AppThemeMode.dark);
    } else {
      await setThemeMode(_isDarkMode ? AppThemeMode.light : AppThemeMode.dark);
    }
  }

  /// Obtenir le thème système
  bool _getSystemTheme() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  /// Obtenir le thème actuel
  ThemeData get currentTheme {
    switch (_currentMode) {
      case AppThemeMode.light:
        return _lightTheme;
      case AppThemeMode.dark:
        return _darkTheme;
      case AppThemeMode.system:
        return _isDarkMode ? _darkTheme : _lightTheme;
    }
  }

  /// Thème clair
  ThemeData get _lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.whiteColor,
        elevation: 4,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.whiteColor,
          elevation: 1,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  /// Thème sombre
  ThemeData get _darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: AppConstants.whiteColor,
        elevation: 4,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.whiteColor,
          elevation: 1,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.grey[800],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Thèmes de l'application
class AppTheme {
  // Couleurs principales
  static const Color primaryColor = AppConstants.primaryColor;
  static const Color secondaryColor = AppConstants.secondaryColor;
  static const Color accentColor = AppConstants.accentColor;
  static const Color backgroundColor = AppConstants.backgroundColor;
  static const Color whiteColor = AppConstants.whiteColor;
  static const Color blackColor = AppConstants.blackColor;
  static const Color errorColor = AppConstants.errorColor;
  static const Color warningColor = AppConstants.warningColor;
  static const Color successColor = AppConstants.successColor;
  static const Color infoColor = AppConstants.infoColor;
  static const Color emergencyColor = AppConstants.alertActiveColor;
  static const Color surfaceColor = AppConstants.backgroundColor;
  static const Color textPrimaryColor = AppConstants.blackColor;
  static const Color textSecondaryColor = AppConstants.blackColor;
  static const Color borderColor = AppConstants.primaryColor;

  /// Dégradé de fond par défaut
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8F9FA),
      Color(0xFFE9ECEF),
    ],
  );

  /// Thème clair
  static ThemeData get lightTheme {
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
        elevation: AppTheme.appBarElevation,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.whiteColor,
          elevation: AppTheme.buttonElevation,
          minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: const BorderSide(color: AppConstants.primaryColor),
          minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: AppTheme.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
    );
  }

  /// Thème sombre
  static ThemeData get darkTheme {
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
        elevation: AppTheme.appBarElevation,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.whiteColor,
          elevation: AppTheme.buttonElevation,
          minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: const BorderSide(color: AppConstants.primaryColor),
          minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: AppTheme.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        color: Colors.grey[800],
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
    );
  }

  // Constantes de thème
  static const double cardElevation = 2.0;
  static const double buttonElevation = 1.0;
  static const double appBarElevation = 4.0;
  static const double borderRadius = 8.0;
  static const double buttonHeight = 48.0;
}

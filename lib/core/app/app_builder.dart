import 'package:flutter/material.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';
import '../services/geolocation_service.dart';
import '../services/alert_service.dart';
import '../services/evidence_service.dart';
import '../services/audio_recording_service.dart';
import '../services/sync_service.dart';
import '../services/emergency_contact_service.dart';
import '../services/fcm_service.dart';
// removed duplicate StorageService import (already imported at top)
import 'app_config.dart';
import '../constants/app_constants.dart';
import 'app_router.dart';

/// Constructeur principal de l'application Guinèmali
class AppBuilder {
  /// Construit l'application avec tous les providers nécessaires
  static Widget buildApp() {
    return MultiProvider(
      providers: [
        // Provider d'authentification
        ChangeNotifierProvider(
          create: (context) => AuthProvider()..initialize(),
        ),
        
        // Provider de localisation
        ChangeNotifierProvider(
          create: (context) => LocaleProvider()..initialize(),
        ),
        
        // Provider de thème
        ChangeNotifierProvider(
          create: (context) => ThemeProvider()..initialize(),
        ),
        
        // Services (singletons)
        Provider<SupabaseService>(
          create: (context) => SupabaseService.instance,
        ),
        Provider<GeolocationService>(
          create: (context) => GeolocationService.instance,
        ),
        Provider<AlertService>(
          create: (context) => AlertService.instance,
        ),
        Provider<EvidenceService>(
          create: (context) => EvidenceService.instance,
        ),
        Provider<AudioRecordingService>(
          create: (context) => AudioRecordingService.instance,
        ),
        Provider<SyncService>(
          create: (context) => SyncService.instance,
        ),
        Provider<EmergencyContactService>(
          create: (context) => EmergencyContactService.instance,
        ),
        Provider<StorageService>(
          create: (context) => StorageService.instance,
        ),
      ],
      
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return MaterialApp(
              title: 'Guinèmali',
              debugShowCheckedModeBanner: false,
              theme: AppConfig.getTheme(isDarkMode: false),
              darkTheme: AppConfig.getTheme(isDarkMode: true),
              supportedLocales: AppConfig.getSupportedLocales(),
              localizationsDelegates: AppConfig.getLocalizationDelegates(),
              home: const _StartupSplash(),
              builder: (context, child) {
                AppConfig.configureSystemUI();
                return ValueListenableBuilder<int>(
                  valueListenable: StorageService.instance.uiSettingsVersion,
                  builder: (context, _, __) {
                    // Accessibility overrides
                    final reduceMotion = StorageService.instance.getBool('a11y_reduce_motion', defaultValue: false);
                    final readableFont = StorageService.instance.getBool('a11y_readable_font', defaultValue: false);
                    final highContrast = StorageService.instance.getBool('a11y_high_contrast', defaultValue: false);

                    final base = child ?? const SizedBox.shrink();
                    final mq = MediaQuery.of(context);
                    // Map stored text size to a global text scale
                    final sizeCode = StorageService.instance.getString('text_size') ?? 'normal';
                    final langCode = StorageService.instance.getString('selected_language');
                    final locale = (langCode == null || langCode == 'system') ? null : Locale(langCode);
                    final scale = () {
                      switch (sizeCode) {
                        case 'small':
                          return 0.9;
                        case 'large':
                          return 1.15;
                        case 'xlarge':
                          return 1.3;
                        case 'normal':
                        default:
                          return 1.0;
                      }
                    }();

                    final media = mq.copyWith(
                      highContrast: highContrast || mq.highContrast,
                      boldText: readableFont || mq.boldText,
                      textScaler: TextScaler.linear(scale),
                    );
                    final baseTheme = Theme.of(context);
                    ThemeData theme = baseTheme.copyWith(
                      pageTransitionsTheme: reduceMotion
                          ? const PageTransitionsTheme(builders: {
                              TargetPlatform.android: NoTransitionsBuilder(),
                              TargetPlatform.iOS: NoTransitionsBuilder(),
                              TargetPlatform.linux: NoTransitionsBuilder(),
                              TargetPlatform.macOS: NoTransitionsBuilder(),
                              TargetPlatform.windows: NoTransitionsBuilder(),
                            })
                          : baseTheme.pageTransitionsTheme,
                      textTheme: readableFont
                          ? baseTheme.textTheme.apply(
                                bodyColor: baseTheme.textTheme.bodyMedium?.color,
                                displayColor: baseTheme.textTheme.bodyMedium?.color,
                              ).copyWith(
                                bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
                                  letterSpacing: 0.3,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                                bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
                                  letterSpacing: 0.3,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                                labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
                                  letterSpacing: 0.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                          : baseTheme.textTheme,
                    );
                    if (highContrast) {
                      theme = theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          primary: AppConstants.primaryColor,
                          onPrimary: Colors.white,
                          secondary: AppConstants.secondaryColor,
                          onSecondary: Colors.white,
                          surface: const Color(0xFF121212),
                          onSurface: const Color(0xFFEAEAEA),
                          background: const Color(0xFF121212),
                          onBackground: const Color(0xFFEAEAEA),
                        ),
                        scaffoldBackgroundColor: const Color(0xFF121212),
                        cardColor: const Color(0xFF1E1E1E),
                        dialogBackgroundColor: const Color(0xFF1E1E1E),
                        bottomSheetTheme: theme.bottomSheetTheme.copyWith(
                          backgroundColor: const Color(0xFF1E1E1E),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                        ),
                        appBarTheme: theme.appBarTheme.copyWith(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        listTileTheme: theme.listTileTheme.copyWith(
                          iconColor: AppConstants.primaryColor,
                          textColor: const Color(0xFFEAEAEA),
                        ),
                        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                          filled: true,
                          fillColor: Colors.white,
                          hintStyle: const TextStyle(color: Colors.black54),
                        ),
                        iconTheme: theme.iconTheme.copyWith(color: AppConstants.primaryColor),
                        snackBarTheme: theme.snackBarTheme.copyWith(
                          backgroundColor: AppConstants.primaryColor,
                          contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            );
          }
                    Widget tree = MediaQuery(data: media, child: Theme(data: theme, child: base));
                    if (locale != null) {
                      tree = Localizations.override(context: context, locale: locale, child: tree);
                    }
                    return tree;
                  },
                );
              },
            );
          }
          return MaterialApp.router(
            title: 'Guinèmali',
            debugShowCheckedModeBanner: false,
            
            // Configuration du thème
            theme: AppConfig.getTheme(isDarkMode: false),
            darkTheme: AppConfig.getTheme(isDarkMode: true),
            
            // Configuration des localisations
            supportedLocales: AppConfig.getSupportedLocales(),
            localizationsDelegates: AppConfig.getLocalizationDelegates(),
            
            // Configuration du routeur (dépend de l'état d'authentification)
            routerConfig: AppRouter.createRouter(authProvider),
            
            // Configuration de l'interface système
            builder: (context, child) {
              // Appliquer la configuration système
              AppConfig.configureSystemUI();
              return ValueListenableBuilder<int>(
                valueListenable: StorageService.instance.uiSettingsVersion,
                builder: (context, _, __) {
                  // Accessibility overrides
                  final reduceMotion = StorageService.instance.getBool('a11y_reduce_motion', defaultValue: false);
                  final readableFont = StorageService.instance.getBool('a11y_readable_font', defaultValue: false);
                  final highContrast = StorageService.instance.getBool('a11y_high_contrast', defaultValue: false);

                  final base = child ?? const SizedBox.shrink();
                  final mq = MediaQuery.of(context);
                  // Map stored text size to a global text scale
                  final sizeCode = StorageService.instance.getString('text_size') ?? 'normal';
                  final langCode = StorageService.instance.getString('selected_language');
                  final locale = (langCode == null || langCode == 'system') ? null : Locale(langCode);
                  final scale = () {
                    switch (sizeCode) {
                      case 'small':
                        return 0.9;
                      case 'large':
                        return 1.15;
                      case 'xlarge':
                        return 1.3;
                      case 'normal':
                      default:
                        return 1.0;
                    }
                  }();

                  final media = mq.copyWith(
                    highContrast: highContrast || mq.highContrast,
                    boldText: readableFont || mq.boldText,
                    textScaler: TextScaler.linear(scale),
                  );
                  final baseTheme = Theme.of(context);
                  ThemeData theme = baseTheme.copyWith(
                    pageTransitionsTheme: reduceMotion
                        ? const PageTransitionsTheme(builders: {
                            TargetPlatform.android: NoTransitionsBuilder(),
                            TargetPlatform.iOS: NoTransitionsBuilder(),
                            TargetPlatform.linux: NoTransitionsBuilder(),
                            TargetPlatform.macOS: NoTransitionsBuilder(),
                            TargetPlatform.windows: NoTransitionsBuilder(),
                          })
                        : baseTheme.pageTransitionsTheme,
                    textTheme: readableFont
                        ? baseTheme.textTheme.apply(
                              bodyColor: baseTheme.textTheme.bodyMedium?.color,
                              displayColor: baseTheme.textTheme.bodyMedium?.color,
                            ).copyWith(
                              bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
                                letterSpacing: 0.3,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                              bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
                                letterSpacing: 0.3,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                              labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                        : baseTheme.textTheme,
                  );
                  if (highContrast) {
                    theme = theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        primary: AppConstants.primaryColor,
                        onPrimary: Colors.white,
                        secondary: AppConstants.secondaryColor,
                        onSecondary: Colors.white,
                        surface: const Color(0xFF121212),
                        onSurface: const Color(0xFFEAEAEA),
                        background: const Color(0xFF121212),
                        onBackground: const Color(0xFFEAEAEA),
                      ),
                      scaffoldBackgroundColor: const Color(0xFF121212),
                      cardColor: const Color(0xFF1E1E1E),
                      dialogBackgroundColor: const Color(0xFF1E1E1E),
                      bottomSheetTheme: theme.bottomSheetTheme.copyWith(
                        backgroundColor: const Color(0xFF1E1E1E),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                      ),
                      appBarTheme: theme.appBarTheme.copyWith(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      listTileTheme: theme.listTileTheme.copyWith(
                        iconColor: AppConstants.primaryColor,
                        textColor: const Color(0xFFEAEAEA),
                      ),
                      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                        filled: true,
                        fillColor: Colors.white,
                        hintStyle: const TextStyle(color: Colors.black54),
                      ),
                      iconTheme: theme.iconTheme.copyWith(color: AppConstants.primaryColor),
                      snackBarTheme: theme.snackBarTheme.copyWith(
                        backgroundColor: AppConstants.primaryColor,
                        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  Widget tree = MediaQuery(data: media, child: Theme(data: theme, child: base));
                  if (locale != null) {
                    tree = Localizations.override(context: context, locale: locale, child: tree);
                  }
                  return tree;
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Initialise tous les services de l'application
  static Future<void> initializeServices() async {
    try {
      print('🚀 Initialisation des services de l\'application...');
      
      // Initialiser Supabase en premier
      await SupabaseService.ensureInitialized();
      print('✅ Supabase initialisé');

      // Initialiser le stockage local pour la persistance de session
      await StorageService.instance.initialize();
      print('✅ StorageService initialisé');
      
      // Initialiser Firebase et FCM
      try {
        await FCMService.instance.initialize();
        print('✅ FCMService initialisé');
      } catch (e) {
        print('⚠️ FCMService non disponible: $e (l\'app continuera sans notifications push)');
      }
      
      // Les autres services sont des singletons qui s'initialisent automatiquement
      print('✅ Services initialisés automatiquement');
      
      print('🎉 Tous les services ont été initialisés avec succès !');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des services: $e');
      rethrow;
    }
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(height: 12),
            Text('Chargement...', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

/// PageTransitionsBuilder without animations (for reduce motion)
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

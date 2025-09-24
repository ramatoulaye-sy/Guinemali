import 'package:flutter/material.dart';
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
import '../services/storage_service.dart';
import 'app_config.dart';
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
                return child ?? const SizedBox.shrink();
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
              return child ?? const SizedBox.shrink();
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

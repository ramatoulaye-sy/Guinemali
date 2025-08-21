import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/audio_recording_service.dart';
import 'core/services/sync_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'shared/screens/welcome_screen.dart';
import 'shared/screens/login_screen.dart';
import 'shared/screens/register_screen.dart';
import 'victim/screens/victim_home_screen.dart';
import 'victim/screens/victim_active_alert_screen.dart';
import 'victim/screens/victim_evidence_screen.dart';
import 'victim/screens/victim_contacts_screen.dart';
import 'victim/screens/victim_profile_screen.dart';
import 'victim/screens/victim_settings_screen.dart';
import 'victim/screens/victim_history_screen.dart';
import 'victim/screens/victim_emergency_plan_screen.dart';
import 'victim/screens/victim_help_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppConstants.whiteColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  try {
    await StorageService.instance.initialize();
    await SupabaseService.initialize();
    await AuthService.instance.initialize();
    await NotificationService.instance.initialize();
    await AudioRecordingService.instance.initialize();
    await SyncService.instance.initialize();
    if (AppConstants.enableLogging) {
      print('✅ Tous les services initialisés avec succès');
    }
  } catch (e) {
    if (AppConstants.enableLogging) {
      print('❌ Erreur lors de l\'initialisation: $e');
    }
  }
  runApp(const GuinemaliApp());
}

class GuinemaliApp extends StatelessWidget {
  const GuinemaliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..initialize()),
        Provider<AudioRecordingService>(create: (_) => AudioRecordingService.instance),
        Provider<SyncService>(create: (_) => SyncService.instance),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: AppConstants.enableDebugMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: _router,
            // Localizations
            locale: localeProvider.locale ?? const Locale('fr'),
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return _buildErrorWidget(errorDetails);
              };
              return child!;
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppConstants.errorColor,
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              const Text(
                'Une erreur est survenue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              if (AppConstants.enableDebugMode)
                Text(
                  errorDetails.exception.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppConstants.paddingLarge),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Redémarrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: AppConstants.routeWelcome,
  routes: [
    GoRoute(path: AppConstants.routeWelcome, name: 'welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: AppConstants.routeLogin, name: 'login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: AppConstants.routeRegister, name: 'register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: AppConstants.routeVictimHome, name: 'victim_home', builder: (context, state) => const VictimHomeScreen()),
    GoRoute(path: AppConstants.routeVictimActiveAlert, name: 'victim_active_alert', builder: (context, state) => const VictimActiveAlertScreen()),
    GoRoute(path: '/victim/record-evidence', name: 'victim_evidence', builder: (context, state) => const VictimEvidenceScreen()),
    GoRoute(path: AppConstants.routeVictimContacts, name: 'victim_contacts', builder: (context, state) => const VictimContactsScreen()),
    GoRoute(path: '/victim/profile', name: 'victim_profile', builder: (context, state) => const VictimProfileScreen()),
    GoRoute(path: '/victim/settings', name: 'victim_settings', builder: (context, state) => const VictimSettingsScreen()),
    GoRoute(path: '/victim/history', name: 'victim_history', builder: (context, state) => const VictimHistoryScreen()),
    GoRoute(path: '/victim/emergency-plan', name: 'victim_emergency_plan', builder: (context, state) => const VictimEmergencyPlanScreen()),
    GoRoute(path: '/victim/help', name: 'victim_help', builder: (context, state) => const VictimHelpScreen()),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppConstants.errorColor),
          const SizedBox(height: AppConstants.paddingLarge),
          const Text('Page non trouvée', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppConstants.paddingMedium),
          Text('La page "${state.uri}" n\'existe pas.', textAlign: TextAlign.center),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton(onPressed: () => context.go(AppConstants.routeWelcome), child: const Text('Retour à l\'accueil')),
        ],
      ),
    ),
  ),
);



/// Écrans temporaires pour les autres types d'utilisateurs

class HelperHomeScreen extends StatelessWidget {
  const HelperHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil Aidant'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.whiteColor,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt,
              size: 100,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Interface Aidant',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ONGHomeScreen extends StatelessWidget {
  const ONGHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil ONG'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.whiteColor,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 100,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Interface ONG',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil Admin'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.whiteColor,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 100,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Interface Administrateur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

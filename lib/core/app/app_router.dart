import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../../shared/screens/welcome_screen.dart';
import '../../shared/screens/login_screen.dart';
import '../../shared/screens/register_screen.dart';
import '../../protected_person/screens/victim_home_screen.dart';
import '../../protected_person/screens/victim_dashboard_screen.dart';
import '../../protected_person/screens/victim_active_alert_screen.dart';
import '../../protected_person/screens/victim_contacts_screen.dart';
import '../../protected_person/screens/victim_quick_actions_screen.dart';
import '../../protected_person/screens/victim_evidence_screen.dart';
import '../../protected_person/screens/victim_emergency_plan_screen.dart';
import '../../protected_person/screens/victim_history_screen.dart';
import '../../protected_person/screens/victim_settings_screen.dart';
import '../../protected_person/screens/victim_help_screen.dart';
import '../../protected_person/screens/victim_profile_screen.dart';
import '../../protected_person/screens/victim_menu_screen.dart';
import '../../protected_person/screens/victim_forum_screen.dart';
import '../../protected_person/screens/victim_map_screen.dart';

/// Configuration centralisée du routeur de l'application
class AppRouter {
  static GoRouter? _router;

  /// Obtient l'instance du routeur configuré
  static GoRouter get router {
    _router ??= _createRouter();
    return _router!;
  }

  /// Crée et configure le routeur principal
  static GoRouter _createRouter() {
    return GoRouter(
      initialLocation: AppConstants.routeWelcome, // Commencer par l'écran de bienvenue
      debugLogDiagnostics: true,
      
      // Logique de redirection basée sur l'authentification
      redirect: (context, state) {
        return _handleRedirect(context, state);
      },

      // Configuration des routes
      routes: _buildRoutes(),
    );
  }

  /// Gère la logique de redirection
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    try {
      // Vérification de l'authentification
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;
      final currentRoute = state.uri.path;

      print('🔄 Redirection - Route: $currentRoute, Authentifié: $isLoggedIn');

      // Vérifier l'accès aux routes protégées
      if (_isProtectedRoute(currentRoute) && !isLoggedIn) {
        print('🚫 Accès refusé à la route protégée: $currentRoute');
        return AppConstants.routeWelcome;
      }

      // App lock: si une méthode est configurée, demander le déverrouillage au premier accès protégé
      // Remarque: garde simple, l'écran de verrouillage devrait être appelé depuis les écrans protégés

      // Si l'utilisateur est connecté et sur la page d'accueil, le rediriger vers son dashboard
      if (isLoggedIn && currentRoute == AppConstants.routeWelcome) {
        print('🚀 Utilisateur connecté, redirection vers le dashboard');
        return AppConstants.routeVictimDashboard;
      }

      return null;
    } catch (e) {
      print('❌ Erreur lors de la redirection: $e');
      // En cas d'erreur, rediriger vers la page d'accueil
      return AppConstants.routeWelcome;
    }
  }

  /// Vérifie si une route est protégée
  static bool _isProtectedRoute(String route) {
    final protectedRoutes = [
      AppConstants.routeVictimHome,
      AppConstants.routeVictimDashboard, // Utiliser la constante
      AppConstants.routeHelperHome,
      AppConstants.routeONGHome,
      AppConstants.routeAdminHome,
    ];
    return protectedRoutes.any((protectedRoute) => route.startsWith(protectedRoute));
  }

  /// Construit toutes les routes de l'application
  static List<RouteBase> _buildRoutes() {
    return [
      // Route d'accueil
      GoRoute(
        path: AppConstants.routeWelcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Routes d'authentification
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Routes des victimes
      GoRoute(
        path: AppConstants.routeVictimHome,
        name: 'victim_home',
        builder: (context, state) => const VictimHomeScreen(),
      ),
      
      // Nouvelle route dashboard des victimes
      GoRoute(
        path: AppConstants.routeVictimDashboard,
        name: 'victim_dashboard',
        builder: (context, state) => const VictimDashboardScreen(),
      ),
      
      // Route de l'écran d'alerte active
      GoRoute(
        path: AppConstants.routeVictimActiveAlert,
        name: 'victim_active_alert',
        builder: (context, state) => const VictimActiveAlertScreen(),
      ),
      
      // Route des contacts des victimes
      GoRoute(
        path: AppConstants.routeVictimContacts,
        name: 'victim_contacts',
        builder: (context, state) => const VictimContactsScreen(),
      ),
      
      // Route des actions rapides des victimes
      GoRoute(
        path: AppConstants.routeVictimQuickActions,
        name: 'victim_quick_actions',
        builder: (context, state) => const VictimQuickActionsScreen(),
      ),
      
      // Route de l'écran des preuves des victimes
      GoRoute(
        path: AppConstants.routeVictimEvidence,
        name: 'victim_evidence',
        builder: (context, state) => const VictimEvidenceScreen(),
      ),
      
      // Route de l'écran du plan d'urgence
      GoRoute(
        path: AppConstants.routeVictimEmergencyPlan,
        name: 'victim_emergency_plan',
        builder: (context, state) => const VictimEmergencyPlanScreen(),
      ),
      
      // Route de l'écran de l'historique
      GoRoute(
        path: AppConstants.routeVictimHistory,
        name: 'victim_history',
        builder: (context, state) => const VictimHistoryScreen(),
      ),
      
      // Route de l'écran des paramètres
      GoRoute(
        path: AppConstants.routeVictimSettings,
        name: 'victim_settings',
        builder: (context, state) => const VictimSettingsScreen(),
      ),
      
      // Route de l'écran d'aide
      GoRoute(
        path: AppConstants.routeVictimHelp,
        name: 'victim_help',
        builder: (context, state) => const VictimHelpScreen(),
      ),
      
      // Route de l'écran du profil
      GoRoute(
        path: AppConstants.routeVictimProfile,
        name: 'victim_profile',
        builder: (context, state) => const VictimProfileScreen(),
      ),
      
      // Route de l'écran du forum
      GoRoute(
        path: AppConstants.routeVictimForum,
        name: 'victim_forum',
        builder: (context, state) => const VictimForumScreen(),
      ),
      
      // Route de la carte GPS temps réel (OSM)
      GoRoute(
        path: '/victim/map',
        name: 'victim_map',
        builder: (context, state) => const VictimMapScreen(),
      ),
      
      // Route de l'écran d'enregistrement des preuves
      GoRoute(
        path: AppConstants.routeVictimRecordEvidence,
        name: 'victim_record_evidence',
        builder: (context, state) => const VictimEvidenceScreen(), // Redirigé vers l'écran des preuves
      ),
    ];
  }
}

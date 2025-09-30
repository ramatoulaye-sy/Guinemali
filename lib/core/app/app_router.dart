import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/security_service.dart';
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
import '../../protected_person/screens/community_forum_screen.dart';
import '../../protected_person/screens/victim_map_screen.dart';
import '../../protected_person/screens/victim_resources_screen.dart';
import '../../protected_person/screens/victim_ngo_screen.dart';
import '../../protected_person/screens/permissions_page.dart';
import '../../protected_person/screens/victim_security_screen.dart';
import '../../shared/screens/app_lock_screen.dart';
import '../test_rpc_functions.dart';

/// Configuration centralisée du routeur de l'application
class AppRouter {
  /// Fabrique un routeur en fonction de l'état d'authentification courant
  static GoRouter createRouter(AuthProvider authProvider) {
    final startLocation = authProvider.isAuthenticated
        ? AppConstants.routeVictimDashboard
        : AppConstants.routeWelcome;
    return GoRouter(
      initialLocation: startLocation,
      debugLogDiagnostics: true,
      
      // Logique de redirection basée sur l'authentification
      redirect: (context, state) => _handleRedirect(context, state),

      // Faire re-évaluer la redirection quand l'état change
      refreshListenable: authProvider,

      // Configuration des routes
      routes: _buildRoutes(),
    );
  }

  /// Gère la logique de redirection
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    try {
      // Vérification de l'authentification
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Tant que l'initialisation est en cours, ne pas rediriger pour éviter l'effet d'écran d'accueil clignotant
      if (authProvider.isLoading) {
        return null;
      }
      final isLoggedIn = authProvider.isAuthenticated;
      final currentRoute = state.uri.path;

      print('🔄 Redirection - Route: $currentRoute, Authentifié: $isLoggedIn');

      // Ne jamais bloquer l'accès à l'écran d'alerte active - PERMET LA NAVIGATION
      if (currentRoute == AppConstants.routeVictimActiveAlert) {
        print('✅ Accès autorisé à l\'écran d\'alerte active');
        return null;
      }

      // Éviter toute redirection quand on est déjà sur une route victime (sauf cas spéciaux)
      if (isLoggedIn && currentRoute.startsWith('/victim/')) {
        // Ne jamais rediriger si on est déjà où on doit être
        print('✅ Route victime autorisée: $currentRoute');
        return null;
      }

      // Vérifier l'accès aux routes protégées
      if (_isProtectedRoute(currentRoute) && !isLoggedIn) {
        print('🚫 Accès refusé à la route protégée: $currentRoute');
        return AppConstants.routeWelcome;
      }

      // App lock: si une méthode est configurée, demander le déverrouillage au premier accès protégé
      // Implémentation légère: on intercepte ici l'accès au dashboard et on pousse un lock screen modal
      if (isLoggedIn && _isProtectedRoute(currentRoute)) {
        _maybeRequireAppLock(context);
      }

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

  static bool _lockShown = false;
  static Future<void> _maybeRequireAppLock(BuildContext context) async {
    if (_lockShown) return;
    _lockShown = true;
    try {
      final method = await SecurityService.instance.getLockMethod();
      if (method == AppLockMethod.none) {
        _lockShown = false;
        return;
      }
      // Afficher le lock screen modale non destructif
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
          insetPadding: EdgeInsets.all(24),
          child: SizedBox(height: 260, child: AppLockScreen()),
        ),
      );
      // Si annulé ou faux, retourner à l'écran de bienvenue
      if (ok != true && context.mounted) {
        context.go(AppConstants.routeWelcome);
      }
    } catch (_) {
      // En cas d'erreur, ne pas bloquer l'utilisateur
    } finally {
      _lockShown = false;
    }
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

      // Route de test RPC (temporaire)
      GoRoute(
        path: '/test-rpc',
        name: 'test_rpc',
        builder: (context, state) => const TestRPCWidget(),
      ),

      // Routes des victimes
      GoRoute(
        path: AppConstants.routeVictimHome,
        name: 'victim_home',
        builder: (context, state) => const VictimHomeScreen(),
      ),
      // Menu modal conservé; l'écran menu est supprimé
      
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
      
      // Route de l'écran du forum communautaire (nouvelle version)
      GoRoute(
        path: AppConstants.routeVictimForum,
        name: 'victim_forum',
        builder: (context, state) => const CommunityForumScreen(),
      ),

      // Route des ressources éducatives
      GoRoute(
        path: AppConstants.routeVictimResources,
        name: 'victim_resources',
        builder: (context, state) => const VictimResourcesScreen(),
      ),

      // Route écran ONG 24/24
      GoRoute(
        path: AppConstants.routeVictimNGO,
        name: 'victim_ngo',
        builder: (context, state) => const VictimNGOScreen(),
      ),
      
      // Route de la carte GPS temps réel (OSM)
      GoRoute(
        path: AppConstants.routeVictimLiveMap,
        name: 'victim_live_map',
        builder: (context, state) => const VictimMapScreen(),
      ),
      // Route de la page d'autorisations
      GoRoute(
        path: AppConstants.routePermissions,
        name: 'permissions',
        builder: (context, state) => const PermissionsPage(),
      ),
      
      // Route de l'écran de sécurité et confidentialité
      GoRoute(
        path: AppConstants.routeVictimSecurity,
        name: 'victim_security',
        builder: (context, state) => const VictimSecurityScreen(),
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

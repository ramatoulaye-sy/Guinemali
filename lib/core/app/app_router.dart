import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/security_service.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import 'router_refresh.dart';
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
      refreshListenable: Listenable.merge([authProvider, RouterRefresh.instance]),

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

      // Si une alerte active existe ET est réellement active, rediriger vers l'écran d'alerte
      final activeAlertId = StorageService.instance.getString(AppConstants.keyCurrentAlertId);
      if (activeAlertId != null && activeAlertId.isNotEmpty) {
        // Ne rediriger que si un flag temporaire demande l'ouverture de l'écran
        final shouldOpen = StorageService.instance.getString('current_alert_should_open') == '1';
        if (!shouldOpen) {
          // Pas de redirection automatique au démarrage/hot restart
          return null;
        }
        final alertJson = StorageService.instance.getString('alert_$activeAlertId');
        if (alertJson == null || alertJson.isEmpty) {
          // Clé orpheline: nettoyer pour éviter les redirections fantômes
          StorageService.instance.remove(AppConstants.keyCurrentAlertId);
        } else {
          try {
            final Map<String, dynamic> alert = jsonDecode(alertJson);
            final dynamic status = alert['statut'] ?? alert['status'];
            if (status == 'active') {
              if (currentRoute != AppConstants.routeVictimActiveAlert) {
                print('🚨 Redirection vers alerte active: $activeAlertId');
                return AppConstants.routeVictimActiveAlert;
              }
            } else {
              // Plus active: nettoyer la clé pour éviter redirections futures
              StorageService.instance.remove(AppConstants.keyCurrentAlertId);
            }
          } catch (e) {
            // JSON invalide: nettoyer la clé
            StorageService.instance.remove(AppConstants.keyCurrentAlertId);
          }
        }
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
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AppLockScreen(),
        ).then((_) {
          _lockShown = false;
        });
      } else {
        _lockShown = false;
      }
    } catch (e) {
      _lockShown = false;
      print('❌ Erreur AppLock: $e');
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
      
      // Plan d'urgence
      GoRoute(
        path: AppConstants.routeVictimEmergencyPlan,
        name: 'victim_emergency_plan',
        builder: (context, state) => const VictimEmergencyPlanScreen(),
      ),

      GoRoute(
        path: AppConstants.routeVictimHistory,
        name: 'victim_history',
        builder: (context, state) => const VictimHistoryScreen(),
      ),

      GoRoute(
        path: AppConstants.routeVictimSettings,
        name: 'victim_settings',
        builder: (context, state) => const VictimSettingsScreen(),
      ),

      GoRoute(
        path: AppConstants.routeVictimHelp,
        name: 'victim_help',
        builder: (context, state) => const VictimHelpScreen(),
      ),

      GoRoute(
        path: AppConstants.routeVictimProfile,
        name: 'victim_profile',
        builder: (context, state) => const VictimProfileScreen(),
      ),

      GoRoute(
        path: AppConstants.routeVictimForum,
        name: 'victim_forum',
        builder: (context, state) => const CommunityForumScreen(),
      ),

      GoRoute(
        path: AppConstants.routeVictimResources,
        name: 'victim_resources',
        builder: (context, state) => const VictimResourcesScreen(),
      ),

      GoRoute(
        path: AppConstants.routeVictimNGO,
        name: 'victim_ngo',
        builder: (context, state) => const VictimNGOScreen(),
      ),

      GoRoute(
        path: AppConstants.routePermissions,
        name: 'permissions',
        builder: (context, state) => const PermissionsPage(),
      ),

      GoRoute(
        path: AppConstants.routeVictimSecurity,
        name: 'victim_security',
        builder: (context, state) => const VictimSecurityScreen(),
      ),

      GoRoute(
        path: AppConstants.routeVictimRecordEvidence,
        name: 'victim_record_evidence',
        builder: (context, state) => const VictimEvidenceScreen(),
      ),
    ];
  }
}

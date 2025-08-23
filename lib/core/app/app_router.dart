import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../../shared/screens/welcome_screen.dart';
import '../../shared/screens/login_screen.dart';
import '../../shared/screens/register_screen.dart';
import '../../victim/screens/victim_home_screen.dart';
import '../../victim/screens/victim_dashboard_screen.dart';

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
      initialLocation: AppConstants.routeVictimDashboard, // TEMPORAIREMENT - Aller directement au dashboard
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
      // TEMPORAIREMENT DÉSACTIVÉ - Contournement des problèmes Supabase
      // final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // final isLoggedIn = authProvider.isAuthenticated;
      final currentRoute = state.uri.path;

      print('🔄 Redirection - Route: $currentRoute, AUTHENTIFICATION DÉSACTIVÉE TEMPORAIREMENT');

      // TEMPORAIREMENT DÉSACTIVÉ - Permettre l'accès à toutes les routes
      // if (_isProtectedRoute(currentRoute) && !isLoggedIn) {
      //   print('🚫 Accès refusé à la route protégée: $currentRoute');
      //   return AppConstants.routeWelcome;
      // }

      // Rediriger directement vers le dashboard des victimes si on est sur la page d'accueil
      if (currentRoute == AppConstants.routeWelcome) {
        print('🚀 Redirection directe vers le dashboard des victimes');
        return AppConstants.routeVictimDashboard;
      }

      return null;
    } catch (e) {
      print('❌ Erreur lors de la redirection: $e');
      // En cas d'erreur, rediriger vers le dashboard au lieu de la page d'accueil
      return AppConstants.routeVictimDashboard;
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
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';

/// Écran de menu principal pour les victimes
class VictimMenuScreen extends StatelessWidget {
  const VictimMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.whiteColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            // Profil utilisateur
            _buildUserProfile(user?.prenom ?? 'Utilisateur'),
            
            const SizedBox(height: AppConstants.spacingLarge),
            
            // Menu principal
            _buildMenuSection(
              title: 'Communauté',
              items: [
                MenuItemData(
                  icon: Icons.forum,
                  title: 'Communauté (Forum)',
                  subtitle: 'Échanger avec la communauté',
                  onTap: () => context.push('/victim/forum'),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingMedium),
            
            _buildMenuSection(
              title: 'Mon Profil',
              items: [
                MenuItemData(
                  icon: Icons.person,
                  title: 'Mon Profil',
                  subtitle: 'Gérer vos informations personnelles',
                  onTap: () => context.push('/victim/profile'),
                ),
                MenuItemData(
                  icon: Icons.emergency,
                  title: 'Plan d\'Urgence',
                  subtitle: 'Personnaliser votre plan de sécurité',
                  onTap: () => context.push('/victim/emergency-plan'),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingMedium),
            
            _buildMenuSection(
              title: 'Mes Données',
              items: [
                MenuItemData(
                  icon: Icons.video_library,
                  title: 'Mes Preuves',
                  subtitle: 'Gérer vos enregistrements',
                  onTap: () => context.push('/victim/evidence'),
                ),
                MenuItemData(
                  icon: Icons.history,
                  title: 'Historique',
                  subtitle: 'Voir l\'historique des alertes',
                  onTap: () => context.push('/victim/history'),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingMedium),
            
            _buildMenuSection(
              title: 'Paramètres',
              items: [
                MenuItemData(
                  icon: Icons.settings,
                  title: 'Paramètres',
                  subtitle: 'Configuration de l\'application',
                  onTap: () => context.push('/victim/settings'),
                ),
                MenuItemData(
                  icon: Icons.help_outline,
                  title: 'Aide et Support',
                  subtitle: 'Guide utilisateur et support',
                  onTap: () => context.push('/victim/help'),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingLarge),
            
            // Section déconnexion
            _buildLogoutSection(context, authProvider),
            
            const SizedBox(height: AppConstants.spacingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(String userName) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppConstants.whiteColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.whiteColor,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: AppConstants.whiteColor,
              size: 30,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: AppConstants.whiteColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Utilisatrice • Mode sécurisé actif',
                  style: TextStyle(
                    color: AppConstants.whiteColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.whiteColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield,
              color: AppConstants.whiteColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<MenuItemData> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          ...items.map((item) => _buildMenuItem(item)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItemData item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingSmall,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Icon(
                  item.icon,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: AppConstants.errorColor.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context, authProvider),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppConstants.errorColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMedium),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Déconnexion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.errorColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Se déconnecter de l\'application',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppConstants.errorColor.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        context.go('/welcome');
      }
    }
  }
}

/// Classe de données pour les éléments de menu
class MenuItemData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  MenuItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

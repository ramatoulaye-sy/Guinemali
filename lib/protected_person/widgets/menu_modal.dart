import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/storage_service.dart';

import '../../core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

/// Fenêtre modale pour le menu principal
class MenuModal extends StatefulWidget {
  const MenuModal({super.key});

  @override
  State<MenuModal> createState() => _MenuModalState();
}

class _MenuModalState extends State<MenuModal> {
  // Données du plan d'urgence
  String _emergencyInstructions = '';
  String _safePlaces = '';
  String _escapeRoutes = '';
  String _medicalInfo = '';

  @override
  void initState() {
    super.initState();
    _loadEmergencyPlan();
  }

  Future<void> _loadEmergencyPlan() async {
    final storage = StorageService.instance;
    setState(() {
      _emergencyInstructions = storage.getString('emergency_instructions') ?? '';
      _safePlaces = storage.getString('emergency_safe_places') ?? '';
      _escapeRoutes = storage.getString('emergency_escape_routes') ?? '';
      _medicalInfo = storage.getString('emergency_medical_info') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Barre de titre
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Menu Principal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Contenu du menu
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Première ligne de boutons
                Row(
                  children: [
                    Expanded(
                      child: _buildMenuButton(
                        icon: Icons.settings,
                        label: 'Paramètres',
                        color: AppTheme.primaryColor,
                        onTap: _openSettings,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMenuButton(
                        icon: Icons.camera_alt,
                        label: 'Preuves',
                        color: AppTheme.secondaryColor,
                        onTap: _openEvidence,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Deuxième ligne de boutons
                Row(
                  children: [
                    Expanded(
                      child: _buildMenuButton(
                        icon: Icons.security,
                        label: 'Sécurité et\nConfidentialité',
                        color: AppTheme.warningColor,
                        onTap: _openSecurity,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMenuButton(
                        icon: Icons.admin_panel_settings,
                        label: 'Autorisations',
                        color: AppTheme.accentColor,
                        onTap: _openPermissions,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Troisième ligne de boutons
                Row(
                  children: [
                    Expanded(
                      child: _buildMenuButton(
                        icon: Icons.history,
                        label: 'Historique',
                        color: AppTheme.successColor,
                        onTap: _openHistory,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                const SizedBox(height: 24),

                // Plan d'urgence (toujours visible)
                _buildEmergencyPlanSection(),

                const SizedBox(height: 24),

                // Bouton de déconnexion
                _buildLogoutButton(),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Construit un bouton du menu
  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la section du plan d'urgence
  Widget _buildEmergencyPlanSection() {
    final isComplete = _emergencyInstructions.isNotEmpty &&
        _safePlaces.isNotEmpty &&
        _escapeRoutes.isNotEmpty &&
        _medicalInfo.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du plan d'urgence
          Row(
            children: [
              Icon(
                Icons.emergency,
                color: AppTheme.emergencyColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Plan d\'Urgence',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              // Badge de statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isComplete ? AppTheme.successColor : AppTheme.warningColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isComplete ? 'Complet' : 'À compléter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Résumé du plan
          if (_emergencyInstructions.isNotEmpty) ...[
            _buildPlanItem('Instructions', _emergencyInstructions),
            const SizedBox(height: 8),
          ],
          if (_safePlaces.isNotEmpty) ...[
            _buildPlanItem('Lieux sûrs', _safePlaces),
            const SizedBox(height: 8),
          ],
          if (_escapeRoutes.isNotEmpty) ...[
            _buildPlanItem('Voies d\'évacuation', _escapeRoutes),
            const SizedBox(height: 8),
          ],
          if (_medicalInfo.isNotEmpty) ...[
            _buildPlanItem('Informations médicales', _medicalInfo),
            const SizedBox(height: 8),
          ],

          if (!isComplete)
            Text(
              'Aucun plan d\'urgence configuré',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),

          const SizedBox(height: 16),

          // Bouton pour ouvrir le plan d'urgence
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openEmergencyPlan,
              icon: const Icon(Icons.edit),
              label: const Text('Modifier le Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un élément du plan d'urgence
  Widget _buildPlanItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Construit le bouton de déconnexion
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Déconnexion'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Actions des boutons
  void _openSettings() {
    print('🔧 Tentative d\'ouverture des paramètres...');
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    print('🔧 Navigation vers: ${AppConstants.routeVictimSettings}');
    try {
      context.push(AppConstants.routeVictimSettings);
      print('✅ Navigation vers paramètres réussie');
    } catch (e) {
      print('❌ Erreur navigation paramètres: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur navigation paramètres: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openEvidence() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    context.push(AppConstants.routeVictimEvidence);
  }

  void _openSecurity() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    context.push(AppConstants.routeVictimSecurity);
  }

  void _openPermissions() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    context.push(AppConstants.routePermissions);
  }

  void _openHistory() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    context.push(AppConstants.routeVictimHistory);
  }

  void _openEmergencyPlan() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    context.push(AppConstants.routeVictimEmergencyPlan);
  }

  void _logout() {
    HapticFeedback.heavyImpact();
    
    // Afficher une boîte de dialogue de confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer la boîte de dialogue
              Navigator.of(context).pop(); // Fermer la modale du menu
              
              // Déconnexion via AuthProvider
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              
              // Navigation vers l'écran de bienvenue
              context.go(AppConstants.routeWelcome);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Écran dédié aux actions rapides avec tous les boutons
class VictimQuickActionsScreen extends StatefulWidget {
  const VictimQuickActionsScreen({super.key});

  @override
  State<VictimQuickActionsScreen> createState() => _VictimQuickActionsScreenState();
}

class _VictimQuickActionsScreenState extends State<VictimQuickActionsScreen> {
  bool _smsAutomatique = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Actions Rapides',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Carte Actions Rapides
              _buildQuickActionsCard(),
              
              const SizedBox(height: 24),
              
              // Carte Plan d'Urgence
              _buildEmergencyPlanCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la carte des actions rapides
  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Titre avec points décoratifs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Actions Rapides',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Boutons d'actions rapides
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.volume_up,
                  label: 'Alerte Sonore',
                  color: Colors.orange,
                  onTap: () => _handleSoundAlert(),
                ),
                _buildActionButton(
                  icon: Icons.phone,
                  label: 'Appel Urgence',
                  color: Colors.red,
                  onTap: () => _handleEmergencyCall(),
                ),
                _buildActionButton(
                  icon: Icons.contact_phone,
                  label: 'Mes Contacts',
                  color: Colors.green,
                  onTap: () => _handleContacts(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.videocam,
                  label: 'Enregistrer Preuve',
                  color: AppTheme.primaryColor,
                  onTap: () => _handleRecordEvidence(),
                ),
                _buildActionButton(
                  icon: Icons.location_on,
                  label: 'Partager Position',
                  color: Colors.green,
                  onTap: () => _handleShareLocation(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Toggle SMS automatique
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SMS automatique',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch(
                  value: _smsAutomatique,
                  onChanged: (value) {
                    setState(() {
                      _smsAutomatique = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                  activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un bouton d'action rapide
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construit la carte du plan d'urgence
  Widget _buildEmergencyPlanCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // En-tête du plan d'urgence
            Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Plan d\'Urgence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'À compléter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.edit, color: AppTheme.primaryColor),
                  onPressed: () => _handleEditEmergencyPlan(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Éléments du plan d'urgence
            _buildEmergencyPlanItem(
              icon: Icons.assignment,
              title: 'Instructions',
              color: Colors.red,
            ),
            _buildEmergencyPlanItem(
              icon: Icons.location_on,
              title: 'Lieux sûrs',
              color: Colors.blue,
            ),
            _buildEmergencyPlanItem(
              icon: Icons.directions_run,
              title: 'Évacuation',
              color: Colors.green,
            ),
            _buildEmergencyPlanItem(
              icon: Icons.medical_services,
              title: 'Infos médicales',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un élément du plan d'urgence
  Widget _buildEmergencyPlanItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Non défini',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Gestionnaires des actions
  void _handleSoundAlert() {
    // TODO: Implémenter la logique d'alerte sonore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔊 Alerte sonore activée - Redirection vers les paramètres'),
        backgroundColor: Colors.orange,
      ),
    );
    // Redirection vers les paramètres pour configurer l'alerte sonore
    context.push(AppConstants.routeVictimSettings);
  }

  void _handleEmergencyCall() {
    // TODO: Implémenter la logique d'appel d'urgence
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📞 Appel d\'urgence - Redirection vers les contacts'),
        backgroundColor: Colors.red,
      ),
    );
    // Redirection vers les contacts d'urgence
    context.push(AppConstants.routeVictimContacts);
  }

  void _handleContacts() {
    context.push(AppConstants.routeVictimContacts);
  }

  void _handleRecordEvidence() {
    context.push(AppConstants.routeVictimRecordEvidence);
  }

  void _handleShareLocation() {
    // TODO: Implémenter la logique de partage de position
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Position partagée - Redirection vers les contacts'),
        backgroundColor: Colors.green,
      ),
    );
    // Redirection vers les contacts pour partager la position
    context.push(AppConstants.routeVictimContacts);
  }

  void _handleEditEmergencyPlan() {
    // TODO: Implémenter la logique d'édition du plan d'urgence
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✏️ Édition du plan d\'urgence - Redirection vers le plan'),
        backgroundColor: Colors.blue,
      ),
    );
    // Redirection vers le plan d'urgence
    context.push(AppConstants.routeVictimEmergencyPlan);
  }
}

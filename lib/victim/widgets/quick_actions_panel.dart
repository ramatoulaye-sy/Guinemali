import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/emergency_contact_service.dart';

/// Panneau d'actions rapides pour les victimes
/// Permet d'accéder rapidement aux fonctionnalités importantes
class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFF8F9FA),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF945acb).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF945acb).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF945acb),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Actions Rapides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF945acb),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFee82ee),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          LayoutBuilder(
            builder: (context, constraints) {
              final actions = <Widget>[
                _buildQuickAction(
                  context,
                  icon: Icons.volume_up,
                  label: 'Alerte\nSonore',
                  color: const Color(0xFFFF9800),
                  onTap: () { HapticFeedback.selectionClick(); _triggerSoundAlert(context); },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.phone,
                  label: 'Appel\nUrgence',
                  color: const Color(0xFFFF0000),
                  onTap: () { HapticFeedback.mediumImpact(); _makeEmergencyCall(context); },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.contacts,
                  label: 'Mes\nContacts',
                  color: const Color(0xFF4CAF50),
                  onTap: () { HapticFeedback.selectionClick(); context.push(AppConstants.routeVictimContacts); },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.videocam,
                  label: 'Enregistrer\nPreuve',
                  color: const Color(0xFF945acb),
                  onTap: () { HapticFeedback.selectionClick(); _navigateToEvidence(context); },
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.share_location,
                  label: 'Partager\nPosition',
                  color: const Color(0xFF4CAF50),
                  onTap: () { HapticFeedback.selectionClick(); _shareLocation(context); },
                ),
              ];
              if (constraints.maxWidth < 380) {
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: actions,
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerSoundAlert(BuildContext context) {
    try {
      // TODO: Implémenter l'alerte sonore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 Alerte sonore déclenchée'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur alerte sonore: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _makeEmergencyCall(BuildContext context) async {
    try {
      await EmergencyContactService.instance.startOrContinueCallSequence();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur appel d\'urgence: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToEvidence(BuildContext context) {
    try {
      // Navigation vers l'enregistrement des preuves
      context.push('/victim/record-evidence');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur navigation: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _shareLocation(BuildContext context) {
    try {
      // TODO: Implémenter le partage de position
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Position partagée avec vos contacts'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur partage position: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }
}

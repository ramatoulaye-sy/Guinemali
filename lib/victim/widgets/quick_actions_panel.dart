import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/emergency_contact_service.dart';
import '../../core/services/geolocation_service.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart'; // Added import for AppTheme

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
            color: const Color(0xFF945acb).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF945acb).withValues(alpha: 0.1),
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
          // Bandeau d'état de séquence d'appels (si en cours)
          ValueListenableBuilder<bool>(
            valueListenable: EmergencyContactService.instance.isRunning,
            builder: (context, running, _) {
              if (!running) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: ValueListenableBuilder<String>(
                  valueListenable: EmergencyContactService.instance.statusText,
                  builder: (context, text, __) {
                    return Text(
                      text,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 6),
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
          const SizedBox(height: 12),
          // Toggle SMS automatique
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sms, size: 16, color: AppTheme.secondaryColor),
              const SizedBox(width: 6),
              Text(
                'SMS automatique',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor, // Couleur de texte principale pour meilleure visibilité
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<bool>(
                valueListenable: EmergencyContactService.instance.autoSmsEnabled,
                builder: (context, enabled, _) {
                  return Switch(
                    value: enabled,
                    onChanged: (v) => EmergencyContactService.instance.setAutoSmsEnabled(v),
                    activeColor: AppTheme.secondaryColor, // Couleur active de la couleur secondaire
                  );
                },
              ),
            ],
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
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
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
                color: color.withValues(alpha: 0.8),
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
      // Alerte sonore simple: série de bips et vibrations
      const int repeats = 6;
      Future<void> playSequence() async {
        for (int i = 0; i < repeats; i++) {
          await SystemSound.play(SystemSoundType.alert);
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 650));
        }
      }

      unawaited(playSequence());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 Alerte sonore en cours (montez le volume)'),
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
      // Petit dialog non bloquant avec progression
      _showCallProgressDialog(context);
      await EmergencyContactService.instance.callAllContactsWithFallback(
        callWindow: const Duration(seconds: 25),
        waitBetween: const Duration(seconds: 5),
      );
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur appel d\'urgence: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _showCallProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              ValueListenableBuilder<String>(
                valueListenable: EmergencyContactService.instance.statusText,
                builder: (_, text, __) => Text(text.isEmpty ? 'Préparation…' : text),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
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
    () async {
      try {
        final pos = await GeolocationService.instance.getCurrentPosition();
        final lat = pos.latitude.toStringAsFixed(6);
        final lon = pos.longitude.toStringAsFixed(6);
        final mapsUrl = 'https://maps.google.com/?q=$lat,$lon';
        final smsBody = Uri.encodeComponent('Voici ma position: $lat,$lon\n$mapsUrl');

        // Ouvrir le composeur SMS avec le message pré-rempli (si dispo)
        final smsUri = Uri.parse('sms:?body=$smsBody');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
          return;
        }

        // Fallback: ouvrir simplement la carte
        final mapUri = Uri.parse(mapsUrl);
        if (await canLaunchUrl(mapUri)) {
          await launchUrl(mapUri, mode: LaunchMode.externalApplication);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Lien de position prêt dans l\'application choisie'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur partage position: $e'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }();
  }
}

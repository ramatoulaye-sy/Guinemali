import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/emergency_contact_service.dart';

/// Fenêtre modale pour les actions rapides
class QuickActionsModal extends StatefulWidget {
  const QuickActionsModal({super.key});

  @override
  State<QuickActionsModal> createState() => _QuickActionsModalState();
}

class _QuickActionsModalState extends State<QuickActionsModal> {
  bool _isSoundAlertActive = false;
  bool _isAutoSmsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoSms = StorageService.instance.getBool('emergency_auto_sms', defaultValue: false);
    setState(() {
      _isAutoSmsEnabled = autoSms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  Icons.flash_on,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Actions Rapides',
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

          // Contenu des actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Première ligne d'actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.volume_up,
                        label: 'Alerte Sonore',
                        color: AppTheme.warningColor,
                        onTap: _triggerSoundAlert,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone,
                        label: 'Appel d\'Urgence',
                        color: AppTheme.emergencyColor,
                        onTap: _makeEmergencyCall,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Deuxième ligne d'actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.contacts,
                        label: 'Mes Contacts',
                        color: AppTheme.primaryColor,
                        onTap: _openContacts,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.camera_alt,
                        label: 'Enregistrer Preuve',
                        color: AppTheme.secondaryColor,
                        onTap: _recordEvidence,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Toggle SMS automatique
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sms,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SMS Automatique',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Envoyer automatiquement un SMS en cas d\'urgence',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAutoSmsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isAutoSmsEnabled = value;
                          });
                          _toggleAutoSms(value);
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un bouton d'action
  Widget _buildActionButton({
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

  /// Déclenche l'alerte sonore
  void _triggerSoundAlert() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSoundAlertActive = !_isSoundAlertActive;
    });
    
    // TODO: Implémenter l'alerte sonore
    print('🔊 Alerte sonore: ${_isSoundAlertActive ? 'activée' : 'désactivée'}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSoundAlertActive ? 'Alerte sonore activée' : 'Alerte sonore désactivée',
        ),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  /// Fait l'appel d'urgence
  void _makeEmergencyCall() {
    HapticFeedback.heavyImpact();
    
    // Utiliser le service d'urgence
    EmergencyContactService.instance.callAllContactsWithFallback();
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appel d\'urgence en cours...'),
        backgroundColor: AppTheme.emergencyColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Ouvre les contacts
  void _openContacts() {
    HapticFeedback.lightImpact();
    
    // TODO: Implémenter l'ouverture des contacts
    print('👥 Ouverture des contacts');
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture des contacts...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  /// Enregistre une preuve
  void _recordEvidence() {
    HapticFeedback.lightImpact();
    
    // TODO: Implémenter l'enregistrement de preuve
    print('📸 Enregistrement de preuve');
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enregistrement de preuve...'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  /// Active/désactive le SMS automatique
  void _toggleAutoSms(bool enabled) {
    StorageService.instance.setBool('emergency_auto_sms', enabled);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'SMS automatique activé' : 'SMS automatique désactivé',
        ),
        backgroundColor: enabled ? AppTheme.successColor : AppTheme.warningColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

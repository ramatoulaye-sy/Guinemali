import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';

/// Écran dédié aux actions rapides avec tous les boutons
class VictimQuickActionsScreen extends StatefulWidget {
  const VictimQuickActionsScreen({super.key});

  @override
  State<VictimQuickActionsScreen> createState() => _VictimQuickActionsScreenState();
}

class _VictimQuickActionsScreenState extends State<VictimQuickActionsScreen> {
  bool _smsAutomatique = true;
  String _customSosMessage = '';
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final customMessage = StorageService.instance.getString('custom_sos_message') ?? '';
    final vibration = StorageService.instance.getBool('vibration_enabled', defaultValue: true);
    final sound = StorageService.instance.getBool('sound_enabled', defaultValue: true);
    
    setState(() {
      _customSosMessage = customMessage;
      _vibrationEnabled = vibration;
      _soundEnabled = sound;
    });
  }

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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Carte Actions Rapides
            _buildQuickActionsCard(),

            const SizedBox(height: 24),

            // Carte Configuration Rapide
            _buildQuickConfigCard(),

            const SizedBox(height: 16),

            // Carte Plan d'Urgence
            _buildEmergencyPlanCard(),

            const SizedBox(height: 24),
          ],
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

  /// Construit la carte de configuration rapide
  Widget _buildQuickConfigCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Titre avec icône
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings,
                  color: AppTheme.secondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Configuration Rapide',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Boutons de configuration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildConfigButton(
                  icon: Icons.message,
                  label: 'Message SOS',
                  color: Colors.blue,
                  onTap: () => _configureSosMessage(),
                ),
                _buildConfigButton(
                  icon: Icons.gps_fixed,
                  label: 'GPS',
                  color: Colors.green,
                  onTap: () => _openLiveMap(),
                ),
                _buildConfigButton(
                  icon: Icons.videocam,
                  label: 'Test Enregistrement',
                  color: AppTheme.primaryColor,
                  onTap: () => _testRecording(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Toggles pour vibration et son
            Row(
              children: [
                Expanded(
                  child: _buildToggleOption(
                    icon: Icons.vibration,
                    label: 'Vibration',
                    value: _vibrationEnabled,
                    onChanged: (value) {
                      setState(() => _vibrationEnabled = value);
                      StorageService.instance.saveBool('vibration_enabled', value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildToggleOption(
                    icon: Icons.volume_up,
                    label: 'Son',
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() => _soundEnabled = value);
                      StorageService.instance.saveBool('sound_enabled', value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un bouton de configuration
  Widget _buildConfigButton({
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construit une option toggle
  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: value ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? AppTheme.primaryColor : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: value ? AppTheme.primaryColor : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: value ? AppTheme.primaryColor : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    try {
      // Vibration personnalisée si activée
      if (_vibrationEnabled) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 200), () {
          HapticFeedback.mediumImpact();
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          HapticFeedback.lightImpact();
        });
      }
      
      // Son personnalisé si activé
      if (_soundEnabled) {
        SystemSound.play(SystemSoundType.alert);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔊 Alerte sonore ${_soundEnabled ? "activée" : "(son désactivé)"} ${_vibrationEnabled ? "+ vibration" : ""}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 Alerte sonore'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleEmergencyCall() {
    final Uri telUri = Uri(scheme: 'tel', path: '112');
    launchUrl(telUri, mode: LaunchMode.externalApplication);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📞 Appel d\'urgence (112) en cours...'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleContacts() {
    context.push(AppConstants.routeVictimContacts);
  }

  void _handleRecordEvidence() {
    context.push(AppConstants.routeVictimRecordEvidence);
  }

  void _handleShareLocation() {
    () async {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activez le GPS pour partager la position.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission localisation refusée.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission localisation bloquée dans les paramètres.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final pos = await Geolocator.getCurrentPosition();
        final url = 'https://www.google.com/maps?q=${pos.latitude},${pos.longitude}';
        await Clipboard.setData(ClipboardData(text: url));
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Lien de position ouvert et copié.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur localisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }();
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

  // Nouvelles méthodes de configuration
  void _configureSosMessage() {
    final controller = TextEditingController(text: _customSosMessage);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Message SOS Personnalisé',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Créez un message personnalisé qui sera envoyé avec vos alertes d\'urgence.',
              style: TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Entrez votre message personnalisé',
                labelText: 'Message SOS',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 160,
            ),
            const Text(
              'Exemple: "Je suis en danger, aidez-moi. Ma position sera partagée."',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _customSosMessage = controller.text.trim());
              StorageService.instance.saveString('custom_sos_message', _customSosMessage);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message SOS mis à jour'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  

  void _openLiveMap() {
    context.push(AppConstants.routeVictimLiveMap);
  }

  void _testRecording() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Test d\'Enregistrement',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Voulez-vous tester l\'enregistrement audio/vidéo ?',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(AppConstants.routeVictimRecordEvidence);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tester'),
          ),
        ],
      ),
    );
  }
}

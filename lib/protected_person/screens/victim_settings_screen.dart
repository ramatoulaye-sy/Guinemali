import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/providers/theme_provider.dart';
import 'package:guinemali/core/providers/locale_provider.dart';
import 'package:guinemali/core/services/security_service.dart';
import '../widgets/settings_form.dart';
import '../widgets/setting_toggle_item.dart';
import 'package:guinemali/core/widgets/gps_permission_widget.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class VictimSettingsScreen extends StatefulWidget {
  const VictimSettingsScreen({super.key});

  @override
  State<VictimSettingsScreen> createState() => _VictimSettingsScreenState();
}

class _VictimSettingsScreenState extends State<VictimSettingsScreen> {
  bool _pushNotifications = true;
  bool _smsNotifications = true;
  bool _emailNotifications = false;
  bool _locationSharing = true;
  bool _autoSync = true;
  bool _darkMode = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _officialEmergencyNumber = '';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _openAppLockDialog(BuildContext context) async {
    final method = await SecurityService.instance.getLockMethod();
    AppLockMethod selected = method;
    final pinController = TextEditingController();

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Sécurité de l\'application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<AppLockMethod>(
                value: AppLockMethod.none,
                groupValue: selected,
                title: const Text('Aucune'),
                onChanged: (v) => setState(() => selected = v!),
              ),
              RadioListTile<AppLockMethod>(
                value: AppLockMethod.biometrics,
                groupValue: selected,
                title: const Text('Biométrie (empreinte/visage)'),
                onChanged: (v) async {
                  final can = await SecurityService.instance.canCheckBiometrics();
                  if (!can) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Biométrie non disponible sur cet appareil')),
                    );
                    return;
                  }
                  setState(() => selected = v!);
                },
              ),
              RadioListTile<AppLockMethod>(
                value: AppLockMethod.pin,
                groupValue: selected,
                title: const Text('Code PIN'),
                onChanged: (v) => setState(() => selected = v!),
              ),
              if (selected == AppLockMethod.pin)
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                await SecurityService.instance.setLockMethod(selected);
                if (selected == AppLockMethod.pin) {
                  await SecurityService.instance.savePin(pinController.text.trim());
                }
                if (context.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paramètres de sécurité enregistrés')),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      _pushNotifications = StorageService.instance.getBool('push_notifications', defaultValue: true);
      _smsNotifications = StorageService.instance.getBool('sms_notifications', defaultValue: true);
      _emailNotifications = StorageService.instance.getBool('email_notifications', defaultValue: false);
      _locationSharing = StorageService.instance.getBool('location_sharing', defaultValue: true);
      _autoSync = StorageService.instance.getBool('auto_sync', defaultValue: true);
      _darkMode = StorageService.instance.getBool('dark_mode', defaultValue: false);
      _soundEnabled = StorageService.instance.getBool('sound_enabled', defaultValue: true);
      _vibrationEnabled = StorageService.instance.getBool('vibration_enabled', defaultValue: true);
      _officialEmergencyNumber = StorageService.instance.getString('official_emergency_number') ?? '';
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des paramètres: $e')),
        );
      }
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      await StorageService.instance.setBool(key, value);
      if (key == 'dark_mode') {
        final themeProvider = context.read<ThemeProvider>();
        themeProvider.toggleTheme();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  Future<void> _saveEmergencyNumber(String value) async {
    try {
      await StorageService.instance.saveString('official_emergency_number', value.trim());
      setState(() => _officialEmergencyNumber = value.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro d\'urgence sauvegardé')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final currentLocale = localeProvider.locale ?? const Locale('fr', 'FR');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildProfessionalAppBar(),
      body: _buildProfessionalBody(),
    );
  }

  /// AppBar professionnel avec design moderne
  PreferredSizeWidget _buildProfessionalAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      title: Row(
        children: [
          ListTile(
            title: const Text('Protection de l\'application'),
            subtitle: const Text('Empreinte digitale, visage ou code PIN'),
            leading: const Icon(Icons.lock_outline),
            onTap: () => _openAppLockDialog(context),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Paramètres',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.secondaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Sécurité',
            style: TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Corps principal avec organisation professionnelle
  Widget _buildProfessionalBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            _buildWelcomeSection(),
            const SizedBox(height: 32),
            _buildNotificationsSection(),
            const SizedBox(height: 24),
            _buildSecuritySection(),
            const SizedBox(height: 24),
            _buildPrivacySection(),
            const SizedBox(height: 24),
            _buildAppearanceSection(),
            const SizedBox(height: 24),
            _buildEmergencySection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// Section d'accueil avec design moderne
  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                        ),
                      ],
                    ),
            child: const Icon(
              Icons.security,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuration de Sécurité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                    const SizedBox(height: 8),
                Text(
                  'Personnalisez vos paramètres de sécurité et de confidentialité pour une protection optimale.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
                        ),
                      ],
                    ),
    );
  }

  /// Section des notifications avec design professionnel
  Widget _buildNotificationsSection() {
    return _buildSectionCard(
      title: 'Notifications',
      icon: Icons.notifications_active,
      color: Colors.blue,
      children: [
        _buildToggleItem(
          title: 'Notifications Push',
          subtitle: 'Recevoir des alertes en temps réel',
          value: _pushNotifications,
          onChanged: (value) {
            setState(() => _pushNotifications = value);
            _saveSetting('push_notifications', value);
          },
          icon: Icons.notifications,
        ),
        _buildToggleItem(
          title: 'Notifications SMS',
          subtitle: 'Alertes par message texte',
          value: _smsNotifications,
          onChanged: (value) {
            setState(() => _smsNotifications = value);
            _saveSetting('sms_notifications', value);
          },
          icon: Icons.sms,
        ),
        _buildToggleItem(
          title: 'Notifications Email',
          subtitle: 'Rapports par email',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() => _emailNotifications = value);
            _saveSetting('email_notifications', value);
          },
          icon: Icons.email,
        ),
      ],
    );
  }

  /// Section de sécurité avec design moderne
  Widget _buildSecuritySection() {
    return _buildSectionCard(
      title: 'Sécurité',
      icon: Icons.security,
      color: Colors.red,
      children: [
        _buildToggleItem(
          title: 'Partage de Position',
          subtitle: 'Autoriser le partage automatique',
          value: _locationSharing,
          onChanged: (value) {
            setState(() => _locationSharing = value);
            _saveSetting('location_sharing', value);
          },
          icon: Icons.location_on,
        ),
        _buildToggleItem(
          title: 'Synchronisation Auto',
          subtitle: 'Synchroniser automatiquement les données',
          value: _autoSync,
          onChanged: (value) {
            setState(() => _autoSync = value);
            _saveSetting('auto_sync', value);
          },
          icon: Icons.sync,
        ),
      ],
    );
  }

  /// Section de confidentialité avec design professionnel
  Widget _buildPrivacySection() {
    return _buildSectionCard(
      title: 'Confidentialité',
      icon: Icons.privacy_tip,
      color: Colors.green,
      children: [
        _buildToggleItem(
          title: 'Mode Sombre',
          subtitle: 'Interface en mode sombre',
                          value: _darkMode,
          onChanged: (value) {
            setState(() => _darkMode = value);
            _saveSetting('dark_mode', value);
          },
          icon: Icons.dark_mode,
        ),
      ],
    );
  }

  /// Section d'apparence avec design moderne
  Widget _buildAppearanceSection() {
    return _buildSectionCard(
      title: 'Apparence',
      icon: Icons.palette,
      color: AppTheme.secondaryColor,
      children: [
        _buildToggleItem(
          title: 'Sons Activés',
          subtitle: 'Activer les sons de l\'application',
          value: _soundEnabled,
          onChanged: (value) {
            setState(() => _soundEnabled = value);
            _saveSetting('sound_enabled', value);
          },
          icon: Icons.volume_up,
        ),
        _buildToggleItem(
          title: 'Vibrations',
          subtitle: 'Activer les vibrations',
          value: _vibrationEnabled,
          onChanged: (value) {
            setState(() => _vibrationEnabled = value);
            _saveSetting('vibration_enabled', value);
          },
          icon: Icons.vibration,
        ),
      ],
    );
  }

  /// Section d'urgence avec design professionnel
  Widget _buildEmergencySection() {
    return _buildSectionCard(
      title: 'Numéro d\'Urgence',
      icon: Icons.emergency,
      color: Colors.orange,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.phone_in_talk,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Numéro Officiel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                        ),
                      ],
                    ),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: _officialEmergencyNumber),
                decoration: InputDecoration(
                  hintText: 'Entrez le numéro d\'urgence officiel',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.emergency,
                    color: Colors.orange,
                  ),
                ),
                onSubmitted: _saveEmergencyNumber,
                          ),
                        ],
                      ),
                    ),
      ],
    );
  }

  /// Bouton de sauvegarde avec design moderne
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Paramètres sauvegardés avec succès'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Sauvegarder les Paramètres',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte de section avec design professionnel
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
              ),
            ],
          ),
          ),
          // Contenu de la section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Élément toggle avec design moderne
  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

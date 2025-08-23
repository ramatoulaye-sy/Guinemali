import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/providers/theme_provider.dart';
import 'package:guinemali/core/providers/locale_provider.dart';
import 'package:guinemali/victim/widgets/settings_form.dart';
import 'package:guinemali/core/widgets/gps_permission_widget.dart';

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
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                    const SizedBox(height: 8),
                    SettingsForm(
                      toggles: [
                        SettingToggleItem(
                          keyName: 'push_notifications',
                          title: 'Notifications Push',
                          subtitle: 'Recevoir des alertes sur votre téléphone',
                          value: _pushNotifications,
                          onChanged: (v) { setState(() => _pushNotifications = v); _saveSetting('push_notifications', v); },
                        ),
                        SettingToggleItem(
                          keyName: 'sms_notifications',
                          title: 'Notifications SMS',
                          subtitle: 'Recevoir des alertes par SMS',
                          value: _smsNotifications,
                          onChanged: (v) { setState(() => _smsNotifications = v); _saveSetting('sms_notifications', v); },
                        ),
                        SettingToggleItem(
                          keyName: 'email_notifications',
                          title: 'Notifications Email',
                          subtitle: 'Recevoir des alertes par email',
                          value: _emailNotifications,
                          onChanged: (v) { setState(() => _emailNotifications = v); _saveSetting('email_notifications', v); },
                        ),
                        SettingToggleItem(
                          keyName: 'sound_enabled',
                          title: 'Son',
                          subtitle: 'Activer les sons d\'alerte',
                          value: _soundEnabled,
                          onChanged: (v) { setState(() => _soundEnabled = v); _saveSetting('sound_enabled', v); },
                        ),
                        SettingToggleItem(
                          keyName: 'vibration_enabled',
                          title: 'Vibration',
                          subtitle: 'Activer les vibrations d\'alerte',
                          value: _vibrationEnabled,
                          onChanged: (v) { setState(() => _vibrationEnabled = v); _saveSetting('vibration_enabled', v); },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text('Confidentialité', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                    const SizedBox(height: 8),
                    SettingsForm(
                      toggles: [
                        SettingToggleItem(
                          keyName: 'location_sharing',
                          title: 'Partage de localisation',
                          subtitle: 'Autoriser le partage de votre position',
                          value: _locationSharing,
                          onChanged: (v) { setState(() => _locationSharing = v); _saveSetting('location_sharing', v); },
                        ),
                        SettingToggleItem(
                          keyName: 'auto_sync',
                          title: 'Synchronisation automatique',
                          subtitle: 'Synchroniser automatiquement les données',
                          value: _autoSync,
                          onChanged: (v) { setState(() => _autoSync = v); _saveSetting('auto_sync', v); },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Widget de gestion des permissions GPS
                    GpsPermissionWidget(
                      showAsCard: false,
                      customMessage: 'Configurez les permissions GPS pour assurer votre sécurité.',
                    ),
                    
                    const SizedBox(height: 24),

                    Text('Préférences', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                    const SizedBox(height: 8),
                    SettingsForm(
                      toggles: [
                        SettingToggleItem(
                          keyName: 'dark_mode',
                          title: 'Mode sombre',
                          subtitle: 'Utiliser le thème sombre',
                          value: _darkMode,
                          onChanged: (v) { setState(() => _darkMode = v); _saveSetting('dark_mode', v); },
                        ),
                      ],
                      extras: [
                        const Divider(),
                        ListTile(
                          title: const Text('Numéro d\'urgence officiel'),
                          subtitle: Text(_officialEmergencyNumber.isEmpty ? '117 (défaut)' : _officialEmergencyNumber),
                          trailing: const Icon(Icons.edit, size: 16),
                          onTap: () async {
                            final value = await _showEmergencyNumberDialog(context, _officialEmergencyNumber);
                            if (value != null) {
                              await _saveEmergencyNumber(value);
                            }
                          },
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Langue'),
                          subtitle: Text(currentLocale.languageCode == 'fr' ? 'Français' : 'English'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final newLocale = await _showLanguagePicker(context, currentLocale);
                            if (newLocale != null) {
                              await context.read<LocaleProvider>().setLocale(newLocale);
                              setState(() {});
                            }
                          },
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Taille du texte'),
                          subtitle: const Text('Moyenne'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélection de taille à implémenter')));
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text('À propos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: const [
                          ListTile(
                            title: Text('Version de l\'application'),
                            subtitle: Text('1.0.0'),
                            trailing: Icon(Icons.info_outline, color: Colors.grey),
                          ),
                          Divider(height: 1),
                          ListTile(
                            title: Text('Conditions d\'utilisation'),
                            subtitle: Text('Lire les conditions d\'utilisation'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                          Divider(height: 1),
                          ListTile(
                            title: Text('Politique de confidentialité'),
                            subtitle: Text('Lire la politique de confidentialité'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                          Divider(height: 1),
                          ListTile(
                            title: Text('Support et aide'),
                            subtitle: Text('Contacter le support'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Locale?> _showLanguagePicker(BuildContext context, Locale current) async {
    Locale? selected = current;
    return showDialog<Locale>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir la langue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<Locale>(
                value: const Locale('fr', 'FR'),
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
                title: const Text('Français'),
              ),
              RadioListTile<Locale>(
                value: const Locale('en', 'US'),
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
                title: const Text('English'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Appliquer')),
          ],
        );
      },
    );
  }

  Future<String?> _showEmergencyNumberDialog(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Numéro d\'urgence officiel'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Ex: 117',
              labelText: 'Numéro',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Enregistrer')),
          ],
        );
      },
    );
  }
}

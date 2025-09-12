import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/security_service.dart';
import 'package:guinemali/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';

class VictimSettingsScreen extends StatefulWidget {
  const VictimSettingsScreen({super.key});

  @override
  State<VictimSettingsScreen> createState() => _VictimSettingsScreenState();
}

class _VictimSettingsScreenState extends State<VictimSettingsScreen> {
  // Notifications (supprimé: géré via type de notifications)
  
  // Sécurité & Confidentialité
  bool _stealthMode = false;
  bool _autoDeleteEvidence = false;
  int _evidenceRetentionDays = 30;
  bool _alertHistoryEnabled = true;
  
  // Connectivité
  String _customSosMessage = '';
  
  // Langue & Accessibilité
  String _selectedLanguage = 'fr';
  String _textSize = 'normal';
  
  // Localisation & Alertes
  String _notificationType = 'push';
  
  // Compte & Utilisation
  String _userPseudo = '';
  String _userLanguage = 'fr';
  
  // Apparence (supprimé: ancienne section non utilisée)
  
  // Urgence (supprimé: ancienne section non utilisée)
  
  // Version
  String _appVersion = '';
  bool _autoUpdates = true;
  
  @override
  void initState() {
    super.initState();
    // Différer toute utilisation de context/Inherited jusqu'après initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSettings();
      _loadAppVersion();
    });
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
          backgroundColor: AppConstants.whiteColor,
          title: const Text(
            'Sécurité de l\'application',
            style: TextStyle(
              color: AppConstants.blackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<AppLockMethod>(
                value: AppLockMethod.none,
                groupValue: selected,
                title: const Text(
                  'Aucune',
                  style: TextStyle(color: AppConstants.blackColor),
                ),
                onChanged: (v) => setState(() => selected = v!),
              ),
              RadioListTile<AppLockMethod>(
                value: AppLockMethod.biometrics,
                groupValue: selected,
                title: const Text(
                  'Biométrie (empreinte/visage)',
                  style: TextStyle(color: AppConstants.blackColor),
                ),
                onChanged: (v) async {
                  final can = await SecurityService.instance.canCheckBiometrics();
                  if (!can) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biométrie non disponible sur cet appareil'),
                        backgroundColor: AppConstants.errorColor,
                      ),
                    );
                    return;
                  }
                  setState(() => selected = v!);
                },
              ),
              RadioListTile<AppLockMethod>(
                value: AppLockMethod.pin,
                groupValue: selected,
                title: const Text(
                  'Code PIN',
                  style: TextStyle(color: AppConstants.blackColor),
                ),
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
                    labelStyle: TextStyle(color: AppConstants.blackColor),
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: AppConstants.primaryColor),
              ),
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
                    const SnackBar(
                      content: Text('Paramètres de sécurité enregistrés'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.whiteColor,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      // Notifications (gérées via type de notifications)
      
      // Sécurité & Confidentialité
      _stealthMode = StorageService.instance.getBool('stealth_mode', defaultValue: false);
      _autoDeleteEvidence = StorageService.instance.getBool('auto_delete_evidence', defaultValue: false);
      _evidenceRetentionDays = StorageService.instance.getInt('evidence_retention_days', defaultValue: 30);
      _alertHistoryEnabled = StorageService.instance.getBool('alert_history_enabled', defaultValue: true);
      
      // Connectivité
      _customSosMessage = StorageService.instance.getString('custom_sos_message') ?? '';
      
      // Langue & Accessibilité
      _selectedLanguage = StorageService.instance.getString('selected_language') ?? 'fr';
      _textSize = StorageService.instance.getString('text_size') ?? 'normal';
      
      // Localisation & Alertes
      _notificationType = StorageService.instance.getString('notification_type') ?? 'push';
      
      // Compte & Utilisation
      _userPseudo = StorageService.instance.getString('user_pseudo') ?? '';
      _userLanguage = StorageService.instance.getString('user_language') ?? 'fr';
      
      // Apparence (non utilisée)
      
      // Urgence (ancienne section supprimée)
      
      // Version
      _autoUpdates = StorageService.instance.getBool('auto_updates', defaultValue: true);
      
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

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Version inconnue';
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      await StorageService.instance.setBool(key, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  Future<void> _saveStringSetting(String key, String value) async {
    try {
      await StorageService.instance.saveString(key, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  Future<void> _saveIntSetting(String key, int value) async {
    try {
      await StorageService.instance.saveString(key, value.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action supprimera définitivement votre compte et toutes vos données. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      // Supprimer toutes les données locales
      await StorageService.instance.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte supprimé avec succès')),
        );
        // Rediriger vers l'écran de connexion
        context.go(AppConstants.routeWelcome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutoriel d\'utilisation'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Bouton SOS: Appuyez longuement pour déclencher une alerte'),
              SizedBox(height: 8),
              Text('2. Contacts: Ajoutez vos contacts de confiance'),
              SizedBox(height: 8),
              Text('3. Preuves: Enregistrez des preuves audio/vidéo'),
              SizedBox(height: 8),
              Text('4. Forum: Participez à la communauté'),
              SizedBox(height: 8),
              Text('5. Paramètres: Personnalisez votre expérience'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _contactONG() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'contact@guinemali.org',
      query: 'subject=Support Guinemali&body=Bonjour, j\'ai besoin d\'aide...',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir l\'email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.whiteColor,
      appBar: _buildProfessionalAppBar(),
      body: _buildProfessionalBody(),
    );
  }

  /// AppBar professionnel avec design moderne
  PreferredSizeWidget _buildProfessionalAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: AppConstants.whiteColor,
      centerTitle: true,
      title: const Text(
        '⚙️ Paramètres',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppConstants.whiteColor,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppConstants.secondaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppConstants.secondaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'Sécurité',
            style: TextStyle(
              color: AppConstants.secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Corps principal en style Material (MD3) utilisant ListView + ListTile
  Widget _buildProfessionalBody() {
    return SafeArea(
      child: ListTileTheme(
        textColor: AppConstants.blackColor,
        iconColor: AppConstants.primaryColor,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            
            _buildSectionHeader('Sécurité & Confidentialité', Icons.lock),
            ..._buildSecurityPrivacyTiles(),
            const Divider(height: 24),

            _buildSectionHeader('Connectivité', Icons.wifi_off),
            ..._buildConnectivityTiles(),
            const Divider(height: 24),

            _buildSectionHeader('Langue & Accessibilité', Icons.language),
            ..._buildLanguageAccessibilityTiles(),
            const Divider(height: 24),

            _buildSectionHeader('Localisation & Alertes', Icons.gps_fixed),
            ..._buildLocationAlertsTiles(),
            const Divider(height: 24),

            _buildSectionHeader('Compte & Utilisation', Icons.person),
            ..._buildAccountUsageTiles(),
            const Divider(height: 24),

            _buildSectionHeader('Techniques & Aide', Icons.support_agent),
            ..._buildTechnicalHelpTiles(),
            const SizedBox(height: 24),

            _buildSaveButton(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  

  /// Tiles: Sécurité & Confidentialité
  List<Widget> _buildSecurityPrivacyTiles() {
    return [
      SwitchListTile(
        title: const Text('Mode Furtif'),
        subtitle: const Text('Masquer l\'application et les notifications'),
        value: _stealthMode,
        secondary: const Icon(Icons.visibility_off),
        onChanged: (value) {
          setState(() => _stealthMode = value);
          _saveSetting('stealth_mode', value);
          _showSavedSnack('Mode furtif ${value ? 'activé' : 'désactivé'}');
        },
      ),
      SwitchListTile(
        title: const Text('Suppression Auto des Preuves'),
        subtitle: Text('Supprimer automatiquement après $_evidenceRetentionDays jours'),
        value: _autoDeleteEvidence,
        secondary: const Icon(Icons.delete_forever),
        onChanged: (value) {
          setState(() => _autoDeleteEvidence = value);
          _saveSetting('auto_delete_evidence', value);
          _showSavedSnack('Suppression auto ${value ? 'activée' : 'désactivée'}');
        },
      ),
      ListTile(
        leading: const Icon(Icons.schedule),
        title: const Text('Rétention des Preuves'),
        subtitle: Text('$_evidenceRetentionDays jours'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      Slider(
        value: _evidenceRetentionDays.toDouble(),
        min: 1,
        max: 90,
        divisions: 89,
        label: '$_evidenceRetentionDays',
        onChanged: (value) {
          setState(() => _evidenceRetentionDays = value.round());
        },
        onChangeEnd: (value) {
          _saveIntSetting('evidence_retention_days', value.round());
          _showSavedSnack('Rétention: ${value.round()} jours');
        },
      ),
      SwitchListTile(
        title: const Text('Historique des Alertes'),
        subtitle: const Text('Conserver l\'historique des alertes'),
        value: _alertHistoryEnabled,
        secondary: const Icon(Icons.history),
        onChanged: (value) {
          setState(() => _alertHistoryEnabled = value);
          _saveSetting('alert_history_enabled', value);
          _showSavedSnack('Historique ${value ? 'activé' : 'désactivé'}');
        },
      ),
      ListTile(
        leading: const Icon(Icons.lock),
        title: const Text('Gestion de la Sécurité'),
        subtitle: const Text('Code PIN, empreinte digitale, schéma'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openAppLockDialog(context),
      ),
      ListTile(
        leading: const Icon(Icons.delete_sweep, color: Colors.red),
        title: const Text('Suppression Rapide des Données'),
        subtitle: const Text('Effacer toutes les données sensibles'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showDeleteDataDialog,
      ),
    ];
  }

  /// Tiles: Connectivité
  List<Widget> _buildConnectivityTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.wifi_off, color: AppConstants.primaryColor),
        title: const Text(
          'Configuration Mode Hors-ligne',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Configurer le comportement en cas de perte de connexion',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _configureOfflineMode,
      ),
      ListTile(
        leading: const Icon(Icons.message, color: AppConstants.primaryColor),
        title: const Text(
          'Message SOS Personnalisé',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: Text(
          _customSosMessage.isEmpty 
              ? 'Entrez votre message personnalisé' 
              : '${_customSosMessage.substring(0, _customSosMessage.length > 30 ? 30 : _customSosMessage.length)}...',
          style: const TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _configureSosMessage,
      ),
      ListTile(
        leading: const Icon(Icons.sync, color: AppConstants.primaryColor),
        title: const Text(
          'Synchronisation des Preuves',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Configurer l\'envoi automatique des preuves',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _configureSyncSettings,
      ),
    ];
  }

  /// Tiles: Langue & Accessibilité
  List<Widget> _buildLanguageAccessibilityTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.language, color: AppConstants.primaryColor),
        title: const Text(
          'Langue de l\'Application',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: Text(
          _getLanguageName(_selectedLanguage),
          style: const TextStyle(color: AppConstants.blackColor),
        ),
        trailing: DropdownButton<String>(
          value: _selectedLanguage,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedLanguage = v);
            _saveStringSetting('selected_language', v);
            _showSavedSnack('Langue: ${_getLanguageName(v)}');
          },
          items: const [
            DropdownMenuItem(value: 'fr', child: Text('Français')),
            DropdownMenuItem(value: 'sus', child: Text('Soussou')),
            DropdownMenuItem(value: 'ff', child: Text('Peulh')),
            DropdownMenuItem(value: 'mlq', child: Text('Malinké')),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.text_fields, color: AppConstants.primaryColor),
        title: const Text(
          'Taille du Texte',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: Text(
          _getTextSizeName(_textSize),
          style: const TextStyle(color: AppConstants.blackColor),
        ),
        trailing: DropdownButton<String>(
          value: _textSize,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _textSize = v);
            _saveStringSetting('text_size', v);
            _showSavedSnack('Taille du texte: ${_getTextSizeName(v)}');
          },
          items: const [
            DropdownMenuItem(value: 'small', child: Text('Petit')),
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'large', child: Text('Grand')),
            DropdownMenuItem(value: 'xlarge', child: Text('Très Grand')),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.contrast, color: AppConstants.primaryColor),
        title: const Text(
          'Configuration d\'Accessibilité',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Contraste, lecture vocale, mode sombre',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _configureAccessibility,
      ),
    ];
  }

  /// Tiles: Localisation & Alertes
  List<Widget> _buildLocationAlertsTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.gps_fixed, color: AppConstants.primaryColor),
        title: const Text(
          'Configuration GPS',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Paramètres de localisation et fréquence',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _configureGpsSettings,
      ),
      ListTile(
        leading: const Icon(Icons.notifications, color: AppConstants.primaryColor),
        title: const Text(
          'Configuration des Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: Text(
          _getNotificationTypeName(_notificationType),
          style: const TextStyle(color: AppConstants.blackColor),
        ),
        trailing: DropdownButton<String>(
          value: _notificationType,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _notificationType = v);
            _saveStringSetting('notification_type', v);
            _showSavedSnack('Notifications: ${_getNotificationTypeName(v)}');
          },
          items: const [
            DropdownMenuItem(value: 'push', child: Text('Notifications Push')),
            DropdownMenuItem(value: 'sms', child: Text('SMS')),
            DropdownMenuItem(value: 'both', child: Text('Push + SMS')),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.contacts, color: AppConstants.primaryColor),
        title: const Text(
          'Gérer les Contacts',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Ajouter/retirer des contacts de confiance',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.push(AppConstants.routeVictimContacts),
      ),
    ];
  }

  /// Tiles: Compte & Utilisation
  List<Widget> _buildAccountUsageTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.person),
        title: const Text('Pseudo'),
        subtitle: Text(_userPseudo.isEmpty ? 'Votre nom d\'utilisateur' : _userPseudo),
        trailing: const Icon(Icons.edit),
        onTap: () async {
          final controller = TextEditingController(text: _userPseudo);
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Modifier le pseudo'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Entrez votre pseudo'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _userPseudo = controller.text.trim());
                    _saveStringSetting('user_pseudo', _userPseudo);
                    Navigator.of(ctx).pop();
                    _showSavedSnack('Pseudo mis à jour');
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.language),
        title: const Text('Langue d\'Utilisation'),
        subtitle: Text(_getLanguageName(_userLanguage)),
        trailing: DropdownButton<String>(
          value: _userLanguage,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _userLanguage = v);
            _saveStringSetting('user_language', v);
            _showSavedSnack('Langue d\'utilisation: ${_getLanguageName(v)}');
          },
          items: const [
            DropdownMenuItem(value: 'fr', child: Text('Français')),
            DropdownMenuItem(value: 'sus', child: Text('Soussou')),
            DropdownMenuItem(value: 'ff', child: Text('Peulh')),
            DropdownMenuItem(value: 'mlq', child: Text('Malinké')),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.lock),
        title: const Text('Changer le Code PIN'),
        subtitle: const Text('Modifier votre code de sécurité'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openAppLockDialog(context),
      ),
      ListTile(
        leading: const Icon(Icons.privacy_tip),
        title: const Text('Politique de Confidentialité'),
        subtitle: const Text('Lire nos conditions d\'utilisation'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showPrivacyPolicy,
      ),
      ListTile(
        leading: const Icon(Icons.delete_forever_outlined, color: Colors.orange),
        title: const Text('Droit à l\'Oubli'),
        subtitle: const Text('Demander la suppression de vos données'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showRightToForgetDialog,
      ),
      ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text('Supprimer le Compte'),
        subtitle: const Text('Supprimer définitivement votre compte'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showDeleteAccountDialog,
      ),
    ];
  }

  /// Tiles: Techniques & Aide
  List<Widget> _buildTechnicalHelpTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.info),
        title: const Text('Version de l\'Application'),
        subtitle: Text(_appVersion),
      ),
      SwitchListTile(
        title: const Text('Mises à Jour Automatiques'),
        subtitle: const Text('Télécharger automatiquement les mises à jour'),
        value: _autoUpdates,
        secondary: const Icon(Icons.system_update),
        onChanged: (value) {
          setState(() => _autoUpdates = value);
          _saveSetting('auto_updates', value);
          _showSavedSnack('Mises à jour auto ${value ? 'activées' : 'désactivées'}');
        },
      ),
      ListTile(
        leading: const Icon(Icons.school),
        title: const Text('Tutoriel d\'Utilisation'),
        subtitle: const Text('Apprendre à utiliser l\'application'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showTutorial,
      ),
      ListTile(
        leading: const Icon(Icons.support_agent),
        title: const Text('Contacter l\'ONG'),
        subtitle: const Text('Obtenir de l\'aide et du support'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _contactONG,
      ),
    ];
  }

  



  

  /// Header informatif
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.settings,
            size: 48,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'Configuration de l\'Application',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.blackColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Personnalisez votre expérience et configurez les paramètres de sécurité selon vos besoins.',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.blackColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// En-tête de section simple (MD3)
  Widget _buildSectionHeader(String title, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: AppConstants.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.w700,
          color: AppConstants.blackColor,
        ),
      ),
    );
  }

  void _showSavedSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppConstants.successColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Méthodes de configuration fonctionnelles
  Future<void> _configureOfflineMode() async {
    _showSavedSnack('Configuration mode hors-ligne - Fonctionnalité en développement');
  }

  Future<void> _configureSosMessage() async {
    final controller = TextEditingController(text: _customSosMessage);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Message SOS Personnalisé',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Créez un message personnalisé qui sera envoyé avec vos alertes d\'urgence.',
              style: TextStyle(color: AppConstants.blackColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Entrez votre message personnalisé',
                labelText: 'Message SOS',
                labelStyle: TextStyle(color: AppConstants.blackColor),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 160,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _customSosMessage = controller.text.trim());
              _saveStringSetting('custom_sos_message', _customSosMessage);
              Navigator.of(ctx).pop();
              _showSavedSnack('Message SOS mis à jour');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.whiteColor,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _configureSyncSettings() async {
    _showSavedSnack('Configuration synchronisation - Fonctionnalité en développement');
  }

  Future<void> _configureAccessibility() async {
    _showSavedSnack('Configuration accessibilité - Fonctionnalité en développement');
  }

  Future<void> _configureGpsSettings() async {
    _showSavedSnack('Configuration GPS - Fonctionnalité en développement');
  }

  

  /// Bouton de sauvegarde
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppConstants.whiteColor),
                  SizedBox(width: 12),
                  Text(
                    'Paramètres sauvegardés avec succès',
                    style: TextStyle(color: AppConstants.whiteColor),
                  ),
                ],
              ),
              backgroundColor: AppConstants.successColor,
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: AppConstants.whiteColor, size: 24),
            SizedBox(width: 12),
            Text(
              'Sauvegarder les Paramètres',
              style: TextStyle(
                color: AppConstants.whiteColor,
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
  // Méthodes utilitaires
  String _getLanguageName(String code) {
    switch (code) {
      case 'fr': return 'Français';
      case 'sus': return 'Soussou';
      case 'ff': return 'Peulh';
      case 'mlq': return 'Malinké';
      default: return 'Français';
    }
  }

  String _getTextSizeName(String size) {
    switch (size) {
      case 'small': return 'Petit';
      case 'normal': return 'Normal';
      case 'large': return 'Grand';
      case 'xlarge': return 'Très Grand';
      default: return 'Normal';
    }
  }

  String _getNotificationTypeName(String type) {
    switch (type) {
      case 'push': return 'Notifications Push';
      case 'sms': return 'SMS';
      case 'both': return 'Push + SMS';
      default: return 'Notifications Push';
    }
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suppression des Données'),
        content: const Text(
          'Cette action supprimera toutes les données sensibles de l\'application (preuves, historique, contacts). Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteAllData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    try {
      // Supprimer les données sensibles
      await StorageService.instance.remove('evidence_files');
      await StorageService.instance.remove('alert_history');
      await StorageService.instance.remove('contacts');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Données supprimées avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Politique de Confidentialité'),
        content: const SingleChildScrollView(
          child: Text(
            'Guinemali s\'engage à protéger votre vie privée. Vos données sont chiffrées et stockées de manière sécurisée. Nous ne partageons jamais vos informations personnelles avec des tiers sans votre consentement explicite.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showRightToForgetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Droit à l\'Oubli'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Conformément au RGPD, vous avez le droit de demander la suppression de vos données personnelles.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Cette demande entraînera :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Suppression de votre compte'),
              Text('• Suppression de toutes vos données personnelles'),
              Text('• Suppression de l\'historique des alertes'),
              Text('• Suppression des preuves enregistrées'),
              SizedBox(height: 16),
              Text(
                'Cette action est irréversible et prendra effet dans les 30 jours.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _requestRightToForget();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Demander la Suppression', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRightToForget() async {
    try {
      // Simuler l'envoi de la demande
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de suppression envoyée. Vous recevrez une confirmation par email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi de la demande: $e')),
        );
      }
    }
  }

  // Nouveaux widgets

  

  

  

  
}

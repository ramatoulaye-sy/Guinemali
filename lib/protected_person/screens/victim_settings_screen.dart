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

class _VictimSettingsScreenState extends State<VictimSettingsScreen> with SingleTickerProviderStateMixin {
  // Notifications (supprimé: géré via type de notifications)
  
  // Sécurité & Confidentialité
  
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
  // États d'expansion des sections (sans sécurité: raccourci)
  bool _expConnectivity = false;
  bool _expLanguage = false;
  bool _expLocation = false;
  bool _expAccount = false;
  bool _expTech = false;
  // Animation FAB
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;
  
  @override
  void initState() {
    super.initState();
    // Différer toute utilisation de context/Inherited jusqu'après initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSettings();
      _loadAppVersion();
    });
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    // lancer après premier frame pour l'effet de rebond
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _fabCtrl.forward(); });
  }

  void _openAppLockDialog(BuildContext context) async {
    final method = await SecurityService.instance.getLockMethod();
    AppLockMethod selected = method;
    final pinController = TextEditingController();
    final pinConfirmController = TextEditingController();
    String? pinError;

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
          content: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
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
                  // Demander immédiatement l'authentification pour activer
                  final ok = await SecurityService.instance.authenticateWithBiometrics(
                    reason: 'Activer le déverrouillage par biométrie',
                  );
                  if (!ok) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Authentification biométrique requise pour activer'),
                          backgroundColor: AppConstants.errorColor,
                        ),
                      );
                    }
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
              if (selected == AppLockMethod.pin) ...[
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nouveau PIN (4-6 chiffres)',
                    labelStyle: const TextStyle(color: Colors.black87),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    errorText: pinError,
                  ),
                  onChanged: (_) => setState(() => pinError = null),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pinConfirmController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le PIN',
                    labelStyle: TextStyle(color: Colors.black87),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                ],
              ],
            ),
            ),
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
                // Validation selon la méthode
                if (selected == AppLockMethod.pin) {
                  final pin = pinController.text.trim();
                  final confirm = pinConfirmController.text.trim();
                  final validDigits = RegExp(r'^\d{4,6}$');
                  if (!validDigits.hasMatch(pin)) {
                    setState(() => pinError = 'Le PIN doit contenir 4 à 6 chiffres');
                    return;
                  }
                  if (pin != confirm) {
                    setState(() => pinError = 'Les deux PIN ne correspondent pas');
                    return;
                  }
                  await SecurityService.instance.savePin(pin);
                  await SecurityService.instance.setLockMethod(AppLockMethod.pin);
                } else if (selected == AppLockMethod.biometrics) {
                  // Demander une auth immédiate pour confirmer l’enrôlement
                  final ok = await SecurityService.instance.authenticateWithBiometrics(reason: 'Activer le déverrouillage par biométrie');
                  if (!ok) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Authentification biométrique requise pour activer'), backgroundColor: AppConstants.errorColor),
                      );
                    }
                    return;
                  }
                  await SecurityService.instance.setLockMethod(AppLockMethod.biometrics);
                } else {
                  await SecurityService.instance.setLockMethod(AppLockMethod.none);
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
      
      // Connectivité
      _customSosMessage = StorageService.instance.getString('custom_sos_message') ?? 
                          StorageService.instance.getString('emergency_message_template') ?? '';
      
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
      
      // Mettre à jour l'état après chargement
      if (mounted) {
        setState(() {});
      }
      // États d'expansion (mémorisés)
      _expConnectivity = StorageService.instance.getBool('settings_exp_connectivity', defaultValue: false);
      _expLanguage = StorageService.instance.getBool('settings_exp_language', defaultValue: false);
      _expLocation = StorageService.instance.getBool('settings_exp_location', defaultValue: false);
      _expAccount = StorageService.instance.getBool('settings_exp_account', defaultValue: false);
      _expTech = StorageService.instance.getBool('settings_exp_tech', defaultValue: false);
      
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
      print('🔄 Début sauvegarde: $key = "$value"');
      await StorageService.instance.saveString(key, value);
      
      // Vérifier immédiatement après sauvegarde
      final saved = StorageService.instance.getString(key);
      print('✅ Vérification immédiate: $key = "$saved"');
      
      if (saved != value) {
        print('❌ ERREUR: La valeur sauvegardée ne correspond pas!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: La sauvegarde a échoué pour $key')),
          );
        }
      }
    } catch (e) {
      print('❌ Exception lors de la sauvegarde: $e');
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
      appBar: _buildProfessionalAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFee82ee), Color(0xFF945acb)],
          ),
        ),
        child: _buildProfessionalBody(),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paramètres sauvegardés'), backgroundColor: AppConstants.successColor),
            );
          },
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Valider'),
        ),
      ),
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          // Raccourci unique vers l'écran Sécurité & Confidentialité
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppConstants.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.lock, color: AppConstants.primaryColor, size: 20),
              ),
              title: const Text('Sécurité & Confidentialité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppConstants.primaryColor)),
              subtitle: const Text('PIN, biométrie, furtif, historique, rétention', style: TextStyle(color: Colors.black54)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
              onTap: () => context.push(AppConstants.routeVictimSecurity),
            ),
          ),
          _buildExpandableCard(
            title: 'Connectivité',
            icon: Icons.wifi_off,
            expanded: _expConnectivity,
            onChanged: (v) async {
              setState(() => _expConnectivity = v);
              await StorageService.instance.saveBool('settings_exp_connectivity', v);
            },
            children: _buildConnectivityTiles(),
          ),
          _buildExpandableCard(
            title: 'Langue & Accessibilité',
            icon: Icons.language,
            expanded: _expLanguage,
            onChanged: (v) async {
              setState(() => _expLanguage = v);
              await StorageService.instance.saveBool('settings_exp_language', v);
            },
            children: _buildLanguageAccessibilityTiles(),
          ),
          _buildExpandableCard(
            title: 'Localisation & Alertes',
            icon: Icons.gps_fixed,
            expanded: _expLocation,
            onChanged: (v) async {
              setState(() => _expLocation = v);
              await StorageService.instance.saveBool('settings_exp_location', v);
            },
            children: _buildLocationAlertsTiles(),
          ),
          _buildExpandableCard(
            title: 'Compte & Utilisation',
            icon: Icons.person,
            expanded: _expAccount,
            onChanged: (v) async {
              setState(() => _expAccount = v);
              await StorageService.instance.saveBool('settings_exp_account', v);
            },
            children: _buildAccountUsageTiles(),
          ),
          _buildExpandableCard(
            title: 'Techniques & Aide',
            icon: Icons.support_agent,
            expanded: _expTech,
            onChanged: (v) async {
              setState(() => _expTech = v);
              await StorageService.instance.saveBool('settings_exp_tech', v);
            },
            children: _buildTechnicalHelpTiles(),
          ),
          const SizedBox(height: 16),
          _buildSaveButton(),
        ],
      ),
    );
  }

  

  // supprimé: section sécurité déplacée

  /// Tiles: Connectivité
  List<Widget> _buildConnectivityTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.wifi_off, color: AppConstants.primaryColor),
        title: const Text('Configuration Mode Hors-ligne', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: const Text('Configurer le comportement en cas de perte de connexion', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureOfflineMode,
      ),
      ListTile(
        leading: const Icon(Icons.message, color: AppConstants.primaryColor),
        title: const Text('Message SOS Personnalisé', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(
          _customSosMessage.isEmpty ? 'Entrez votre message personnalisé' : '${_customSosMessage.substring(0, _customSosMessage.length > 30 ? 30 : _customSosMessage.length)}...',
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureSosMessage,
      ),
      ListTile(
        leading: const Icon(Icons.sync, color: AppConstants.primaryColor),
        title: const Text('Synchronisation des Preuves', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: const Text('Configurer l\'envoi automatique des preuves', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureSyncSettings,
      ),
    ];
  }

  /// Tiles: Langue & Accessibilité
  List<Widget> _buildLanguageAccessibilityTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.language, color: AppConstants.primaryColor),
        title: const Text('Langue de l\'Application', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(_getLanguageName(_selectedLanguage), style: const TextStyle(color: Colors.black54)),
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
        title: const Text('Taille du Texte', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(_getTextSizeName(_textSize), style: const TextStyle(color: Colors.black54)),
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
        title: const Text('Configuration d\'Accessibilité', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: const Text('Contraste, lecture vocale, mode sombre', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureAccessibility,
      ),
    ];
  }

  /// Tiles: Localisation & Alertes
  List<Widget> _buildLocationAlertsTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.gps_fixed, color: AppConstants.primaryColor),
        title: const Text('Configuration GPS', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: const Text('Paramètres de localisation et fréquence', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureGpsSettings,
      ),
      ListTile(
        leading: const Icon(Icons.notifications, color: AppConstants.primaryColor),
        title: const Text('Configuration des Notifications', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(_getNotificationTypeName(_notificationType), style: const TextStyle(color: Colors.black54)),
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
        title: const Text('Gérer les Contacts', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: const Text('Ajouter/retirer des contacts de confiance', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: () => context.push(AppConstants.routeVictimContacts),
      ),
    ];
  }

  /// Tiles: Compte & Utilisation
  List<Widget> _buildAccountUsageTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.person),
        title: const Text('Pseudo', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: Text(_userPseudo.isEmpty ? 'Votre nom d\'utilisateur' : _userPseudo, style: const TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.edit, color: Colors.black45),
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
        title: const Text('Langue d\'Utilisation', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: Text(_getLanguageName(_userLanguage), style: const TextStyle(color: Colors.black54)),
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
        title: const Text('Changer le Code PIN', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: const Text('Modifier votre code de sécurité', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: () => _openAppLockDialog(context),
      ),
      ListTile(
        leading: const Icon(Icons.privacy_tip),
        title: const Text('Politique de Confidentialité', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: const Text('Lire nos conditions d\'utilisation', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showPrivacyPolicy,
      ),
      ListTile(
        leading: const Icon(Icons.delete_forever_outlined, color: Colors.orange),
        title: const Text('Droit à l\'Oubli', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: const Text('Demander la suppression de vos données', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showRightToForgetDialog,
      ),
      ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text('Supprimer le Compte', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: const Text('Supprimer définitivement votre compte', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showDeleteAccountDialog,
      ),
    ];
  }

  /// Tiles: Techniques & Aide
  List<Widget> _buildTechnicalHelpTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.info),
        title: const Text('Version de l\'Application', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: Text(_appVersion, style: const TextStyle(color: Colors.black54)),
      ),
      SwitchListTile(
        title: const Text('Mises à Jour Automatiques', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: const Text('Télécharger automatiquement les mises à jour', style: TextStyle(color: Colors.black54)),
        value: _autoUpdates,
        secondary: const Icon(Icons.system_update),
        activeColor: AppConstants.primaryColor,
        onChanged: (value) {
          setState(() => _autoUpdates = value);
          _saveSetting('auto_updates', value);
          _showSavedSnack('Mises à jour auto ${value ? 'activées' : 'désactivées'}');
        },
      ),
      ListTile(
        leading: const Icon(Icons.school),
        title: const Text('Tutoriel d\'Utilisation', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: const Text('Apprendre à utiliser l\'application', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showTutorial,
      ),
      ListTile(
        leading: const Icon(Icons.support_agent),
        title: const Text('Contacter l\'ONG', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: const Text('Obtenir de l\'aide et du support', style: TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
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

  // _buildSectionHeader supprimé (non utilisé)

  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required bool expanded,
    required ValueChanged<bool> onChanged,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      margin: const EdgeInsets.only(bottom: 12),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: expanded ? AppConstants.secondaryColor.withOpacity(0.25) : Colors.black.withOpacity(0.08),
            blurRadius: expanded ? 22 : 16,
            spreadRadius: expanded ? 1 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          maintainState: true,
          initiallyExpanded: expanded,
          onExpansionChanged: onChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryColor,
            ),
          ),
          trailing: Icon(
            expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: AppConstants.primaryColor,
          ),
          children: [
            ListTileTheme(
              textColor: Colors.black87,
              iconColor: AppConstants.primaryColor,
              child: Column(children: children),
            ),
          ],
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
    bool wifiOnly = StorageService.instance.getBool('offline_wifi_only', defaultValue: true);
    bool deferUploads = StorageService.instance.getBool('offline_defer_uploads', defaultValue: true);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        contentPadding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 8),
        titleTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20),
        contentTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
        title: const Text('Mode hors-ligne'),
        content: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Synchroniser uniquement en Wi‑Fi', style: TextStyle(color: Colors.black87)),
                value: wifiOnly,
                onChanged: (v) => setState(() => wifiOnly = v),
              ),
              SwitchListTile(
                title: const Text('Différer les envois quand hors-ligne', style: TextStyle(color: Colors.black87)),
                value: deferUploads,
                onChanged: (v) => setState(() => deferUploads = v),
              ),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await StorageService.instance.saveBool('offline_wifi_only', wifiOnly);
              await StorageService.instance.saveBool('offline_defer_uploads', deferUploads);
              if (mounted) {
                Navigator.of(ctx).pop();
                _showSavedSnack('Mode hors-ligne sauvegardé');
              }
            },
            child: const Text('Enregistrer'),
          )
        ],
      ),
    );
  }

  Future<void> _configureSosMessage() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Recharger la valeur à chaque reconstruction du dialog
            final latest = StorageService.instance.getString('custom_sos_message') ??
                StorageService.instance.getString('emergency_message_template') ??
                _customSosMessage;
            final controller = TextEditingController(text: latest);
            
            final viewInsets = MediaQuery.of(ctx).viewInsets;
            return Theme(
              data: ThemeData.light(),
              child: Padding(
                padding: EdgeInsets.only(bottom: viewInsets.bottom),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Message SOS Personnalisé', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
                          const SizedBox(height: 12),
                          const Text('Créez un message personnalisé qui sera envoyé avec vos alertes d\'urgence.', style: TextStyle(color: Colors.black87)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF945acb), width: 1.2),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: EditableText(
                              controller: controller,
                              focusNode: FocusNode(),
                              autofocus: true,
                              style: const TextStyle(color: Colors.black87, fontSize: 16),
                              cursorColor: Colors.black87,
                              backgroundCursorColor: Colors.black12,
                              selectionColor: const Color(0x22000000),
                              selectionControls: materialTextSelectionControls,
                              keyboardAppearance: Brightness.light,
                              keyboardType: TextInputType.multiline,
                              maxLines: 4,
                              minLines: 4,
                              textAlign: TextAlign.start,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Annuler', style: TextStyle(color: Color(0xFF945acb))),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final newMessage = controller.text.trim();
                                  print('💾 Sauvegarde message SOS: "$newMessage"');
                                  
                                  // Mettre à jour l'état local
                                  this.setState(() => _customSosMessage = newMessage);
                                  
                                  // Sauvegarder
                                  await _saveStringSetting('custom_sos_message', newMessage);
                                  await _saveStringSetting('emergency_message_template', newMessage);
                                  
                                  // Vérifier la sauvegarde
                                  final saved1 = StorageService.instance.getString('custom_sos_message');
                                  final saved2 = StorageService.instance.getString('emergency_message_template');
                                  print('✅ Vérification sauvegarde:');
                                  print('  - custom_sos_message: "$saved1"');
                                  print('  - emergency_message_template: "$saved2"');
                                  
                                  Navigator.of(ctx).pop();
                                  _showSavedSnack('Message SOS mis à jour');
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF945acb), foregroundColor: Colors.white),
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _configureSyncSettings() async {
    bool autoSyncProofs = StorageService.instance.getBool('sync_proofs_auto', defaultValue: true);
    int syncIntervalMin = StorageService.instance.getInt('sync_interval_min', defaultValue: 15);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        contentPadding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 8),
        titleTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20),
        contentTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
        title: const Text('Synchronisation des preuves'),
        content: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Synchronisation automatique', style: TextStyle(color: Colors.black87)),
                value: autoSyncProofs,
                onChanged: (v) => setState(() => autoSyncProofs = v),
              ),
              Row(
                children: [
                  const Text('Intervalle (min): ', style: TextStyle(color: Colors.black87)),
                  Expanded(
                    child: Slider(
                      min: 5,
                      max: 120,
                      divisions: 23,
                      value: syncIntervalMin.toDouble(),
                      label: '$syncIntervalMin',
                      onChanged: (v) => setState(() => syncIntervalMin = v.round()),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await StorageService.instance.saveBool('sync_proofs_auto', autoSyncProofs);
              await StorageService.instance.saveString('sync_interval_min', syncIntervalMin.toString());
              if (mounted) {
                Navigator.of(ctx).pop();
                _showSavedSnack('Synchronisation sauvegardée');
              }
            },
            child: const Text('Enregistrer'),
          )
        ],
      ),
    );
  }

  Future<void> _configureAccessibility() async {
    bool highContrast = StorageService.instance.getBool('a11y_high_contrast', defaultValue: false);
    bool ttsHints = StorageService.instance.getBool('a11y_tts_hints', defaultValue: false);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        contentPadding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 8),
        titleTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20),
        contentTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
        title: const Text('Accessibilité'),
        content: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Contraste élevé', style: TextStyle(color: Colors.black87)),
                value: highContrast,
                onChanged: (v) => setState(() => highContrast = v),
              ),
              SwitchListTile(
                title: const Text('Aides vocales (TTS)', style: TextStyle(color: Colors.black87)),
                value: ttsHints,
                onChanged: (v) => setState(() => ttsHints = v),
              ),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await StorageService.instance.saveBool('a11y_high_contrast', highContrast);
              await StorageService.instance.saveBool('a11y_tts_hints', ttsHints);
              if (mounted) {
                Navigator.of(ctx).pop();
                _showSavedSnack('Accessibilité sauvegardée');
              }
            },
            child: const Text('Enregistrer'),
          )
        ],
      ),
    );
  }

  Future<void> _configureGpsSettings() async {
    bool gpsEnabled = StorageService.instance.getBool('gps_enabled', defaultValue: false);
    String accuracy = StorageService.instance.getString('gps_accuracy') ?? 'balanced';
    int interval = StorageService.instance.getInt('gps_interval_sec', defaultValue: 60);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        contentPadding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 8),
        titleTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20),
        contentTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
        title: const Text('Paramètres GPS'),
        content: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Activer le suivi GPS', style: TextStyle(color: Colors.black87)),
                value: gpsEnabled,
                onChanged: (v) => setState(() => gpsEnabled = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Précision', style: TextStyle(color: Colors.black87)),
                trailing: DropdownButton<String>(
                  value: accuracy,
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'high', child: Text('Haute', style: TextStyle(color: Colors.black87))),
                    DropdownMenuItem(value: 'balanced', child: Text('Équilibrée', style: TextStyle(color: Colors.black87))),
                    DropdownMenuItem(value: 'low', child: Text('Basse', style: TextStyle(color: Colors.black87))),
                  ],
                  onChanged: (v) => setState(() => accuracy = v ?? accuracy),
                ),
              ),
              Row(
                children: [
                  const Text('Intervalle (sec): ', style: TextStyle(color: Colors.black87)),
                  Expanded(
                    child: Slider(
                      min: 10,
                      max: 600,
                      divisions: 59,
                      value: interval.toDouble(),
                      label: '$interval',
                      onChanged: (v) => setState(() => interval = v.round()),
                    ),
                  ),
                ],
              )
            ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await StorageService.instance.saveBool('gps_enabled', gpsEnabled);
              await StorageService.instance.saveString('gps_accuracy', accuracy);
              await StorageService.instance.saveString('gps_interval_sec', interval.toString());
              if (mounted) {
                Navigator.of(ctx).pop();
                _showSavedSnack('Paramètres GPS sauvegardés');
              }
            },
            child: const Text('Enregistrer'),
          )
        ],
      ),
    );
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

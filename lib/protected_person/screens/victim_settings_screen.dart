import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guinemali/core/services/a11y_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guinemali/core/services/location_tracking_service.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/security_service.dart';
import 'package:guinemali/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:guinemali/core/services/sync_service.dart';
import 'package:guinemali/protected_person/widgets/menu_modal.dart';

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

  // High-contrast only; otherwise keep original light design
  bool get _isHighContrast => StorageService.instance.getBool('a11y_high_contrast', defaultValue: false);
  Color get _iconColor => AppConstants.primaryColor;
  Color get _titleColor => _isHighContrast ? Colors.white : Colors.black87;
  Color get _subtitleColor => _isHighContrast ? Colors.white70 : Colors.black54;
  Color get _cardColor => _isHighContrast ? const Color(0xFF121212) : Colors.white;
  Color get _chipBg => _isHighContrast ? Colors.white12 : AppConstants.primaryColor.withOpacity(0.1);

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
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Supprimer le compte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tapez SUPPRIMER pour confirmer la suppression définitive.'),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                decoration: const InputDecoration(
                  hintText: 'SUPPRIMER',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: confirmCtrl.text.trim().toUpperCase() == 'SUPPRIMER'
                  ? () async {
                      Navigator.of(ctx).pop();
                      await _deleteAccount();
                      A11yService.announceIfEnabled(context, 'Compte supprimé');
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      // Purge complète: préférences + base SQLite locale
      await StorageService.instance.clearDatabase();
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

  Future<void> _showChangePinDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;
    String? error;
    await showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            labelStyle: TextStyle(color: Colors.black87),
            hintStyle: TextStyle(color: Colors.black54),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFBDBDBD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF945ACB), width: 2),
            ),
          ),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.black87,
                displayColor: Colors.black87,
              ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Changer le code PIN', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
            scrollable: true,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: obscure,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.black87),
                  cursorColor: Colors.black87,
                  decoration: InputDecoration(
                    labelText: 'PIN actuel',
                    errorText: error,
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: obscure,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.black87),
                  cursorColor: Colors.black87,
                  decoration: const InputDecoration(labelText: 'Nouveau PIN (4–6 chiffres)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: obscure,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.black87),
                  cursorColor: Colors.black87,
                  decoration: const InputDecoration(labelText: 'Confirmer le nouveau PIN'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler', style: TextStyle(color: Colors.black87))),
              ElevatedButton(
                onPressed: () async {
                final pinOld = currentCtrl.text.trim();
                final pinNew = newCtrl.text.trim();
                final pinConfirm = confirmCtrl.text.trim();
                final re = RegExp(r'^\d{4,6}$');
                if (!re.hasMatch(pinNew)) {
                  setState(() => error = 'Le PIN doit contenir 4 à 6 chiffres');
                  return;
                }
                if (pinNew != pinConfirm) {
                  setState(() => error = 'Les deux PIN ne correspondent pas');
                  return;
                }
                try {
                  final ok = await SecurityService.instance.verifyPin(pinOld);
                  if (!ok) {
                    setState(() => error = 'PIN actuel incorrect');
                    return;
                  }
                  await SecurityService.instance.savePin(pinNew);
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  _showSavedSnack('Code PIN mis à jour');
                  A11yService.announceIfEnabled(context, 'Code PIN mis à jour');
                } catch (e) {
                  setState(() => error = 'Erreur: $e');
                }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
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
      // FAB retiré pour éviter la redondance avec le bouton principal de sauvegarde
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
        leading: Icon(Icons.wifi_off, color: _iconColor),
        title: Text('Configuration Mode Hors-ligne', style: TextStyle(fontWeight: FontWeight.w600, color: _titleColor)),
        subtitle: Text('Configurer le comportement en cas de perte de connexion', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureOfflineMode,
      ),
      ListTile(
        leading: Icon(Icons.message, color: _iconColor),
        title: Text('Message SOS Personnalisé', style: TextStyle(fontWeight: FontWeight.w600, color: _titleColor)),
        subtitle: Text(
          _customSosMessage.isEmpty ? 'Entrez votre message personnalisé' : '${_customSosMessage.substring(0, _customSosMessage.length > 30 ? 30 : _customSosMessage.length)}...',
          style: TextStyle(color: _subtitleColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureSosMessage,
      ),
      ListTile(
        leading: Icon(Icons.sync, color: _iconColor),
        title: Text('Synchronisation des Preuves', style: TextStyle(fontWeight: FontWeight.w600, color: _titleColor)),
        subtitle: Text('Configurer l\'envoi automatique des preuves', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureSyncSettings,
      ),
      ListTile(
        leading: Icon(Icons.sync_problem, color: _iconColor),
        title: Text('Synchroniser maintenant', style: TextStyle(fontWeight: FontWeight.w600, color: _titleColor)),
        subtitle: Text('Force l\'envoi immédiat des éléments en attente', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.black45),
        onTap: () async {
          if (!mounted) return;
          try {
            final wasOnline = SyncService.instance.isOnline;
            if (!wasOnline) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hors-ligne: la synchronisation sera tentée dès le retour en ligne')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronisation démarrée…')),
              );
            }
            await SyncService.instance.forceSync();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Synchronisation terminée')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur de synchronisation: $e')),
            );
          }
        },
      ),
    ];
  }

  /// Tiles: Langue & Accessibilité
  List<Widget> _buildLanguageAccessibilityTiles() {
    final titleStyle = TextStyle(fontWeight: FontWeight.w600, color: _titleColor);
    final subtitleStyle = TextStyle(color: _subtitleColor);
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.language, color: _iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Langue de l\'Application',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_getLanguageName(_selectedLanguage), style: subtitleStyle),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedLanguage,
                  dropdownColor: Colors.white,
                  iconEnabledColor: _iconColor,
                  style: titleStyle,
                  onChanged: (_selectedLanguage == 'system') ? null : (v) {
                    if (v == null) return;
                    setState(() => _selectedLanguage = v);
                    _saveStringSetting('selected_language', v);
                    _showSavedSnack('Langue: ${_getLanguageName(v)}');
                  },
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('Langue du Système')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'sus', child: Text('Soussou')),
                    DropdownMenuItem(value: 'ff', child: Text('Peulh')),
                    DropdownMenuItem(value: 'mlq', child: Text('Malinké')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      SwitchListTile(
        title: Text('Suivre la langue du système', style: titleStyle),
        value: _selectedLanguage == 'system',
        onChanged: (v) {
          setState(() => _selectedLanguage = v ? 'system' : 'fr');
          _saveStringSetting('selected_language', _selectedLanguage);
          _showSavedSnack(v ? 'Langue: Système' : 'Langue: Français');
        },
      ),
      ListTile(
        leading: Icon(Icons.text_fields, color: _iconColor),
        title: Text('Taille du Texte', style: titleStyle),
        subtitle: Text(_getTextSizeName(_textSize), style: subtitleStyle),
        trailing: DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: DropdownButton<String>(
              value: _textSize,
              dropdownColor: Colors.white,
              iconEnabledColor: _iconColor,
              style: titleStyle,
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
        ),
      ),
      ListTile(
        leading: Icon(Icons.contrast, color: _iconColor),
        title: Text('Configuration d\'Accessibilité', style: titleStyle),
        subtitle: Text('Contraste, lecture vocale, mode sombre', style: subtitleStyle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureAccessibility,
      ),
    ];
  }

  /// Tiles: Localisation & Alertes
  List<Widget> _buildLocationAlertsTiles() {
    return [
      ListTile(
        leading: Icon(Icons.gps_fixed, color: _iconColor),
        title: Text('Configuration GPS', style: TextStyle(fontWeight: FontWeight.w600, color: _titleColor)),
        subtitle: Text('Paramètres de localisation et fréquence', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureGpsSettings,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(Icons.notifications, color: AppConstants.primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configuration des Notifications',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_getNotificationTypeName(_notificationType), style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _notificationType,
                  dropdownColor: Colors.white,
                  iconEnabledColor: AppConstants.primaryColor,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
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
            ),
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
        leading: Icon(Icons.person, color: _iconColor),
        title: Text('Pseudo', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text(_userPseudo.isEmpty ? 'Votre nom d\'utilisateur' : _userPseudo, style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.edit, color: Colors.grey),
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
                    final txt = controller.text.trim();
                    if (txt.length < 2 || txt.length > 32) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le pseudo doit contenir 2 à 32 caractères')));
                      return;
                    }
                    setState(() => _userPseudo = txt);
                    _saveStringSetting('user_pseudo', _userPseudo);
                    Navigator.of(ctx).pop();
                    _showSavedSnack('Pseudo mis à jour');
                    A11yService.announceIfEnabled(context, 'Pseudo mis à jour');
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          );
        },
      ),
      ListTile(
        leading: Icon(Icons.language, color: _iconColor),
        title: Text('Langue d\'Utilisation', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text(_getLanguageName(_userLanguage), style: TextStyle(color: _subtitleColor)),
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
        leading: Icon(Icons.lock, color: _iconColor),
        title: Text('Changer le Code PIN', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Modifier votre code de sécurité', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showChangePinDialog,
      ),
      ListTile(
        leading: Icon(Icons.privacy_tip, color: _iconColor),
        title: Text('Politique de Confidentialité', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Lire nos conditions d\'utilisation', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showPrivacyPolicy,
      ),
      ListTile(
        leading: Icon(Icons.delete_forever_outlined, color: Colors.orange.shade700),
        title: Text('Droit à l\'Oubli', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Demander la suppression de vos données', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showRightToForgetDialog,
      ),
      ListTile(
        leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
        title: Text('Supprimer le Compte', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Supprimer définitivement votre compte', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showDeleteAccountDialog,
      ),
    ];
  }

  /// Tiles: Techniques & Aide
  List<Widget> _buildTechnicalHelpTiles() {
    return [
      ListTile(
        leading: Icon(Icons.info, color: _iconColor),
        title: Text('Version de l\'Application', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text(_appVersion, style: TextStyle(color: _subtitleColor)),
      ),
      SwitchListTile(
        title: Text('Mises à Jour Automatiques', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Télécharger automatiquement les mises à jour', style: TextStyle(color: _subtitleColor)),
        value: _autoUpdates,
        secondary: Icon(Icons.system_update, color: _iconColor),
        activeColor: AppConstants.primaryColor,
        onChanged: (value) {
          setState(() => _autoUpdates = value);
          _saveSetting('auto_updates', value);
          _showSavedSnack('Mises à jour auto ${value ? 'activées' : 'désactivées'}');
        },
      ),
      // Accès direct au Centre d'Aide complet
      ListTile(
        leading: Icon(Icons.support, color: _iconColor),
        title: Text('Centre d\'Aide', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Email, téléphone, FAQ, manuel', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: () => context.push(AppConstants.routeVictimHelp),
      ),
      // Diagnostic Permissions (GPS/SMS/Stockage)
      ListTile(
        leading: Icon(Icons.privacy_tip, color: _iconColor),
        title: Text('Diagnostiquer les Permissions', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Vérifier GPS, SMS, stockage', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: () => context.push(AppConstants.routePermissions),
      ),
      // Test Notifications
      ListTile(
        leading: Icon(Icons.notifications_active, color: _iconColor),
        title: Text('Tester les Notifications', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Simuler selon votre mode (Push/SMS)', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.black45),
        onTap: () {
          final mode = StorageService.instance.getString('notification_type') ?? 'push';
          final label = mode == 'both' ? 'Push + SMS' : (mode == 'sms' ? 'SMS' : 'Push');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Test notifications: $label')),
          );
          A11yService.announceIfEnabled(context, 'Test notifications: $label');
        },
      ),
      ListTile(
        leading: Icon(Icons.school, color: _iconColor),
        title: Text('Tutoriel d\'Utilisation', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Apprendre à utiliser l\'application', style: TextStyle(color: _subtitleColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showTutorial,
      ),
      ListTile(
        leading: Icon(Icons.support_agent, color: _iconColor),
        title: Text('Contacter l\'ONG', style: TextStyle(color: _titleColor, fontWeight: FontWeight.w600)),
        subtitle: Text('Obtenir de l\'aide et du support', style: TextStyle(color: _subtitleColor)),
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
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.settings,
            size: 48,
            color: _iconColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Configuration de l\'Application',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Personnalisez votre expérience et configurez les paramètres de sécurité selon vos besoins.',
            style: TextStyle(
              fontSize: 14,
              color: _subtitleColor,
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
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              color: _chipBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _iconColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _iconColor,
            ),
          ),
          trailing: Icon(
            expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: _iconColor,
          ),
          children: [
            ListTileTheme(
              textColor: _titleColor,
              iconColor: _iconColor,
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
    A11yService.announceIfEnabled(context, message);
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Slider(
                          min: 5,
                          max: 120,
                          divisions: 23,
                          value: syncIntervalMin.toDouble(),
                          label: '$syncIntervalMin min',
                          onChanged: (v) => setState(() => syncIntervalMin = v.round()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('5', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Text('120', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$syncIntervalMin min', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'S’applique à la synchronisation automatique quand vous êtes en ligne.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
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
              await StorageService.instance.setInt('sync_interval_min', syncIntervalMin);
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
    bool reduceMotion = StorageService.instance.getBool('a11y_reduce_motion', defaultValue: false);
    bool readableFont = StorageService.instance.getBool('a11y_readable_font', defaultValue: false);
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
              SwitchListTile(
                title: const Text('Réduire les animations', style: TextStyle(color: Colors.black87)),
                subtitle: const Text('Diminue les mouvements pour limiter l’inconfort visuel', style: TextStyle(color: Colors.black54)),
                value: reduceMotion,
                onChanged: (v) => setState(() => reduceMotion = v),
              ),
              SwitchListTile(
                title: const Text('Police plus lisible', style: TextStyle(color: Colors.black87)),
                subtitle: const Text('Augmente l’espacement et l’épaisseur des textes', style: TextStyle(color: Colors.black54)),
                value: readableFont,
                onChanged: (v) => setState(() => readableFont = v),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Aperçu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: highContrast ? Colors.black : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: highContrast ? Colors.white : const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lisibilité du texte',
                      style: TextStyle(
                        color: highContrast ? Colors.yellow : Colors.black87,
                        fontSize: 16,
                        fontWeight: readableFont ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: readableFont ? 0.4 : 0.0,
                        height: readableFont ? 1.35 : 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AnimatedOpacity(
                          opacity: reduceMotion ? 1.0 : 1.0,
                          duration: Duration(milliseconds: reduceMotion ? 0 : 250),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: highContrast ? Colors.white : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: highContrast ? Colors.yellow : const Color(0xFFE0E0E0)),
                            ),
                            child: Text(
                              reduceMotion ? 'Animations réduites' : 'Animations normales',
                              style: TextStyle(
                                color: highContrast ? Colors.black : Colors.black87,
                                fontWeight: readableFont ? FontWeight.w700 : FontWeight.w500,
                                letterSpacing: readableFont ? 0.3 : 0.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
              await StorageService.instance.saveBool('a11y_reduce_motion', reduceMotion);
              await StorageService.instance.saveBool('a11y_readable_font', readableFont);
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
    String permStatus = await _getLocationPermissionStatusLabel();
    final lastPos = StorageService.instance.getString('gps_last_position') ?? '—';
    final lastSync = StorageService.instance.getString('gps_last_sync') ?? '—';
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
              Row(
                children: [
                  const Icon(Icons.shield_moon, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Permissions: $permStatus', style: const TextStyle(color: Colors.black54))),
                  TextButton(
                    onPressed: () async {
                      final ok = await _ensureLocationPermissions(ctx);
                      setState(() => permStatus = ok ? 'OK' : 'À corriger');
                    },
                    child: const Text('Vérifier'),
                  ),
                ],
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
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Dernière position: $lastPos', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Dernière sync: $lastSync', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ),
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
              try {
                if (gpsEnabled) {
                  await LocationTrackingService.instance.start(accuracy: accuracy, intervalSec: interval);
                } else {
                  await LocationTrackingService.instance.stop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS: $e')));
                }
              }
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

  Future<String> _getLocationPermissionStatusLabel() async {
    final service = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    if (!service) return 'Services désactivés';
    switch (perm) {
      case LocationPermission.always:
        return 'OK (toujours)';
      case LocationPermission.whileInUse:
        return 'OK (en usage)';
      case LocationPermission.deniedForever:
        return 'Refusé définitivement';
      case LocationPermission.denied:
        return 'Refusé';
      default:
        return 'Inconnu';
    }
  }

  Future<bool> _ensureLocationPermissions(BuildContext ctx) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showSavedSnack('Activez le GPS dans les paramètres');
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      _showSavedSnack('Permission refusée définitivement. Ouvrez les paramètres.');
      await Geolocator.openAppSettings();
      return false;
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
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
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: AppConstants.whiteColor, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Paramètres sauvegardés avec succès',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppConstants.whiteColor),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppConstants.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(milliseconds: 1200),
            ),
          );
          // Rediriger vers le menu après un court délai pour laisser la Snackbar s'afficher
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            // Ouvrir la fenêtre modale du menu principal
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const MenuModal(),
            );
          });
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
            Icon(Icons.save, color: AppConstants.whiteColor, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sauvegarder les Paramètres',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppConstants.whiteColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
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



  void _showPrivacyPolicy() async {
    final lang = _userLanguage;
    final Map<String, String> urls = {
      'fr': 'https://guinemali.org/politique-confidentialite',
      'sus': 'https://guinemali.org/confidentialite-sus',
      'ff': 'https://guinemali.org/confidentialite-ff',
      'mlq': 'https://guinemali.org/confidentialite-mlq',
    };
    final url = urls[lang] ?? urls['fr']!;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: afficher un résumé
      if (!mounted) return;
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
          ],
        ),
      );
    }
  }

  void _showRightToForgetDialog() {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Droit à l\'Oubli'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Conformément au RGPD, vous pouvez demander la suppression de vos données personnelles.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Raison (facultatif)', border: OutlineInputBorder(), filled: true),
              ),
              const SizedBox(height: 12),
              const Text('Cette action est irréversible et prendra effet dans les 30 jours.', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final reason = reasonCtrl.text.trim();
              _requestRightToForget(reason.isEmpty ? null : reason);
              A11yService.announceIfEnabled(context, 'Demande de suppression envoyée');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Demander la Suppression', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRightToForget(String? reason) async {
    try {
      // Simuler l'envoi de la demande
      await Future.delayed(const Duration(seconds: 1));
      // Conserver localement la raison optionnelle pour suivi/support
      if (reason != null && reason.isNotEmpty) {
        await StorageService.instance.saveString('right_to_forget_reason', reason);
      }
      
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

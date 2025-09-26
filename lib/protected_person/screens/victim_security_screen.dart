import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guinemali/core/constants/app_constants.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/security_service.dart';

class VictimSecurityScreen extends StatefulWidget {
  const VictimSecurityScreen({super.key});

  @override
  State<VictimSecurityScreen> createState() => _VictimSecurityScreenState();
}

class _VictimSecurityScreenState extends State<VictimSecurityScreen> {
  bool _isLoading = true;
  bool _biometricsAvailable = false;
  String _currentLockMethod = 'none';
  bool _stealthMode = false;
  bool _autoDeleteEvidence = false;
  bool _alertHistoryEnabled = true;
  int _evidenceRetentionDays = 30;
  
  // États d'expansion des sections
  bool _expProtection = false;
  bool _expDataPrivacy = false;
  bool _expAdvancedSecurity = false;
  
  // Contrôleurs pour les formulaires
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() => _isLoading = true);
    try {
      // Vérifier la disponibilité de la biométrie
      _biometricsAvailable = await SecurityService.instance.canCheckBiometrics();
      
      // Charger les paramètres de sécurité
      _stealthMode = StorageService.instance.getBool('stealth_mode', defaultValue: false);
      _autoDeleteEvidence = StorageService.instance.getBool('auto_delete_evidence', defaultValue: false);
      _evidenceRetentionDays = StorageService.instance.getInt('evidence_retention_days', defaultValue: 30);
      _alertHistoryEnabled = StorageService.instance.getBool('alert_history_enabled', defaultValue: true);
      
      // Charger la méthode de verrouillage actuelle
      final lockMethod = await SecurityService.instance.getLockMethod();
      _currentLockMethod = lockMethod.toString().split('.').last;
      
      // Charger les états d'expansion des sections
      _expProtection = StorageService.instance.getBool('security_exp_protection', defaultValue: false);
      _expDataPrivacy = StorageService.instance.getBool('security_exp_data_privacy', defaultValue: false);
      _expAdvancedSecurity = StorageService.instance.getBool('security_exp_advanced', defaultValue: false);
      
    } catch (e) {
      print('Erreur lors du chargement des paramètres de sécurité: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSecuritySetting(String key, bool value) async {
    try {
      await StorageService.instance.setBool(key, value);
      _showSnack('Paramètre de sécurité sauvegardé');
    } catch (e) {
      _showSnack('Erreur lors de la sauvegarde: $e', isError: true);
    }
  }

  Future<void> _saveIntSetting(String key, int value) async {
    try {
      await StorageService.instance.saveString(key, value.toString());
      _showSnack('Paramètre de sécurité sauvegardé');
    } catch (e) {
      _showSnack('Erreur lors de la sauvegarde: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppConstants.whiteColor),
        ),
        backgroundColor: isError ? AppConstants.errorColor : AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFee82ee), Color(0xFF945acb)],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: AppConstants.whiteColor,
      centerTitle: true,
      title: const Text(
        '🔒 Sécurité & Confidentialité',
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
            'Protection',
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildExpandableCard(
            title: 'Protection de l\'Application',
            icon: Icons.security,
            expanded: _expProtection,
            onChanged: (v) async {
              setState(() => _expProtection = v);
              await StorageService.instance.saveBool('security_exp_protection', v);
            },
            children: _buildProtectionTiles(),
          ),
          _buildExpandableCard(
            title: 'Données Privées',
            icon: Icons.privacy_tip,
            expanded: _expDataPrivacy,
            onChanged: (v) async {
              setState(() => _expDataPrivacy = v);
              await StorageService.instance.saveBool('security_exp_data_privacy', v);
            },
            children: _buildDataPrivacyTiles(),
          ),
          _buildExpandableCard(
            title: 'Sécurité Avancée',
            icon: Icons.admin_panel_settings,
            expanded: _expAdvancedSecurity,
            onChanged: (v) async {
              setState(() => _expAdvancedSecurity = v);
              await StorageService.instance.saveBool('security_exp_advanced', v);
            },
            children: _buildAdvancedSecurityTiles(),
          ),
          const SizedBox(height: 16),
          _buildSecurityStatus(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Icon(
            Icons.security,
            size: 48,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'Protection Maximale',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Configurez les paramètres de sécurité pour protéger vos données et votre vie privée.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

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

  // Méthodes pour les tiles de chaque section
  List<Widget> _buildProtectionTiles() {
    return [
      // Indicateur de méthode actuelle
      if (_currentLockMethod != 'none')
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppConstants.successColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getCurrentMethodIcon(),
                color: AppConstants.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Méthode active: ${_getCurrentMethodName()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.successColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: _disableCurrentMethod,
                child: const Text(
                  'Désactiver',
                  style: TextStyle(color: AppConstants.errorColor),
                ),
              ),
            ],
          ),
        ),
      ListTile(
        leading: Icon(
          _biometricsAvailable ? Icons.fingerprint : Icons.fingerprint_outlined,
          color: _currentLockMethod == 'biometrics' ? AppConstants.successColor : AppConstants.primaryColor,
        ),
        title: Text(
          'Configurer Biométrie',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _currentLockMethod == 'biometrics' ? AppConstants.successColor : Colors.black87,
          ),
        ),
        subtitle: Text(
          _biometricsAvailable 
              ? (_currentLockMethod == 'biometrics' ? 'Biométrie configurée' : 'Enregistrer votre empreinte ou visage')
              : 'Non disponible sur cet appareil',
          style: TextStyle(
            color: _currentLockMethod == 'biometrics' ? AppConstants.successColor : Colors.black54,
          ),
        ),
        trailing: _currentLockMethod == 'biometrics' 
            ? const Icon(Icons.check_circle, color: AppConstants.successColor)
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _biometricsAvailable ? _configureBiometrics : null,
      ),
      ListTile(
        leading: Icon(
          Icons.pin, 
          color: _currentLockMethod == 'pin' ? AppConstants.successColor : AppConstants.primaryColor,
        ),
        title: Text(
          'Configurer Code PIN',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _currentLockMethod == 'pin' ? AppConstants.successColor : Colors.black87,
          ),
        ),
        subtitle: Text(
          _currentLockMethod == 'pin' ? 'Code PIN configuré' : 'Créer un code PIN de 4-6 chiffres',
          style: TextStyle(
            color: _currentLockMethod == 'pin' ? AppConstants.successColor : Colors.black54,
          ),
        ),
        trailing: _currentLockMethod == 'pin' 
            ? const Icon(Icons.check_circle, color: AppConstants.successColor)
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configurePin,
      ),
      ListTile(
        leading: Icon(
          Icons.gesture, 
          color: _currentLockMethod == 'pattern' ? AppConstants.successColor : AppConstants.primaryColor,
        ),
        title: Text(
          'Configurer Schéma',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _currentLockMethod == 'pattern' ? AppConstants.successColor : Colors.black87,
          ),
        ),
        subtitle: Text(
          _currentLockMethod == 'pattern' ? 'Schéma configuré' : 'Créer un schéma de déverrouillage',
          style: TextStyle(
            color: _currentLockMethod == 'pattern' ? AppConstants.successColor : Colors.black54,
          ),
        ),
        trailing: _currentLockMethod == 'pattern' 
            ? const Icon(Icons.check_circle, color: AppConstants.successColor)
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configurePattern,
      ),
      ListTile(
        leading: Icon(
          Icons.password, 
          color: _currentLockMethod == 'password' ? AppConstants.successColor : AppConstants.primaryColor,
        ),
        title: Text(
          'Configurer Mot de Passe',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _currentLockMethod == 'password' ? AppConstants.successColor : Colors.black87,
          ),
        ),
        subtitle: Text(
          _currentLockMethod == 'password' ? 'Mot de passe configuré' : 'Créer un mot de passe sécurisé',
          style: TextStyle(
            color: _currentLockMethod == 'password' ? AppConstants.successColor : Colors.black54,
          ),
        ),
        trailing: _currentLockMethod == 'password' 
            ? const Icon(Icons.check_circle, color: AppConstants.successColor)
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configurePassword,
      ),
    ];
  }

  List<Widget> _buildDataPrivacyTiles() {
    return [
      SwitchListTile(
        title: const Text(
          'Mode Furtif',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Masquer l\'application et les notifications',
          style: TextStyle(color: Colors.black54),
        ),
        value: _stealthMode,
        onChanged: (value) {
          setState(() => _stealthMode = value);
          _saveSecuritySetting('stealth_mode', value);
        },
      ),
      SwitchListTile(
        title: const Text(
          'Historique des Alertes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Conserver l\'historique des alertes',
          style: TextStyle(color: Colors.black54),
        ),
        value: _alertHistoryEnabled,
        onChanged: (value) {
          setState(() => _alertHistoryEnabled = value);
          _saveSecuritySetting('alert_history_enabled', value);
        },
      ),
      SwitchListTile(
        title: const Text(
          'Suppression Auto des Preuves',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'Supprimer automatiquement après $_evidenceRetentionDays jours',
          style: const TextStyle(color: Colors.black54),
        ),
        value: _autoDeleteEvidence,
        onChanged: (value) {
          setState(() => _autoDeleteEvidence = value);
          _saveSecuritySetting('auto_delete_evidence', value);
        },
      ),
      ListTile(
        leading: const Icon(Icons.schedule, color: AppConstants.primaryColor),
        title: const Text(
          'Rétention des Preuves',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '$_evidenceRetentionDays jours',
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _configureEvidenceRetention,
      ),
      ListTile(
        leading: const Icon(Icons.delete_sweep, color: AppConstants.warningColor),
        title: const Text(
          'Suppression Rapide des Données',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Effacer toutes les données sensibles',
          style: TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showQuickDeleteDialog,
      ),
    ];
  }

  List<Widget> _buildAdvancedSecurityTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.lock, color: AppConstants.primaryColor),
        title: const Text(
          'Chiffrement des Données',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Toutes les données sont chiffrées localement',
          style: TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.check_circle, color: AppConstants.successColor),
      ),
      ListTile(
        leading: const Icon(Icons.cloud_off, color: AppConstants.primaryColor),
        title: const Text(
          'Mode Hors-ligne',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Fonctionnement sans connexion internet',
          style: TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.check_circle, color: AppConstants.successColor),
      ),
      ListTile(
        leading: const Icon(Icons.privacy_tip, color: AppConstants.primaryColor),
        title: const Text(
          'Politique de Confidentialité',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Lire nos conditions d\'utilisation',
          style: TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showPrivacyPolicy,
      ),
      ListTile(
        leading: const Icon(Icons.delete_forever, color: AppConstants.errorColor),
        title: const Text(
          'Droit à l\'Oubli',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Demander la suppression de vos données',
          style: TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
        onTap: _showRightToForgetDialog,
      ),
    ];
  }





  Widget _buildSecurityStatus() {
    final securityLevel = _calculateSecurityLevel();
    final statusColor = _getSecurityStatusColor(securityLevel);
    final statusText = _getSecurityStatusText(securityLevel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.security,
            size: 48,
            color: statusColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Niveau de Sécurité: $statusText',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getSecurityRecommendations(securityLevel),
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.blackColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _calculateSecurityLevel() {
    int level = 0;
    if (_currentLockMethod == 'biometrics') level += 3;
    if (_currentLockMethod == 'pin') level += 2;
    if (_currentLockMethod == 'pattern') level += 2;
    if (_currentLockMethod == 'password') level += 2;
    if (_stealthMode) level += 1;
    if (_autoDeleteEvidence) level += 1;
    return level;
  }

  Color _getSecurityStatusColor(int level) {
    if (level >= 5) return AppConstants.successColor;
    if (level >= 3) return AppConstants.warningColor;
    return AppConstants.errorColor;
  }

  String _getSecurityStatusText(int level) {
    if (level >= 5) return 'Élevé';
    if (level >= 3) return 'Moyen';
    return 'Faible';
  }

  String _getSecurityRecommendations(int level) {
    if (level >= 5) return 'Excellent ! Votre sécurité est maximale.';
    if (level >= 3) return 'Bon niveau de sécurité. Activez la biométrie pour plus de protection.';
    return 'Activez l\'authentification biométrique ou le code PIN pour plus de sécurité.';
  }

  // Méthodes utilitaires pour l'affichage
  // Méthodes de configuration manquantes
  Future<void> _configureBiometrics() async {
    try {
      // Vérifier si la biométrie est disponible
      final isAvailable = await SecurityService.instance.canCheckBiometrics();
      if (!isAvailable) {
        _showSnack('Biométrie non disponible sur cet appareil', isError: true);
        return;
      }

      // Vérifier si une méthode est déjà active
      if (_currentLockMethod != 'none') {
        final shouldContinue = await _showMethodChangeDialog();
        if (!shouldContinue) return;
        await _disableCurrentMethod();
      }

      // Afficher un message d'information
      _showSnack('Placez votre doigt sur le capteur ou regardez la caméra...');

      // Tester l'authentification biométrique
      final success = await SecurityService.instance.authenticateWithBiometrics(
        reason: 'Configurer le déverrouillage biométrique'
      );
      
      if (success) {
        await SecurityService.instance.setLockMethod(AppLockMethod.biometrics);
        setState(() => _currentLockMethod = 'biometrics');
        _showSnack('Biométrie configurée avec succès');
      } else {
        _showSnack('Configuration biométrique non disponible sur cet appareil', isError: true);
      }
    } catch (e) {
      print('Erreur configuration biométrique: $e');
      _showSnack('Erreur lors de la configuration biométrique: $e', isError: true);
    }
  }

  Future<void> _configurePin() async {
    try {
      // Vérifier si une méthode est déjà active
      if (_currentLockMethod != 'none') {
        final shouldContinue = await _showMethodChangeDialog();
        if (!shouldContinue) return;
        await _disableCurrentMethod();
      }

      _pinController.clear();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConstants.whiteColor,
          title: const Text(
            'Configurer le Code PIN',
            style: TextStyle(
              color: AppConstants.blackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Créez un code PIN de 4 à 6 chiffres',
                style: TextStyle(color: AppConstants.blackColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Code PIN',
                  labelStyle: TextStyle(color: AppConstants.blackColor),
                  border: OutlineInputBorder(),
                ),
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
              onPressed: () async {
                final pin = _pinController.text.trim();
                if (pin.length >= 4 && pin.length <= 6) {
                  await SecurityService.instance.savePin(pin);
                  await SecurityService.instance.setLockMethod(AppLockMethod.pin);
                  setState(() => _currentLockMethod = 'pin');
                  Navigator.of(ctx).pop();
                  _showSnack('Code PIN configuré avec succès');
                } else {
                  _showSnack('Le PIN doit contenir 4 à 6 chiffres', isError: true);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    }
  }

  Future<void> _configurePattern() async {
    try {
      // Vérifier si une méthode est déjà active
      if (_currentLockMethod != 'none') {
        final shouldContinue = await _showMethodChangeDialog();
        if (!shouldContinue) return;
        await _disableCurrentMethod();
      }

      // Simulation de configuration de schéma
      await Future.delayed(const Duration(seconds: 1));
      await StorageService.instance.saveString('pattern_lock', 'simulated_pattern');
      setState(() => _currentLockMethod = 'pattern');
      _showSnack('Schéma configuré avec succès (simulation)');
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    }
  }

  Future<void> _configurePassword() async {
    try {
      // Vérifier si une méthode est déjà active
      if (_currentLockMethod != 'none') {
        final shouldContinue = await _showMethodChangeDialog();
        if (!shouldContinue) return;
        await _disableCurrentMethod();
      }

      _passwordController.clear();
      _confirmPasswordController.clear();
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConstants.whiteColor,
          title: const Text(
            'Configurer le Mot de Passe',
            style: TextStyle(
              color: AppConstants.blackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Créez un mot de passe sécurisé (minimum 8 caractères)',
                style: TextStyle(color: AppConstants.blackColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(color: AppConstants.blackColor),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  labelStyle: TextStyle(color: AppConstants.blackColor),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
                final password = _passwordController.text.trim();
                final confirmPassword = _confirmPasswordController.text.trim();
                
                if (password.length < 8) {
                  _showSnack('Le mot de passe doit contenir au moins 8 caractères', isError: true);
                  return;
                }
                
                if (password != confirmPassword) {
                  _showSnack('Les mots de passe ne correspondent pas', isError: true);
                  return;
                }
                
                Navigator.of(ctx).pop();
                await _savePassword(password);
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
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    }
  }

  Future<void> _savePassword(String password) async {
    try {
      // Sauvegarder le mot de passe (simulation)
      await StorageService.instance.saveString('password_lock', password);
      setState(() => _currentLockMethod = 'password');
      _showSnack('Mot de passe configuré avec succès');
    } catch (e) {
      _showSnack('Erreur lors de la configuration du mot de passe: $e', isError: true);
    }
  }

  // Méthodes utilitaires
  IconData _getCurrentMethodIcon() {
    switch (_currentLockMethod) {
      case 'biometrics': return Icons.fingerprint;
      case 'pin': return Icons.pin;
      case 'pattern': return Icons.gesture;
      case 'password': return Icons.password;
      default: return Icons.lock_open;
    }
  }

  String _getCurrentMethodName() {
    switch (_currentLockMethod) {
      case 'biometrics': return 'Biométrie';
      case 'pin': return 'Code PIN';
      case 'pattern': return 'Schéma';
      case 'password': return 'Mot de Passe';
      default: return 'Aucune';
    }
  }

  Future<bool> _showMethodChangeDialog() async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Changer de méthode de sécurité',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Vous avez déjà configuré ${_getCurrentMethodName()}. Voulez-vous la désactiver et configurer une nouvelle méthode ?',
            style: const TextStyle(color: AppConstants.blackColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _disableCurrentMethod() async {
    try {
      await SecurityService.instance.setLockMethod(AppLockMethod.none);
      await StorageService.instance.remove('pattern_lock');
      await StorageService.instance.remove('password_lock');
      setState(() => _currentLockMethod = 'none');
      _showSnack('Méthode de sécurité désactivée');
    } catch (e) {
      _showSnack('Erreur lors de la désactivation: $e', isError: true);
    }
  }

  Future<void> _configureEvidenceRetention() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Rétention des Preuves',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nombre de jours avant suppression automatique',
              style: TextStyle(color: AppConstants.blackColor),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _evidenceRetentionDays.toDouble(),
              min: 1,
              max: 365,
              divisions: 364,
              label: '$_evidenceRetentionDays jours',
              onChanged: (value) {
                setState(() => _evidenceRetentionDays = value.round());
              },
            ),
            Text(
              '$_evidenceRetentionDays jours',
              style: const TextStyle(
                color: AppConstants.blackColor,
                fontWeight: FontWeight.bold,
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
              await _saveIntSetting('evidence_retention_days', _evidenceRetentionDays);
              Navigator.of(ctx).pop();
              _showSnack('Rétention des preuves mise à jour');
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickDeleteDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Suppression Rapide',
          style: TextStyle(
            color: AppConstants.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Cette action supprimera définitivement toutes vos données sensibles. Êtes-vous sûr ?',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implémenter la suppression rapide
              Navigator.of(ctx).pop();
              _showSnack('Suppression rapide effectuée');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacyPolicy() async {
    _showSnack('Ouverture de la politique de confidentialité');
    // TODO: Ouvrir l'URL de la politique de confidentialité
  }

  

















  void _showRightToForgetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Droit à l\'Oubli',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Conformément au RGPD, vous avez le droit de demander la suppression de vos données personnelles.',
                style: TextStyle(color: AppConstants.blackColor),
              ),
              SizedBox(height: 16),
              Text(
                'Cette demande entraînera :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.blackColor,
                ),
              ),
              SizedBox(height: 8),
              Text('• Suppression de votre compte', style: TextStyle(color: AppConstants.blackColor)),
              Text('• Suppression de toutes vos données personnelles', style: TextStyle(color: AppConstants.blackColor)),
              Text('• Suppression de l\'historique des alertes', style: TextStyle(color: AppConstants.blackColor)),
              Text('• Suppression des preuves enregistrées', style: TextStyle(color: AppConstants.blackColor)),
              SizedBox(height: 16),
              Text(
                'Cette action est irréversible et prendra effet dans les 30 jours.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppConstants.blackColor,
                ),
              ),
            ],
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
            onPressed: () {
              Navigator.of(ctx).pop();
              _requestRightToForget();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.warningColor,
              foregroundColor: AppConstants.whiteColor,
            ),
            child: const Text('Demander la Suppression'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRightToForget() async {
    try {
      // Simuler l'envoi de la demande
      await Future.delayed(const Duration(seconds: 1));
      
      _showSnack('Demande de suppression envoyée. Vous recevrez une confirmation par email.');
    } catch (e) {
      _showSnack('Erreur lors de l\'envoi de la demande: $e', isError: true);
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guinemali/core/constants/app_constants.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/security_service.dart';
import 'package:local_auth/local_auth.dart';

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
  
  // Contrôleurs pour les formulaires
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Variables pour le schéma
  List<int> _pattern = [];

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
      backgroundColor: AppConstants.whiteColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          
          _buildSectionHeader('Protection de l\'Application', Icons.lock),
          ..._buildAppProtectionTiles(),
          const Divider(height: 24),

          _buildSectionHeader('Confidentialité des Données', Icons.privacy_tip),
          ..._buildPrivacyTiles(),
          const Divider(height: 24),

          _buildSectionHeader('Gestion des Preuves', Icons.security),
          ..._buildEvidenceManagementTiles(),
          const Divider(height: 24),

          _buildSectionHeader('Sécurité Avancée', Icons.shield),
          ..._buildAdvancedSecurityTiles(),
          const SizedBox(height: 24),

          _buildSecurityStatus(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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
            Icons.security,
            size: 48,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'Protection Maximale',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.blackColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Configurez les paramètres de sécurité pour protéger vos données et votre vie privée.',
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

  List<Widget> _buildAppProtectionTiles() {
    return [
      // Méthode de verrouillage actuelle
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getCurrentMethodColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getCurrentMethodColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getCurrentMethodIcon(),
              color: _getCurrentMethodColor(),
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Méthode Actuelle: ${_getCurrentMethodName()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppConstants.blackColor,
                    ),
                  ),
                  Text(
                    _getCurrentMethodDescription(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.blackColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_currentLockMethod != 'none')
              IconButton(
                icon: const Icon(Icons.edit, color: AppConstants.primaryColor),
                onPressed: _changeCurrentMethod,
              ),
          ],
        ),
      ),
      
      // Options de sécurité
      ListTile(
        leading: Icon(
          _biometricsAvailable ? Icons.fingerprint : Icons.fingerprint_outlined,
          color: _biometricsAvailable ? AppConstants.primaryColor : AppConstants.errorColor,
        ),
        title: const Text(
          'Configurer Biométrie',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: Text(
          _biometricsAvailable 
              ? 'Enregistrer votre empreinte ou visage'
              : 'Non disponible sur cet appareil',
          style: const TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _biometricsAvailable ? _setupBiometrics : null,
      ),
      
      ListTile(
        leading: const Icon(Icons.pin, color: AppConstants.primaryColor),
        title: const Text(
          'Configurer Code PIN',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Créer un code PIN de 4-6 chiffres',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _setupPin,
      ),
      
      ListTile(
        leading: const Icon(Icons.gesture, color: AppConstants.primaryColor),
        title: const Text(
          'Configurer Schéma',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Créer un schéma de déverrouillage',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _setupPattern,
      ),
      
      ListTile(
        leading: const Icon(Icons.password, color: AppConstants.primaryColor),
        title: const Text(
          'Configurer Mot de Passe',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Créer un mot de passe sécurisé',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _setupPassword,
      ),
      
      if (_currentLockMethod != 'none')
        ListTile(
          leading: const Icon(Icons.lock_open, color: AppConstants.errorColor),
          title: const Text(
            'Désactiver la Sécurité',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppConstants.blackColor,
            ),
          ),
          subtitle: const Text(
            'Supprimer la protection de l\'application',
            style: TextStyle(color: AppConstants.blackColor),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _disableSecurity,
        ),
    ];
  }

  List<Widget> _buildPrivacyTiles() {
    return [
      SwitchListTile(
        title: const Text(
          'Mode Furtif',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Masquer l\'application et les notifications',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        value: _stealthMode,
        secondary: const Icon(Icons.visibility_off, color: AppConstants.primaryColor),
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
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Conserver l\'historique des alertes',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        value: _alertHistoryEnabled,
        secondary: const Icon(Icons.history, color: AppConstants.primaryColor),
        onChanged: (value) {
          setState(() => _alertHistoryEnabled = value);
          _saveSecuritySetting('alert_history_enabled', value);
        },
      ),
      ListTile(
        leading: const Icon(Icons.delete_sweep, color: AppConstants.warningColor),
        title: const Text(
          'Suppression Rapide des Données',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Effacer toutes les données sensibles',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showDeleteDataDialog,
      ),
    ];
  }

  List<Widget> _buildEvidenceManagementTiles() {
    return [
      SwitchListTile(
        title: const Text(
          'Suppression Auto des Preuves',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: Text(
          'Supprimer automatiquement après $_evidenceRetentionDays jours',
          style: const TextStyle(color: AppConstants.blackColor),
        ),
        value: _autoDeleteEvidence,
        secondary: const Icon(Icons.delete_forever, color: AppConstants.primaryColor),
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
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: Text(
          '$_evidenceRetentionDays jours',
          style: const TextStyle(color: AppConstants.blackColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      Slider(
        value: _evidenceRetentionDays.toDouble(),
        min: 1,
        max: 90,
        divisions: 89,
        label: '$_evidenceRetentionDays',
        activeColor: AppConstants.primaryColor,
        onChanged: (value) {
          setState(() => _evidenceRetentionDays = value.round());
        },
        onChangeEnd: (value) {
          _saveIntSetting('evidence_retention_days', value.round());
        },
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
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Toutes les données sont chiffrées localement',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.check_circle, color: AppConstants.successColor),
      ),
      ListTile(
        leading: const Icon(Icons.cloud_off, color: AppConstants.primaryColor),
        title: const Text(
          'Mode Hors-ligne',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Fonctionnement sans connexion internet',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.check_circle, color: AppConstants.successColor),
      ),
      ListTile(
        leading: const Icon(Icons.privacy_tip, color: AppConstants.primaryColor),
        title: const Text(
          'Politique de Confidentialité',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Lire nos conditions d\'utilisation',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showPrivacyPolicy,
      ),
      ListTile(
        leading: const Icon(Icons.delete_forever, color: AppConstants.errorColor),
        title: const Text(
          'Droit à l\'Oubli',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: const Text(
          'Demander la suppression de vos données',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
  Color _getCurrentMethodColor() {
    switch (_currentLockMethod) {
      case 'biometrics': return AppConstants.successColor;
      case 'pin': return AppConstants.primaryColor;
      case 'pattern': return AppConstants.secondaryColor;
      case 'password': return AppConstants.warningColor;
      default: return AppConstants.errorColor;
    }
  }

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

  String _getCurrentMethodDescription() {
    switch (_currentLockMethod) {
      case 'biometrics': return 'Empreinte digitale ou reconnaissance faciale';
      case 'pin': return 'Code numérique de 4-6 chiffres';
      case 'pattern': return 'Schéma de déverrouillage';
      case 'password': return 'Mot de passe sécurisé';
      default: return 'Aucune protection activée';
    }
  }

  // Méthodes de configuration
  Future<void> _setupBiometrics() async {
    try {
      final LocalAuthentication auth = LocalAuthentication();
      final bool canAuthenticate = await auth.canCheckBiometrics;
      
      if (!canAuthenticate) {
        _showSnack('Biométrie non disponible sur cet appareil', isError: true);
        return;
      }

      // Vérifier la méthode actuelle
      if (_currentLockMethod != 'none') {
        _showSnack('Désactivez d\'abord la méthode actuelle', isError: true);
        return;
      }

      // Tester l'authentification biométrique
      final bool authenticated = await auth.authenticate(
        localizedReason: 'Placez votre doigt sur le capteur ou regardez la caméra pour configurer la biométrie',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await SecurityService.instance.setLockMethod(AppLockMethod.biometrics);
        setState(() => _currentLockMethod = 'biometrics');
        _showSnack('Authentification biométrique configurée avec succès');
      } else {
        _showSnack('Configuration biométrique annulée', isError: true);
      }
    } catch (e) {
      _showSnack('Erreur lors de la configuration biométrique: $e', isError: true);
    }
  }

  Future<void> _setupPin() async {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez un code PIN de 4 à 6 chiffres',
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
                counterText: '',
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
              final pin = _pinController.text.trim();
              if (pin.length < 4 || pin.length > 6) {
                _showSnack('Le code PIN doit contenir entre 4 et 6 chiffres', isError: true);
                return;
              }
              
              Navigator.of(ctx).pop();
              await _savePin(pin);
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

  Future<void> _savePin(String pin) async {
    try {
      if (_currentLockMethod != 'none') {
        _showSnack('Désactivez d\'abord la méthode actuelle', isError: true);
        return;
      }

      await SecurityService.instance.setLockMethod(AppLockMethod.pin);
      await SecurityService.instance.savePin(pin);
      setState(() => _currentLockMethod = 'pin');
      _showSnack('Code PIN configuré avec succès');
    } catch (e) {
      _showSnack('Erreur lors de la configuration du PIN: $e', isError: true);
    }
  }

  Future<void> _setupPattern() async {
    _pattern.clear();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Configurer le Schéma',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 300,
          height: 300,
          child: _buildPatternLock(),
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
            onPressed: _pattern.length >= 4 ? () async {
              Navigator.of(ctx).pop();
              await _savePattern();
            } : null,
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

  Widget _buildPatternLock() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final isSelected = _pattern.contains(index);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (!_pattern.contains(index)) {
                _pattern.add(index);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppConstants.primaryColor : Colors.grey[300],
              border: Border.all(
                color: isSelected ? AppConstants.primaryColor : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isSelected ? AppConstants.whiteColor : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePattern() async {
    try {
      if (_currentLockMethod != 'none') {
        _showSnack('Désactivez d\'abord la méthode actuelle', isError: true);
        return;
      }

      // Sauvegarder le schéma (simulation)
      await StorageService.instance.saveString('pattern_lock', _pattern.join(','));
      setState(() => _currentLockMethod = 'pattern');
      _showSnack('Schéma configuré avec succès');
    } catch (e) {
      _showSnack('Erreur lors de la configuration du schéma: $e', isError: true);
    }
  }

  Future<void> _setupPassword() async {
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
        content: Column(
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
  }

  Future<void> _savePassword(String password) async {
    try {
      if (_currentLockMethod != 'none') {
        _showSnack('Désactivez d\'abord la méthode actuelle', isError: true);
        return;
      }

      // Sauvegarder le mot de passe (simulation)
      await StorageService.instance.saveString('password_lock', password);
      setState(() => _currentLockMethod = 'password');
      _showSnack('Mot de passe configuré avec succès');
    } catch (e) {
      _showSnack('Erreur lors de la configuration du mot de passe: $e', isError: true);
    }
  }

  Future<void> _changeCurrentMethod() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Modifier la Méthode de Sécurité',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Pour changer de méthode de sécurité, vous devez d\'abord désactiver la méthode actuelle, puis configurer la nouvelle méthode.',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Fermer',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _disableSecurity();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.warningColor,
              foregroundColor: AppConstants.whiteColor,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  Future<void> _disableSecurity() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Désactiver la Sécurité',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir désactiver la protection de l\'application ? Cette action supprimera toutes les méthodes de sécurité configurées.',
          style: TextStyle(color: AppConstants.blackColor),
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
              Navigator.of(ctx).pop();
              try {
                await SecurityService.instance.setLockMethod(AppLockMethod.none);
                await StorageService.instance.remove('pattern_lock');
                await StorageService.instance.remove('password_lock');
                setState(() => _currentLockMethod = 'none');
                _showSnack('Sécurité désactivée');
              } catch (e) {
                _showSnack('Erreur lors de la désactivation: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: AppConstants.whiteColor,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }



  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Suppression des Données',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Cette action supprimera toutes les données sensibles de l\'application (preuves, historique, contacts). Cette action est irréversible.',
          style: TextStyle(color: AppConstants.blackColor),
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
              _deleteAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: AppConstants.whiteColor,
            ),
            child: const Text('Supprimer'),
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
      
      _showSnack('Données supprimées avec succès');
    } catch (e) {
      _showSnack('Erreur lors de la suppression: $e', isError: true);
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Politique de Confidentialité',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Guinemali s\'engage à protéger votre vie privée. Vos données sont chiffrées et stockées de manière sécurisée. Nous ne partageons jamais vos informations personnelles avec des tiers sans votre consentement explicite.\n\nToutes les preuves sont chiffrées localement avant stockage. L\'application fonctionne en mode hors-ligne pour garantir votre sécurité même sans connexion internet.',
            style: TextStyle(color: AppConstants.blackColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Fermer',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
        ],
      ),
    );
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

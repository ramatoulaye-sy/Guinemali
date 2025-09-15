import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:guinemali/core/constants/app_constants.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _locGranted = false;
  bool _micGranted = false;
  bool _camGranted = false;
  bool _storageGranted = false;
  bool _notifGranted = false;
  bool _smsGranted = false;
  bool _isLoading = true;

  String _locationAccuracy = 'haute';
  
  // Configuration avancée des médias
  bool _autoRecordOnAlert = true;
  int _maxRecordingDuration = 300; // 5 minutes
  
  // Configuration stockage et sécurité
  bool _encryptLocalFiles = true;
  int _autoDeleteDays = 30;
  bool _cloudSync = true;
  
  // Configuration communications
  bool _smsBackup = true;
  String _notificationSound = 'alerte';

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    
    try {
      // Vérifier les permissions une par une avec gestion d'erreur
      final permissions = [
        Permission.location,
        Permission.microphone,
        Permission.camera,
        Permission.storage,
        Permission.notification,
        Permission.sms,
      ];

      final results = await Future.wait(
        permissions.map((p) => p.status.catchError((e) {
          print('❌ Erreur permission ${p.toString()}: $e');
          return PermissionStatus.denied;
        })),
      );

      if (!mounted) return;
      
      setState(() {
        _locGranted = results[0].isGranted;
        _micGranted = results[1].isGranted;
        _camGranted = results[2].isGranted;
        _storageGranted = results[3].isGranted;
        _notifGranted = results[4].isGranted;
        _smsGranted = results[5].isGranted;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur lors de la vérification des permissions: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _confirmConsent(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppConstants.whiteColor,
            title: Text(
              title,
              style: const TextStyle(
                color: AppConstants.blackColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(color: AppConstants.blackColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: AppConstants.primaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.whiteColor,
                ),
                child: const Text('Autoriser'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: AppConstants.whiteColor),
        ),
        backgroundColor: isError ? AppConstants.errorColor : AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleToggle({
    required Permission permission,
    required bool enable,
    required String consentTitle,
    required String consentMessage,
    required VoidCallback onGranted,
    required VoidCallback onDenied,
  }) async {
    try {
      if (enable) {
        final ok = await _confirmConsent(consentTitle, consentMessage);
        if (!ok) {
          onDenied();
          _showSnack('Autorisation refusée par l\'utilisateur', isError: true);
          return;
        }
        
        final status = await permission.request();
        if (status.isGranted) {
          onGranted();
          _showSnack('✅ $consentTitle activée');
        } else if (status.isPermanentlyDenied) {
          onDenied();
          _showSnack('❌ $consentTitle bloquée. Ouvrir les paramètres.', isError: true);
          _showSettingsDialog(consentTitle);
        } else {
          onDenied();
          _showSnack('❌ $consentTitle refusée', isError: true);
        }
      } else {
        onDenied();
        _showSnack('🔒 $consentTitle désactivée');
      }
    } catch (e) {
      print('❌ Erreur lors de la gestion de la permission: $e');
      onDenied();
      _showSnack('❌ Erreur lors de la gestion de la permission', isError: true);
    }
  }

  void _showSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: Text(
          'Paramètres requis',
          style: const TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'La permission $permissionName est bloquée. Veuillez l\'activer manuellement dans les paramètres de l\'application.',
          style: const TextStyle(color: AppConstants.blackColor),
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
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.whiteColor,
            ),
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.whiteColor,
      appBar: AppBar(
        title: const Text(
          '⚙️ Autorisations nécessaires',
          style: TextStyle(
            color: AppConstants.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.whiteColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshAll,
              color: AppConstants.primaryColor,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  
                  // Section Localisation
                  _buildLocationPermissionCard(),

                  const SizedBox(height: 16),

                  // Section Enregistrement Média
                  _buildMediaRecordingCard(),

                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  // Section Stockage et Sécurité
                  _buildStorageSecurityCard(),

                  const SizedBox(height: 16),

                  // Section Communications d'Urgence
                  _buildEmergencyCommunicationsCard(),

                  const SizedBox(height: 24),

                  // Bouton paramètres système
                  _buildSystemSettingsButton(),

                  const SizedBox(height: 16),

                  // Résumé des permissions
                  _buildPermissionsSummary(),

                  const SizedBox(height: 20),
                ],
              ),
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
            'Gestion des Autorisations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.blackColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Configurez les permissions nécessaires pour le bon fonctionnement de l\'application de sécurité.',
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

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required Function(bool) onToggle,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted 
              ? AppConstants.successColor.withOpacity(0.3)
              : AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              icon,
              color: isGranted ? AppConstants.successColor : AppConstants.primaryColor,
              size: 28,
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.blackColor,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                color: AppConstants.blackColor,
                fontSize: 13,
              ),
            ),
            value: isGranted,
            onChanged: onToggle,
            activeColor: AppConstants.successColor,
            inactiveThumbColor: AppConstants.primaryColor,
            inactiveTrackColor: AppConstants.primaryColor.withOpacity(0.3),
          ),
          if (child != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationAccuracySelector() {
    return Row(
      children: [
        Icon(
          Icons.gps_fixed,
          size: 18,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(width: 8),
        const Text(
          'Précision GPS:',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _locationAccuracy,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppConstants.primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(
                value: 'haute',
                child: Text('Haute précision'),
              ),
              DropdownMenuItem(
                value: 'basse',
                child: Text('Basse précision'),
              ),
            ],
            onChanged: (v) => setState(() => _locationAccuracy = v ?? 'haute'),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemSettingsButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
        ),
      ),
      child: TextButton.icon(
        onPressed: openAppSettings,
        icon: const Icon(
          Icons.settings,
          color: AppConstants.primaryColor,
        ),
        label: const Text(
          'Ouvrir les paramètres système',
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPermissionsSummary() {
    final totalPermissions = 6;
    final grantedPermissions = [
      _locGranted,
      _micGranted,
      _camGranted,
      _storageGranted,
      _notifGranted,
      _smsGranted,
    ].where((granted) => granted).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: grantedPermissions == totalPermissions
            ? AppConstants.successColor.withOpacity(0.1)
            : AppConstants.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: grantedPermissions == totalPermissions
              ? AppConstants.successColor.withOpacity(0.3)
              : AppConstants.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            grantedPermissions == totalPermissions
                ? Icons.check_circle
                : Icons.warning,
            color: grantedPermissions == totalPermissions
                ? AppConstants.successColor
                : AppConstants.warningColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grantedPermissions == totalPermissions
                      ? 'Toutes les permissions sont activées'
                      : '$grantedPermissions/$totalPermissions permissions activées',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: grantedPermissions == totalPermissions
                        ? AppConstants.successColor
                        : AppConstants.warningColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  grantedPermissions == totalPermissions
                      ? 'L\'application fonctionne de manière optimale'
                      : 'Activez les permissions manquantes pour une meilleure expérience',
                  style: const TextStyle(
                    color: AppConstants.blackColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nouvelles méthodes de configuration avancées
  Widget _buildLocationPermissionCard() {
    return _buildPermissionCard(
      icon: Icons.location_on,
      title: '📍 Localisation (GPS)',
      subtitle: 'Utile pour envoyer votre position en cas d\'alerte',
      isGranted: _locGranted,
      onToggle: (v) => _handleToggle(
        permission: Permission.location,
        enable: v,
        consentTitle: 'Localisation',
        consentMessage: 'Autoriser l\'application à accéder à votre position pour l\'alerte et la carte.',
        onGranted: () => setState(() => _locGranted = true),
        onDenied: () => setState(() => _locGranted = false),
      ),
      child: _locGranted ? _buildLocationAccuracySelector() : null,
    );
  }

  Widget _buildMediaRecordingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_micGranted || _camGranted)
              ? AppConstants.successColor.withOpacity(0.3)
              : AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.mic,
              color: _micGranted ? AppConstants.successColor : AppConstants.primaryColor,
              size: 28,
            ),
            title: const Text(
              '🎤 Microphone',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.blackColor,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Nécessaire pour enregistrer un audio comme preuve',
              style: TextStyle(
                color: AppConstants.blackColor,
                fontSize: 13,
              ),
            ),
            trailing: Switch(
              value: _micGranted,
              onChanged: (v) => _handleToggle(
                permission: Permission.microphone,
                enable: v,
                consentTitle: 'Microphone',
                consentMessage: 'Autoriser l\'enregistrement audio lors d\'une alerte ou comme preuve.',
                onGranted: () => setState(() => _micGranted = true),
                onDenied: () => setState(() => _micGranted = false),
              ),
              activeColor: AppConstants.successColor,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.videocam,
              color: _camGranted ? AppConstants.successColor : AppConstants.primaryColor,
              size: 28,
            ),
            title: const Text(
              '🎥 Caméra',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.blackColor,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Nécessaire pour enregistrer une vidéo comme preuve',
              style: TextStyle(
                color: AppConstants.blackColor,
                fontSize: 13,
              ),
            ),
            trailing: Switch(
              value: _camGranted,
              onChanged: (v) => _handleToggle(
                permission: Permission.camera,
                enable: v,
                consentTitle: 'Caméra',
                consentMessage: 'Autoriser l\'enregistrement vidéo lors d\'une alerte ou comme preuve.',
                onGranted: () => setState(() => _camGranted = true),
                onDenied: () => setState(() => _camGranted = false),
              ),
              activeColor: AppConstants.successColor,
            ),
          ),
          if (_micGranted || _camGranted) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration Enregistrement:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.blackColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.auto_awesome, size: 20),
                    title: const Text(
                      'Enregistrement automatique en alerte',
                      style: TextStyle(fontSize: 14, color: AppConstants.blackColor),
                    ),
                    trailing: Switch(
                      value: _autoRecordOnAlert,
                      onChanged: (v) => setState(() => _autoRecordOnAlert = v),
                      activeColor: AppConstants.successColor,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timer, size: 20),
                    title: Text(
                      'Durée max: ${_maxRecordingDuration ~/ 60} min',
                      style: const TextStyle(fontSize: 14, color: AppConstants.blackColor),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.settings, size: 20),
                      onPressed: () => _showSnack('Configuration durée - Fonctionnalité en développement'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStorageSecurityCard() {
    return _buildPermissionCard(
      icon: Icons.sd_storage,
      title: '💾 Stockage et Sécurité',
      subtitle: 'Gestion sécurisée des preuves et fichiers',
      isGranted: _storageGranted,
      onToggle: (v) => _handleToggle(
        permission: Permission.storage,
        enable: v,
        consentTitle: 'Stockage',
        consentMessage: 'Autoriser l\'enregistrement chiffré local des preuves avant envoi sécurisé.',
        onGranted: () => setState(() => _storageGranted = true),
        onDenied: () => setState(() => _storageGranted = false),
      ),
      child: _storageGranted ? _buildStorageSettings() : null,
    );
  }

  Widget _buildStorageSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuration Sécurité:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock, size: 20),
          title: const Text(
            'Chiffrement local des fichiers',
            style: TextStyle(fontSize: 14, color: AppConstants.blackColor),
          ),
          trailing: Switch(
            value: _encryptLocalFiles,
            onChanged: (v) => setState(() => _encryptLocalFiles = v),
            activeColor: AppConstants.successColor,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_sync, size: 20),
          title: const Text(
            'Synchronisation cloud automatique',
            style: TextStyle(fontSize: 14, color: AppConstants.blackColor),
          ),
          trailing: Switch(
            value: _cloudSync,
            onChanged: (v) => setState(() => _cloudSync = v),
            activeColor: AppConstants.successColor,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_sweep, size: 20),
          title: Text(
            'Suppression auto: $_autoDeleteDays jours',
            style: const TextStyle(fontSize: 14, color: AppConstants.blackColor),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () => _showSnack('Configuration suppression - Fonctionnalité en développement'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyCommunicationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_notifGranted || _smsGranted)
              ? AppConstants.successColor.withOpacity(0.3)
              : AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.notifications,
              color: _notifGranted ? AppConstants.successColor : AppConstants.primaryColor,
              size: 28,
            ),
            title: const Text(
              '🔔 Notifications Push',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.blackColor,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Alertes en temps réel (Firebase Cloud Messaging)',
              style: TextStyle(
                color: AppConstants.blackColor,
                fontSize: 13,
              ),
            ),
            trailing: Switch(
              value: _notifGranted,
              onChanged: (v) => _handleToggle(
                permission: Permission.notification,
                enable: v,
                consentTitle: 'Notifications',
                consentMessage: 'Autoriser l\'envoi de notifications (alertes et mises à jour importantes).',
                onGranted: () => setState(() => _notifGranted = true),
                onDenied: () => setState(() => _notifGranted = false),
              ),
              activeColor: AppConstants.successColor,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.sms,
              color: _smsGranted ? AppConstants.successColor : AppConstants.primaryColor,
              size: 28,
            ),
            title: const Text(
              '📩 SMS Secours',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.blackColor,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'SMS d\'alerte si internet indisponible',
              style: TextStyle(
                color: AppConstants.blackColor,
                fontSize: 13,
              ),
            ),
            trailing: Switch(
              value: _smsGranted,
              onChanged: (v) => _handleToggle(
                permission: Permission.sms,
                enable: v,
                consentTitle: 'SMS Secours',
                consentMessage: 'Autoriser l\'application à envoyer automatiquement un SMS d\'alerte aux aidants en cas d\'urgence et d\'absence d\'internet.',
                onGranted: () => setState(() => _smsGranted = true),
                onDenied: () => setState(() => _smsGranted = false),
              ),
              activeColor: AppConstants.successColor,
            ),
          ),
          if (_notifGranted || _smsGranted) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration Communications:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.blackColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_notifGranted) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.volume_up, size: 20),
                      title: Text(
                        'Son notification: $_notificationSound',
                        style: const TextStyle(fontSize: 14, color: AppConstants.blackColor),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () => _showSnack('Configuration son - Fonctionnalité en développement'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.vibration, size: 20),
                      title: const Text(
                        'Vibration en alerte',
                        style: TextStyle(fontSize: 14, color: AppConstants.blackColor),
                      ),
                      trailing: Switch(
                        value: true,
                        onChanged: (v) => _showSnack('Vibration ${v ? 'activée' : 'désactivée'}'),
                        activeColor: AppConstants.successColor,
                      ),
                    ),
                  ],
                  if (_smsGranted) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.backup, size: 20),
                      title: const Text(
                        'SMS de secours automatique',
                        style: TextStyle(fontSize: 14, color: AppConstants.blackColor),
                      ),
                      trailing: Switch(
                        value: _smsBackup,
                        onChanged: (v) => setState(() => _smsBackup = v),
                        activeColor: AppConstants.successColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}



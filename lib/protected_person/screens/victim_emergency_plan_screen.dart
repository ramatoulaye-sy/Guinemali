import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/emergency_contact_service.dart';
import 'package:guinemali/core/services/geolocation_service.dart';
import 'package:guinemali/core/services/local_alert_service.dart';
import 'package:guinemali/core/services/local_notification_service.dart';
import 'package:guinemali/core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class VictimEmergencyPlanScreen extends StatefulWidget {
  const VictimEmergencyPlanScreen({super.key});

  @override
  State<VictimEmergencyPlanScreen> createState() => _VictimEmergencyPlanScreenState();
}

class _VictimEmergencyPlanScreenState extends State<VictimEmergencyPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emergencyInstructionsController = TextEditingController();
  final _safePlacesController = TextEditingController();
  final _escapeRoutesController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  final _smsTemplateController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, dynamic>? _emergencyPlan;

  @override
  void initState() {
    super.initState();
    _loadEmergencyPlan();
  }

  // === Actions rapides (réutilisent la logique existante du panneau Actions Rapides) ===
  void _navigateToSOS(BuildContext context) async {
    HapticFeedback.heavyImpact();
    
    // Demander confirmation
    final confirmed = await _showEmergencyConfirmation();
    if (!confirmed) return;
    
    try {
      // Obtenir la position actuelle
      final position = await GeolocationService.instance.getCurrentPosition();
      
      // Créer l'alerte d'urgence locale
      final alertId = await LocalAlertService.instance.createEmergencyAlert(
        latitude: position.latitude,
        longitude: position.longitude,
        type: 'urgence',
        dangerLevel: 5,
        description: 'Alerte SOS déclenchée depuis le plan d\'urgence',
      );
      
      // Notifier les contacts d'urgence
      final customMessage = _smsTemplateController.text.isNotEmpty 
          ? _smsTemplateController.text 
          : null;
      
      await LocalNotificationService.instance.notifyEmergencyContacts(
        alertId: alertId,
        latitude: position.latitude,
        longitude: position.longitude,
        customMessage: customMessage,
      );
      
      // Rediriger vers l'écran d'alerte active
      if (mounted) {
        context.go(AppConstants.routeVictimActiveAlert);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Alerte d\'urgence déclenchée !'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du déclenchement de l\'alerte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Affiche une confirmation pour déclencher l'alerte d'urgence
  Future<bool> _showEmergencyConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          '🚨 Alerte d\'Urgence',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir déclencher une alerte d\'urgence ?\n\n'
          'Cela va :\n'
          '• Envoyer votre position GPS\n'
          '• Notifier vos contacts d\'urgence\n'
          '• Démarrer l\'enregistrement automatique',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déclencher l\'Alerte'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _startEmergencyCallSequence(BuildContext context) async {
    HapticFeedback.mediumImpact();
    try {
      await EmergencyContactService.instance.callAllContactsWithFallback(
        callWindow: const Duration(seconds: 25),
        waitBetween: const Duration(seconds: 5),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur appel d\'urgence: $e')),
      );
    }
  }

  Future<void> _shareLocation(BuildContext context) async {
    HapticFeedback.selectionClick();
    try {
      final pos = await GeolocationService.instance.getCurrentPosition();
      final lat = pos.latitude.toStringAsFixed(6);
      final lon = pos.longitude.toStringAsFixed(6);
      final mapsUrl = 'https://maps.google.com/?q=$lat,$lon';
      final smsBody = Uri.encodeComponent('Voici ma position: $lat,$lon\n$mapsUrl');
      final smsUri = Uri.parse('sms:?body=$smsBody');

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } else {
        final mapUri = Uri.parse(mapsUrl);
        if (await canLaunchUrl(mapUri)) {
          await launchUrl(mapUri, mode: LaunchMode.externalApplication);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Lien de position prêt')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur partage position: $e')),
      );
    }
  }

  @override
  void dispose() {
    _emergencyInstructionsController.dispose();
    _safePlacesController.dispose();
    _escapeRoutesController.dispose();
    _medicalInfoController.dispose();
    _smsTemplateController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyPlan() async {
    setState(() => _isLoading = true);
    try {
      // Charger le plan d'urgence depuis le stockage local
      final instructions = StorageService.instance.getString('emergency_instructions') ?? '';
      final safePlaces = StorageService.instance.getString('safe_places') ?? '';
      final escapeRoutes = StorageService.instance.getString('escape_routes') ?? '';
      final medicalInfo = StorageService.instance.getString('medical_info') ?? '';
      final smsTemplate = StorageService.instance.getString('emergency_message_template') 
          ?? 'Alerte SOS – j\'ai besoin d\'aide.\nMa position: {lat},{lon}\n{link}';
      
      _emergencyInstructionsController.text = instructions;
      _safePlacesController.text = safePlaces;
      _escapeRoutesController.text = escapeRoutes;
      _medicalInfoController.text = medicalInfo;
      _smsTemplateController.text = smsTemplate;
      
      _emergencyPlan = {
        'instructions': instructions,
        'safe_places': safePlaces,
        'escape_routes': escapeRoutes,
        'medical_info': medicalInfo,
        'sms_template': smsTemplate,
      };
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveEmergencyPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final plan = {
        'instructions': _emergencyInstructionsController.text.trim(),
        'safe_places': _safePlacesController.text.trim(),
        'escape_routes': _escapeRoutesController.text.trim(),
        'medical_info': _medicalInfoController.text.trim(),
        'sms_template': _smsTemplateController.text.trim(),
        'last_updated': DateTime.now().toIso8601String(),
      };

      // Sauvegarder le plan d'urgence localement
      await StorageService.instance.saveString('emergency_instructions', _emergencyInstructionsController.text.trim());
      await StorageService.instance.saveString('safe_places', _safePlacesController.text.trim());
      await StorageService.instance.saveString('escape_routes', _escapeRoutesController.text.trim());
      await StorageService.instance.saveString('medical_info', _medicalInfoController.text.trim());
      await StorageService.instance.saveString('emergency_message_template', _smsTemplateController.text.trim());
      setState(() => _emergencyPlan = plan);
      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Plan d\'urgence sauvegardé avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur sauvegarde: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emergency, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Plan d\'Urgence',
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
            _isEditing ? 'Édition' : 'Consultation',
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
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            _buildEmergencyPlanSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
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
                  'Plan d\'Urgence Personnel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                                 Text(
                   'Définissez vos instructions, lieux sûrs, routes d\'évacuation et informations médicales pour une réponse d\'urgence optimale.',
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

  /// Section des actions rapides avec design professionnel
  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Actions d\'Urgence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.sos,
                  label: 'SOS',
                  color: Colors.red,
                  onTap: () => _navigateToSOS(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.phone,
                  label: 'Appel',
                  color: Colors.orange,
                  onTap: () => _startEmergencyCallSequence(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.location_on,
                  label: 'Position',
                  color: Colors.green,
                  onTap: () => _shareLocation(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bouton d'action rapide avec design moderne
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
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
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section du plan d'urgence avec design professionnel
  Widget _buildEmergencyPlanSection() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Configuration du Plan',
            icon: Icons.edit_note,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
                     _buildPlanField(
             controller: _emergencyInstructionsController,
             label: 'Instructions d\'Urgence',
             hint: 'Ex: Rester calme, appeler le 112, se mettre à l\'abri, alerter les voisins...',
             icon: Icons.assignment,
             color: Colors.red,
             maxLines: 3,
           ),
           const SizedBox(height: 16),
           _buildPlanField(
             controller: _safePlacesController,
             label: 'Lieux Sûrs',
             hint: 'Ex: École du quartier, mairie, église, maison de la famille Martin...',
             icon: Icons.location_on,
             color: Colors.green,
             maxLines: 2,
           ),
           const SizedBox(height: 16),
           _buildPlanField(
             controller: _escapeRoutesController,
             label: 'Routes d\'Évacuation',
             hint: 'Ex: Sortie arrière → Rue des Fleurs → Place du Marché',
             icon: Icons.directions_run,
             color: Colors.orange,
             maxLines: 2,
           ),
           const SizedBox(height: 16),
           _buildPlanField(
             controller: _medicalInfoController,
             label: 'Informations Médicales',
             hint: 'Ex: Allergie aux arachides, diabète type 2, groupe sanguin A+...',
             icon: Icons.medical_services,
             color: Colors.purple,
             maxLines: 2,
           ),
           const SizedBox(height: 16),
           _buildPlanField(
             controller: _smsTemplateController,
             label: 'Modèle de SMS',
             hint: 'Ex: URGENCE! J\'ai besoin d\'aide. Ma position: {lat},{lon}',
             icon: Icons.sms,
             color: Colors.blue,
             maxLines: 2,
           ),
        ],
      ),
    );
  }

  /// En-tête de section avec design professionnel
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
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
    );
  }

  /// Champ de plan avec design moderne
  Widget _buildPlanField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              enabled: _isEditing,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: color,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ce champ est obligatoire';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  /// État de chargement avec design moderne
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement du plan d\'urgence...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Boutons d'action avec design moderne
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: _isEditing ? 'Annuler' : 'Modifier',
            icon: _isEditing ? Icons.close : Icons.edit,
            color: _isEditing ? Colors.grey : AppTheme.secondaryColor,
            onTap: () {
              if (_isEditing) {
                _loadEmergencyPlan(); // Restaurer les valeurs
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: _isEditing ? 'Sauvegarder' : 'Actions Rapides',
            icon: _isEditing ? Icons.save : Icons.flash_on,
            color: _isEditing ? Colors.green : AppTheme.primaryColor,
            onTap: _isEditing ? _saveEmergencyPlan : () => _navigateToSOS(context),
          ),
        ),
      ],
    );
  }

  /// Bouton d'action avec design moderne
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
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
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

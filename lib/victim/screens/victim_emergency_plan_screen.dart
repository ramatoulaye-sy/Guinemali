import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/emergency_contact_service.dart';
import 'package:guinemali/core/services/geolocation_service.dart';

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
  void _navigateToSOS(BuildContext context) {
    HapticFeedback.heavyImpact();
    // Aller à l'écran principal où se trouve le bouton SOS
    if (mounted) {
      context.go('/victim/home');
      // Message clair pour guider l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Appuyez sur le bouton SOS rouge pour déclencher une alerte d\'urgence'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
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
          SnackBar(content: Text('Erreur lors du chargement: $e')),
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
      // Sauvegarder le plan d'urgence localement
      await StorageService.instance.saveString('emergency_instructions', _emergencyInstructionsController.text.trim());
      await StorageService.instance.saveString('safe_places', _safePlacesController.text.trim());
      await StorageService.instance.saveString('escape_routes', _escapeRoutesController.text.trim());
      await StorageService.instance.saveString('medical_info', _medicalInfoController.text.trim());
      await StorageService.instance.saveString('emergency_message_template', _smsTemplateController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan d\'urgence sauvegardé avec succès')),
        );
        setState(() => _isEditing = false);
        await _loadEmergencyPlan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
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
      appBar: AppBar(
        title: const Text('Plan d\'Urgence'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEmergencyHeader(),
                          const SizedBox(height: 24),
                          if (_isEditing) ...[
                            _buildEmergencyPlanForm(),
                            const SizedBox(height: 24),
                            _buildActionButtons(),
                          ] else ...[
                            _buildEmergencyPlanView(),
                          ],
                          const SizedBox(height: 24),
                          _buildEmergencyActions(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade200, width: 2),
            ),
            child: Icon(
              Icons.emergency,
              size: 48,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Votre Plan d\'Urgence',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          Text(
            'Personnalisez vos actions en cas d\'urgence',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyPlanForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions d\'Urgence',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextArea(
            controller: _emergencyInstructionsController,
            label: 'Que faire en cas d\'urgence ?',
            hint: 'Ex: Appeler immédiatement les services d\'urgence, se mettre en sécurité...',
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Les instructions d\'urgence sont requises';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Lieux de Sécurité',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextArea(
            controller: _safePlacesController,
            label: 'Où vous réfugier ?',
            hint: 'Ex: Chambre avec verrou, voisin de confiance, lieu public...',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Routes d\'Évacuation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextArea(
            controller: _escapeRoutesController,
            label: 'Comment vous échapper ?',
            hint: 'Ex: Sortie arrière, fenêtre de secours, escalier de service...',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Informations Médicales',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextArea(
            controller: _medicalInfoController,
            label: 'Informations importantes pour les secours',
            hint: 'Ex: Allergies, médicaments, conditions médicales...',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Message d\'urgence (SMS)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextArea(
            controller: _smsTemplateController,
            label: 'Modèle de SMS',
            hint: 'Utilisez {lat} {lon} {link} pour insérer la position',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le message d\'urgence est requis';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.black87),
      cursorColor: Colors.red,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildEmergencyPlanView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlanSection(
          'Instructions d\'Urgence',
          Icons.emergency,
          _emergencyPlan?['instructions'] ?? 'Aucune instruction définie',
          Colors.red,
        ),
        const SizedBox(height: 16),
        _buildPlanSection(
          'Lieux de Sécurité',
          Icons.location_on,
          _emergencyPlan?['safe_places'] ?? 'Aucun lieu défini',
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildPlanSection(
          'Routes d\'Évacuation',
          Icons.directions_run,
          _emergencyPlan?['escape_routes'] ?? 'Aucune route définie',
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildPlanSection(
          'Informations Médicales',
          Icons.medical_services,
          _emergencyPlan?['medical_info'] ?? 'Aucune information médicale',
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildPlanSection(
          'Message d\'urgence (SMS)',
          Icons.sms,
          (_emergencyPlan?['sms_template'] ?? '').toString().isEmpty
              ? 'Aucun message défini'
              : (_emergencyPlan?['sms_template'] ?? '') as String,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildPlanSection(String title, IconData icon, String content, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveEmergencyPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Sauvegarder'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() => _isEditing = false);
              _loadEmergencyPlan(); // Restaurer les valeurs originales
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Annuler'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions Rapides en Cas d\'Urgence',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.sos,
                title: 'Déclencher SOS',
                subtitle: 'Alerte immédiate',
                color: Colors.red,
                onTap: () => _navigateToSOS(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.phone,
                title: 'Appel Urgence',
                subtitle: 'Contacter les secours',
                color: Colors.orange,
                onTap: () => _startEmergencyCallSequence(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.location_on,
                title: 'Partager Position',
                subtitle: 'Envoyer votre localisation',
                color: Colors.blue,
                onTap: () => _shareLocation(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.record_voice_over,
                title: 'Enregistrer Preuve',
                subtitle: 'Capturer des éléments',
                color: Colors.green,
                onTap: () => context.push('/victim/record-evidence'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

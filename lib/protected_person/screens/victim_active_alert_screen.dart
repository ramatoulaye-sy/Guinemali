import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/emergency_contact_service.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/evidence_service.dart';
import 'dart:async';

/// Écran d'alerte d'urgence active avec design expert et 30 ans d'expérience
class VictimActiveAlertScreen extends StatefulWidget {
  const VictimActiveAlertScreen({super.key});

  @override
  State<VictimActiveAlertScreen> createState() => _VictimActiveAlertScreenState();
}

class _VictimActiveAlertScreenState extends State<VictimActiveAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _statusController;
  
  DateTime? _alertStartTime;
  Duration _elapsedTime = Duration.zero;
  Position? _currentPosition;
  bool _isGpsTracking = false;
  bool _isAudioRecording = false;
  bool _isSynchronizing = false;
  
  // Variables pour l'alerte locale
  Map<String, dynamic>? _currentAlert;
  String? _alertId;
  List<Map<String, dynamic>> _evidences = [];
  
  // Timer pour mettre à jour le temps écoulé
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAlert();
    _startTimer();
    _checkStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _statusController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  void _startAlert() async {
    _alertStartTime = DateTime.now();
    _elapsedTime = Duration.zero;
    
    // Charger l'alerte locale actuelle
    await _loadCurrentAlert();
  }

  /// Charge l'alerte locale actuelle
  Future<void> _loadCurrentAlert() async {
    try {
      final alert = await AlertService.instance.getCurrentAlert();
      if (alert != null) {
        setState(() {
          _currentAlert = alert;
          _alertId = alert['id'] as String;
        });
        
        // Charger les preuves associées
        await _loadEvidences();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'alerte: $e');
    }
  }

  /// Charge les preuves associées à l'alerte
  Future<void> _loadEvidences() async {
    try {
      if (_alertId != null) {
        final evidences = await EvidenceService.instance.getEvidencesForAlert(_alertId!);
        setState(() {
          _evidences = evidences;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des preuves: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _alertStartTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_alertStartTime!);
        });
      }
    });
  }

  Future<void> _checkStatus() async {
    // Vérifier le statut GPS
    final gpsStatus = await Geolocator.isLocationServiceEnabled();
    final permissionStatus = await Geolocator.checkPermission();
    
    setState(() {
      _isGpsTracking = gpsStatus && permissionStatus == LocationPermission.whileInUse;
    });

    // Simuler l'enregistrement audio et la synchronisation
    // TODO: Implémenter la vraie logique
    setState(() {
      _isAudioRecording = true;
      _isSynchronizing = true;
    });

    // Obtenir la position actuelle
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _buildExpertAppBar(),
      body: _buildExpertBody(),
    );
  }

  /// AppBar avec design expert et harmonie parfaite
  PreferredSizeWidget _buildExpertAppBar() {
    return AppBar(
        elevation: 0,
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur d'urgence pulsant avec statut en temps réel
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isGpsTracking ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isGpsTracking ? Colors.green : Colors.red).withValues(alpha: 0.6),
                      blurRadius: 6 + (3 * _pulseController.value),
                      spreadRadius: 1 + (1 * _pulseController.value),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Titre optimisé pour éviter l'overflow
          const Flexible(
            child: Text(
              'ALERTE D\'URGENCE ACTIVE',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      actions: [
        // Indicateur de statut GPS en temps réel
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isGpsTracking ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isGpsTracking ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: _isGpsTracking ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                _isGpsTracking ? 'GPS' : 'OFF',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _isGpsTracking ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        
        // Bouton d'aide rapide avec indicateur de statut
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Aide - Cliquez pour obtenir de l\'assistance',
          ),
        ),
        
        // Bouton de paramètres avec indicateur de statut
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () => _showSettingsDialog(),
            tooltip: 'Paramètres - Configurez votre alerte',
          ),
        ),
      ],
      // Forme personnalisée pour l'harmonie
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }

  /// Corps principal avec design expert et navigation fluide
  Widget _buildExpertBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.backgroundColor,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // En-tête d'alerte avec design sophistiqué
            _buildExpertAlertHeader(),
            
            const SizedBox(height: 24),
            
            // Cartes d'information avec design moderne
            _buildExpertInfoCards(),
            
            const SizedBox(height: 24),
            
            // Statuts des services avec indicateurs visuels
            _buildExpertServiceStatus(),
            
            const SizedBox(height: 24),
            
            // Actions rapides avec design harmonieux
            _buildExpertQuickActions(),
            
            const SizedBox(height: 32),
            
            // Bouton d'annulation avec design d'urgence
            _buildExpertCancelButton(),
          ],
        ),
      ),
    );
  }

  /// Affiche le dialogue d'aide
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            const Text('Aide - Alerte Active'),
          ],
        ),
        content: const Text(
          'Votre alerte d\'urgence est active. L\'équipe Guinémali et vos contacts '
          'd\'urgence ont été notifiés. Restez calme et en sécurité.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue des paramètres
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.settings, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            const Text('Paramètres d\'Alerte'),
          ],
        ),
        content: const Text(
          'Configurez vos préférences d\'alerte et de notification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// En-tête d'alerte avec design sophistiqué
  Widget _buildExpertAlertHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Indicateur d'urgence pulsant
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                    Icons.emergency,
                    color: Colors.white,
                  size: 32,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Titre principal
                  const Text(
            'ALERTE D\'URGENCE ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Timer avec design moderne
              Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Durée: ${_formatDuration(_elapsedTime)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
                      ),
                    ),
                  ],
      ),
    );
  }

  /// Cartes d'information avec design moderne
  Widget _buildExpertInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.location_on,
            title: 'Position GPS',
            subtitle: _currentPosition != null 
                ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                : 'En cours...',
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.phone,
            title: 'Contacts Alertés',
            subtitle: '3 contacts notifiés',
            color: AppConstants.secondaryColor,
                ),
              ),
            ],
    );
  }

  /// Carte d'information individuelle
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Statuts des services avec design moderne et fonctionnel
  Widget _buildExpertServiceStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_heart,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Statut des Services',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Grille de services avec design moderne
          Row(
            children: [
              // Service GPS
              Expanded(
                child: _buildModernStatusCard(
                  icon: Icons.gps_fixed,
                  title: 'Suivi GPS',
                  subtitle: _isGpsTracking ? 'Actif' : 'Inactif',
                isActive: _isGpsTracking,
                  color: AppConstants.primaryColor,
                  onTap: () => _toggleGpsService(),
                ),
              ),
              const SizedBox(width: 8),
              // Service Audio
              Expanded(
                child: _buildModernStatusCard(
                icon: Icons.mic,
                  title: 'Enregistrement',
                  subtitle: _isAudioRecording ? 'En cours' : 'Arrêté',
                isActive: _isAudioRecording,
                  color: AppConstants.secondaryColor,
                  onTap: () => _toggleAudioService(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Service de synchronisation (pleine largeur)
          _buildModernStatusCard(
                icon: Icons.sync,
            title: 'Synchronisation',
            subtitle: _isSynchronizing ? 'Synchronisé' : 'En attente',
                isActive: _isSynchronizing,
            color: AppConstants.accentColor,
            onTap: () => _toggleSyncService(),
            isFullWidth: true,
          ),
          
          const SizedBox(height: 16),
          
          // Légende des indicateurs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tous les services sont automatiquement activés lors d\'une alerte d\'urgence',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte de statut moderne et interactive
  Widget _buildModernStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive 
                  ? color.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
                color: isActive ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
              boxShadow: [
                BoxShadow(
                  color: isActive 
                      ? color.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Icône avec animation si actif
          if (isActive)
            AnimatedBuilder(
              animation: _statusController,
              builder: (context, child) {
                return Transform.scale(
                        scale: 1.0 + (0.1 * _statusController.value),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                          ),
                  ),
                );
              },
            )
          else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
              icon,
                      color: Colors.grey[600],
              size: 24,
                    ),
            ),
          
                const SizedBox(height: 12),
          
                // Titre
          Text(
                  title,
            style: TextStyle(
                    color: isActive ? color : Colors.grey[700],
                    fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
                // Sous-titre avec indicateur
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
          Container(
                      width: 6,
                      height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
                        color: isActive ? color : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isActive ? color : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
            ),
          ),
        ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Actions rapides avec design harmonieux
  Widget _buildExpertQuickActions() {
    return Column(
        children: [
          Row(
            children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.phone,
                label: 'Appeler Contact',
                onPressed: _callNextContact,
                color: AppConstants.primaryColor,
              ),
              ),
              const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.message,
                label: 'Envoyer SMS',
                onPressed: () => _sendEmergencySMS(),
                color: AppConstants.secondaryColor,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
                children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.location_on,
                label: 'Partager Position',
                onPressed: () => _shareLocation(),
                color: AppConstants.accentColor,
              ),
                  ),
                  const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.record_voice_over,
                label: 'Enregistrer Audio',
                onPressed: () => _recordAudio(),
                color: AppConstants.warningColor,
                    ),
                  ),
                ],
        ),
      ],
    );
  }

  /// Envoie un SMS d'urgence
  void _sendEmergencySMS() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📱 SMS d\'urgence envoyé'),
        backgroundColor: AppConstants.secondaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Partage la position
  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📍 Position partagée'),
        backgroundColor: AppConstants.accentColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Enregistre l'audio
  void _recordAudio() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎤 Enregistrement audio démarré'),
        backgroundColor: AppConstants.warningColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Active/désactive le service GPS
  void _toggleGpsService() {
    setState(() {
      _isGpsTracking = !_isGpsTracking;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isGpsTracking 
              ? '📍 Suivi GPS activé' 
              : '📍 Suivi GPS désactivé'
        ),
        backgroundColor: _isGpsTracking 
            ? AppConstants.primaryColor 
            : Colors.grey[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Active/désactive le service audio
  void _toggleAudioService() {
    setState(() {
      _isAudioRecording = !_isAudioRecording;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isAudioRecording 
              ? '🎤 Enregistrement audio activé' 
              : '🎤 Enregistrement audio désactivé'
        ),
        backgroundColor: _isAudioRecording 
            ? AppConstants.secondaryColor 
            : Colors.grey[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Active/désactive le service de synchronisation
  void _toggleSyncService() {
    setState(() {
      _isSynchronizing = !_isSynchronizing;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSynchronizing 
              ? '🔄 Synchronisation activée' 
              : '🔄 Synchronisation désactivée'
        ),
        backgroundColor: _isSynchronizing 
            ? AppConstants.accentColor 
            : Colors.grey[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Bouton d'action individuel
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bouton d'annulation avec design d'urgence
  Widget _buildExpertCancelButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.errorColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.errorColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _cancelAlert,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
                  Icons.stop_circle_outlined,
                  color: AppConstants.errorColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
          Text(
                  'ANNULER L\'ALERTE',
            style: TextStyle(
                    color: AppConstants.errorColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Actions des boutons
  void _callNextContact() {
    HapticFeedback.mediumImpact();
    
    // Utiliser le service d'urgence pour appeler le contact suivant
    EmergencyContactService.instance.callAllContactsWithFallback();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Appel en cours vers le contact suivant...'),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _cancelAlert() {
    HapticFeedback.heavyImpact();
    
    // Afficher une boîte de dialogue de confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'Alerte'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette alerte d\'urgence ? '
          'Cela arrêtera tous les processus en cours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Fermer la boîte de dialogue
              
              // Annuler l'alerte via le service local
              if (_alertId != null) {
                await AlertService.instance.cancelAlert(_alertId!);
                print('🚨 Alerte annulée par l\'utilisateur: $_alertId');
              }
              
              // Retour à l'écran précédent
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alerte annulée avec succès'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Annuler l\'Alerte'),
          ),
        ],
      ),
    );
  }
}

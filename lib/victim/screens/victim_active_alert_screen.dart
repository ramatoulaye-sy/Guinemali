import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/emergency_contact_service.dart';
import 'dart:async';

/// Écran d'alerte d'urgence active avec toutes les fonctionnalités
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

  void _startAlert() {
    _alertStartTime = DateTime.now();
    _elapsedTime = Duration.zero;
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Alerte d\'Urgence'),
        backgroundColor: AppTheme.emergencyColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bloc principal d'alerte
            _buildAlertBlock(),
            
            const SizedBox(height: 24),
            
            // Bloc de position
            _buildPositionBlock(),
            
            const SizedBox(height: 24),
            
            // Bouton d'appel au contact suivant
            _buildCallNextContactButton(),
            
            const SizedBox(height: 24),
            
            // Bouton d'annulation de l'alerte
            _buildCancelAlertButton(),
            
            const SizedBox(height: 24),
            
            // Message de réconfort
            _buildComfortMessage(),
          ],
        ),
      ),
    );
  }

  /// Construit le bloc principal d'alerte
  Widget _buildAlertBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.emergencyColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emergencyColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec titre et timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Titre de l'alerte
              Row(
                children: [
                  Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Alerte d\'urgence active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Timer avec icône
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_elapsedTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Statuts GPS, Audio et Sync
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusItem(
                icon: Icons.location_on,
                label: 'Tracking GPS',
                isActive: _isGpsTracking,
                color: AppTheme.successColor,
              ),
              _buildStatusItem(
                icon: Icons.mic,
                label: 'Enregistrement\nAudio Auto',
                isActive: _isAudioRecording,
                color: AppTheme.warningColor,
              ),
              _buildStatusItem(
                icon: Icons.sync,
                label: 'Synchronisation',
                isActive: _isSynchronizing,
                color: AppTheme.infoColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit un élément de statut
  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive 
            ? color.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icône avec animation si actif
          if (isActive)
            AnimatedBuilder(
              animation: _statusController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (0.2 * _statusController.value),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                );
              },
            )
          else
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
          
          const SizedBox(height: 8),
          
          // Label
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          // Indicateur de statut
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le bloc de position
  Widget _buildPositionBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du bloc position
          Row(
            children: [
              Icon(
                Icons.my_location,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Votre position',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Affichage de la position
          if (_currentPosition != null) ...[
            _buildPositionInfo('Latitude', _currentPosition!.latitude.toStringAsFixed(6)),
            const SizedBox(height: 8),
            _buildPositionInfo('Longitude', _currentPosition!.longitude.toStringAsFixed(6)),
            const SizedBox(height: 8),
            _buildPositionInfo('Précision', '±${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
            const SizedBox(height: 8),
            _buildPositionInfo('Altitude', '${_currentPosition!.altitude.toStringAsFixed(1)}m'),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_off,
                    color: AppTheme.textSecondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Position en cours de récupération...',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontStyle: FontStyle.italic,
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

  /// Construit une information de position
  Widget _buildPositionInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  /// Construit le bouton d'appel au contact suivant
  Widget _buildCallNextContactButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _callNextContact,
        icon: const Icon(Icons.phone),
        label: const Text('Appeler Contact Suivant'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  /// Construit le bouton d'annulation de l'alerte
  Widget _buildCancelAlertButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _cancelAlert,
        icon: const Icon(Icons.stop),
        label: const Text('Annuler l\'Alerte'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorColor,
          side: BorderSide(color: AppTheme.errorColor, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Construit le message de réconfort
  Widget _buildComfortMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            color: AppTheme.secondaryColor,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            'Vous n\'êtes pas seul(e)',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Notre équipe et vos contacts d\'urgence sont mobilisés pour vous aider. '
            'Restez calme et en sécurité.',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            onPressed: () {
              Navigator.of(context).pop(); // Fermer la boîte de dialogue
              
              // TODO: Implémenter la logique d'annulation de l'alerte
              print('🚨 Alerte annulée par l\'utilisateur');
              
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

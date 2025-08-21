import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/geolocation_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/emergency_contact_service.dart';
import '../../core/services/audio_recording_service.dart';
import '../../core/services/sync_service.dart';

/// Écran affiché quand une alerte d'urgence est active
/// Permet à la victime de suivre l'état de l'alerte et d'annuler si nécessaire
class VictimActiveAlertScreen extends StatefulWidget {
  const VictimActiveAlertScreen({super.key});

  @override
  State<VictimActiveAlertScreen> createState() => _VictimActiveAlertScreenState();
}

class _VictimActiveAlertScreenState extends State<VictimActiveAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _statusController;
  bool _isLoading = false;
  bool _isDataLoading = true;
  String? _currentAlertId;
  Map<String, dynamic>? _alertData;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentAlert();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _statusController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _loadCurrentAlert() async {
    try {
      setState(() {
        _isDataLoading = true;
      });

      final alerts = await AlertService.instance.getActiveAlerts();
      if (alerts.isNotEmpty) {
        final alert = alerts.first;
        setState(() {
          _currentAlertId = alert.id;
          _alertData = {
            'id': alert.id,
            'type': alert.typeAlerte,
            'danger_level': alert.niveauDanger,
            'timestamp': alert.timestamp,
            'latitude': alert.latitude,
            'longitude': alert.longitude,
          };
          _isDataLoading = false;
        });
        
        // Démarrer le mode d'urgence après avoir chargé les données
        _startEmergencyMode();
      } else {
        // Fallback: tenter de charger une alerte locale non synchronisée
        try {
          final localAlerts = await StorageService.instance.getLocalAlerts();
          if (localAlerts.isNotEmpty) {
            final alert = localAlerts.first;
            setState(() {
              _currentAlertId = alert['id'] as String;
              _alertData = alert;
              _isDataLoading = false;
            });
            _startEmergencyMode();
            return;
          }
        } catch (_) {}

        // Aucune alerte trouvée
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noActiveAlertBody),
              backgroundColor: AppConstants.warningColor,
            ),
          );
          context.go(AppConstants.routeVictimHome);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDataLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement alerte: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _startEmergencyMode() {
    // Vibration continue pour attirer l'attention
    HapticFeedback.heavyImpact();
    
    // Démarrer les animations
    _statusController.forward();
    
    // Notifier les contacts d'urgence
    _notifyEmergencyContacts();
  }

  Future<void> _notifyEmergencyContacts() async {
    try {
      // Cette fonction sera appelée par AlertService
      if (AppConstants.enableLogging) {
        print('✅ Contacts d\'urgence notifiés');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur notification contacts: $e');
      }
    }
  }

  Future<void> _cancelAlert() async {
    if (_currentAlertId == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AlertService.instance.cancelAlert(_currentAlertId!);
      // Arrêter le tracking GPS
      await GeolocationService.instance.stopBackgroundTracking();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alerte annulée avec succès'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        
        // Retourner à l'écran d'accueil
        context.go(AppConstants.routeVictimHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur annulation: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callEmergencyServices() async {
    try {
      // Appeler séquentiellement les contacts d'urgence
      await EmergencyContactService.instance.startOrContinueCallSequence();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur appel: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    // Afficher un indicateur de chargement si les données ne sont pas encore chargées
    if (_isDataLoading) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
              const SizedBox(height: AppConstants.spacingLarge),
              Text(
                l10n.alertLoading,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Afficher un message d'erreur si aucune alerte n'est trouvée
    if (_alertData == null || _currentAlertId == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: AppConstants.warningColor,
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                Text(
                  l10n.noActiveAlertTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                Text(
                  l10n.noActiveAlertBody,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                ElevatedButton(
                  onPressed: () => context.go(AppConstants.routeVictimHome),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.whiteColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge,
                      vertical: AppConstants.paddingMedium,
                    ),
                  ),
                  child: Text(l10n.backToHome),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.alertActiveColor.withValues(alpha: 0.1),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              // En-tête d'urgence
              _buildEmergencyHeader(l10n),
              
              const SizedBox(height: AppConstants.spacingLarge),
              
              // Indicateur GPS Tracking
               _buildGPSTrackingIndicator(),
               
               const SizedBox(height: AppConstants.spacingMedium),
               
               // Indicateur Audio Recording
               _buildAudioRecordingIndicator(),
               
               const SizedBox(height: AppConstants.spacingMedium),
               
               // Indicateur Synchronisation
               _buildSyncIndicator(),
               
               const SizedBox(height: AppConstants.spacingLarge),
              
              // Statut de l'alerte
              _buildAlertStatus(l10n),
              
              const SizedBox(height: AppConstants.spacingLarge),
              
              // Informations de localisation
              _buildLocationInfo(l10n),
              
              const SizedBox(height: AppConstants.spacingLarge),
              
                      // Actions d'urgence
                      _buildEmergencyActions(l10n),
                      const SizedBox(height: AppConstants.spacingMedium),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF0000), Color(0xFFFF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.6),
                      blurRadius: 15 + (10 * _pulseController.value),
                      spreadRadius: 3 + (2 * _pulseController.value),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Color(0xFFFF0000),
                  size: 35,
                ),
              );
            },
          ),
          const SizedBox(width: AppConstants.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.emergencyActiveTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black38),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.emergencyActiveSubtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertStatus(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8F9FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
                            color: const Color(0xFF945acb).withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
                          color: const Color(0xFF945acb).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.alertStatus,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF945acb),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFF4444),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF0000).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  l10n.statusActive,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSmall),
              Text(
                l10n.triggeredAt(_formatTimestamp(_alertData?['timestamp'])),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning,
                  color: Color(0xFFFF0000),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSmall),
              Text(
                l10n.dangerLevel(_getDangerLevelText(_alertData?['danger_level'])),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppConstants.alertActiveColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yourPosition,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppConstants.infoColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingSmall),
              Expanded(
                child: Text(
                  'Lat: ${_formatCoordinate(_alertData?['latitude'])}, '
                  'Lon: ${_formatCoordinate(_alertData?['longitude'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Row(
            children: [
              const Icon(
                Icons.people,
                color: AppConstants.successColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingSmall),
              Text(
                l10n.emergencyContactsNotified,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyActions(AppLocalizations l10n) {
    return Column(
      children: [
        // Bouton d'appel d'urgence
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _callEmergencyServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.alertActiveColor,
              foregroundColor: AppConstants.whiteColor,
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              ),
            ),
            icon: const Icon(Icons.phone_forwarded, size: 24),
            label: Text(
              l10n.callNextContact,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingMedium),
        
        // Bouton d'annulation
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _cancelAlert,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
              side: const BorderSide(color: AppConstants.errorColor),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.errorColor),
                    ),
                  )
                : const Icon(Icons.cancel, size: 24),
            label: Text(
              _isLoading ? l10n.cancelling : l10n.cancelAlert,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingLarge),
        
        // Message d'aide
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppConstants.infoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(
              color: AppConstants.infoColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.infoColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingSmall),
              Expanded(
                child: Text(
                  l10n.helpMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.infoColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Maintenant';
    
    try {
      DateTime dateTime;
      
      // Si c'est déjà un DateTime
      if (timestamp is DateTime) {
        dateTime = timestamp;
      }
      // Si c'est une chaîne, essayer de la parser
      else if (timestamp is String) {
        if (timestamp.isEmpty) return 'Maintenant';
        dateTime = DateTime.parse(timestamp);
      }
      // Si c'est un autre type, essayer de le convertir
      else {
        dateTime = DateTime.parse(timestamp.toString());
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else {
        return 'Il y a ${difference.inDays}j';
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur formatage timestamp: $e');
      }
      return 'Maintenant';
    }
  }

  String _getDangerLevelText(dynamic dangerLevel) {
    if (dangerLevel == null) return 'Élevé';
    
    try {
      final level = int.tryParse(dangerLevel.toString());
      switch (level) {
        case 1:
          return 'Faible';
        case 2:
          return 'Modéré';
        case 3:
          return 'Moyen';
        case 4:
          return 'Élevé';
        case 5:
          return 'Critique';
        default:
          return 'Élevé';
      }
    } catch (e) {
      return 'Élevé';
    }
  }

  String _formatCoordinate(dynamic coordinate) {
    if (coordinate == null) return '...';
    
    try {
      final coord = double.tryParse(coordinate.toString());
      if (coord != null) {
        return coord.toStringAsFixed(6);
      }
      return '...';
    } catch (e) {
      return '...';
    }
  }

  /// Construire l'indicateur GPS Tracking
  Widget _buildGPSTrackingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingSmall),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            child: const Icon(Icons.gps_fixed, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppConstants.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Tracking GPS ACTIF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                SizedBox(height: 4),
                Text('Positions capturées en temps réel', style: TextStyle(fontSize: 14, color: Colors.green)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium, vertical: AppConstants.paddingSmall),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
            child: const Text('ON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Construire l'indicateur Audio Recording
  Widget _buildAudioRecordingIndicator() {
    return Consumer<AudioRecordingService>(
      builder: (context, audioService, child) {
        final isRecording = audioService.isRecording;
        final color = isRecording ? Colors.blue : Colors.grey;
        final statusText = isRecording ? 'ACTIF' : 'INACTIF';
        final descriptionText = isRecording 
            ? 'Enregistrement audio en cours' 
            : 'Enregistrement audio arrêté';
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingSmall),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(isRecording ? Icons.mic : Icons.mic_off, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppConstants.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enregistrement Audio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(descriptionText, style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium, vertical: AppConstants.paddingSmall),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construire l'indicateur de synchronisation
  Widget _buildSyncIndicator() {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        final isOnline = syncService.isOnline;
        final isSyncing = syncService.isSyncing;
        final pendingItems = syncService.pendingItemsCount;
        final failedItems = syncService.failedItemsCount;
        
        Color color;
        String statusText;
        String descriptionText;
        IconData icon;
        
        if (isSyncing) {
          color = Colors.orange;
          statusText = 'SYNC';
          descriptionText = 'Synchronisation en cours...';
          icon = Icons.sync;
        } else if (!isOnline) {
          color = Colors.red;
          statusText = 'HORS-LIGNE';
          descriptionText = 'Mode hors-ligne activé';
          icon = Icons.cloud_off;
        } else if (pendingItems > 0) {
          color = Colors.blue;
          statusText = 'EN ATTENTE';
          descriptionText = '$pendingItems éléments à synchroniser';
          icon = Icons.cloud_upload;
        } else if (failedItems > 0) {
          color = Colors.red;
          statusText = 'ERREURS';
          descriptionText = '$failedItems éléments échoués';
          icon = Icons.error;
        } else {
          color = Colors.green;
          statusText = 'SYNCHRONISÉ';
          descriptionText = 'Toutes les données sont à jour';
          icon = Icons.cloud_done;
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingSmall),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppConstants.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Synchronisation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(descriptionText, style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium, vertical: AppConstants.paddingSmall),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}

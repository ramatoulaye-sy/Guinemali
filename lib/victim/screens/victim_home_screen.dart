import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/app_constants.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/geolocation_service.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/evidence_service.dart';
import '../../core/services/audio_recording_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/widgets/responsive_builder.dart';
import '../../core/widgets/loading_widgets.dart';
import '../../core/widgets/accessibility_widgets.dart';
import '../../core/widgets/gesture_navigation.dart';
import '../widgets/sos_button.dart';
import '../widgets/quick_actions_panel.dart';
import '../widgets/victim_status_card.dart';
import '../widgets/emergency_plan_widget.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/storage_service.dart';

/// Écran d'accueil principal pour les victimes
/// Contient le bouton SOS animé et les actions rapides
class VictimHomeScreen extends StatefulWidget {
  const VictimHomeScreen({super.key});

  @override
  State<VictimHomeScreen> createState() => _VictimHomeScreenState();
}

class _VictimHomeScreenState extends State<VictimHomeScreen>
    with TickerProviderStateMixin, AccessibilityMixin {
  late AnimationController _pulseController;
  late AnimationController _backgroundController;
  bool _isEmergencyMode = false;
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkLocationPermission();
    _initializeEvidenceService();
    _ensureUserLoaded();
  }

  /// S'assure que l'utilisateur est chargé
  Future<void> _ensureUserLoaded() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        if (AppConstants.enableLogging) {
          print('⚠️ Utilisateur non chargé, tentative de rechargement...');
        }
        authProvider.refreshUser();
      } else {
        if (AppConstants.enableLogging) {
          print('✅ Utilisateur chargé: ${authProvider.currentUser!.prenom}');
        }
      }
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _checkLocationPermission() async {
    // Vérifier les permissions de géolocalisation au démarrage
    try {
      await GeolocationService.instance.checkPermissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions de localisation requises: $e'),
            backgroundColor: AppConstants.warningColor,
          ),
        );
      }
    }
  }

  Future<void> _initializeEvidenceService() async {
    // Initialiser le service d'enregistrement des preuves
    try {
      await EvidenceService.instance.initialize();
      if (AppConstants.enableLogging) {
        print('✅ EvidenceService initialisé');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur initialisation EvidenceService: $e');
      }
    }
  }

  /// Rafraîchir les données
  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Recharger l'utilisateur
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUser();

      // Vérifier les permissions
      await _checkLocationPermission();

      // Initialiser les services
      await _initializeEvidenceService();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Données rafraîchies'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors du rafraîchissement: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _triggerEmergencyAlert() async {
    if (_isLoading) return;

    // Vérifier que l'utilisateur est connecté
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur: Utilisateur non connecté. Veuillez vous reconnecter.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _isEmergencyMode = true;
    });

    try {
      if (AppConstants.enableLogging) {
        print('🚨 Déclenchement de l\'alerte SOS...');
        print('👤 Utilisateur: ${authProvider.currentUser!.prenom} (ID: ${authProvider.currentUser!.id})');
      }

      // Vibration tactile
      HapticFeedback.heavyImpact();
      
      // Animation d'urgence
      _backgroundController.forward();

      // Obtenir la position actuelle avec fallback
      Position? position;
      double latitude = 0.0;
      double longitude = 0.0;
      try {
        position = await GeolocationService.instance.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (e) {
        if (AppConstants.enableLogging) {
          print('⚠️ Position actuelle indisponible, tentative avec dernière position connue: $e');
        }
        position = await GeolocationService.instance.getLastKnownPosition();
        if (position != null) {
          latitude = position.latitude;
          longitude = position.longitude;
        } else {
          if (AppConstants.enableLogging) {
            print('⚠️ Aucune position disponible, utilisation de (0,0)');
          }
        }
      }
      
      if (AppConstants.enableLogging) {
        print('📍 Position obtenue: $latitude, $longitude');
      }
      
      // Déclencher l'alerte
      final alertId = await AlertService.instance.createEmergencyAlert(
        latitude: latitude,
        longitude: longitude,
        type: 'urgence',
        dangerLevel: 5,
      );

      if (AppConstants.enableLogging) {
        print('🚨 Alerte créée avec ID: $alertId');
      }

      // Démarrer l'enregistrement automatique des preuves
      if (alertId.isNotEmpty) {
        try {
          await EvidenceService.instance.startEvidenceRecording(alertId);
          if (AppConstants.enableLogging) {
            print('📹 Enregistrement des preuves démarré');
          }
        } catch (e) {
          if (AppConstants.enableLogging) {
            print('⚠️ Erreur enregistrement preuves: $e');
          }
          // Continuer même si l'enregistrement échoue
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 ALERTE DÉCLENCHÉE - Aide en route'),
            backgroundColor: AppConstants.alertActiveColor,
          ),
        );
      }

      // Rediriger vers l'écran d'alerte active
      if (mounted) {
        // Stocker l'ID pour l'écran des preuves
        try { await StorageService.instance.saveString(AppConstants.keyCurrentAlertId, alertId); } catch (_) {}
        context.push(AppConstants.routeVictimActiveAlert);
      }

    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors du déclenchement de l\'alerte: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du déclenchement: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // On garde le fond d'urgence jusqu'à l'écran suivant
        });
        // Le fond sera réinitialisé à la sortie de l'écran
      }
    }
  }

  /// Méthode de test pour vérifier que les boutons fonctionnent
  void _testButtonFunctionality() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Test: Bouton fonctionne correctement'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isEmergencyMode
                    ? [
                        const Color(0xFFFF0000).withValues(alpha: 0.1),
                        const Color(0xFFFF0000).withValues(alpha: 0.05),
                      ]
                    : [
                        const Color(0xFFF8F9FA),
                        const Color(0xFFF0F0F0),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: RefreshableWidget(
                onRefresh: _refreshData,
                isLoading: _isRefreshing,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: ResponsivePadding.mobile,
                          child: ResponsiveBuilder(
                            mobile: _buildMobileLayout(l10n, user),
                            tablet: _buildTabletLayout(l10n, user),
                            desktop: _buildDesktopLayout(l10n, user),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Layout pour mobile
  Widget _buildMobileLayout(AppLocalizations l10n, user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // En-tête avec image de fond
        _buildHeader(l10n.helloUser(user?.prenom ?? '')),
        
        const SizedBox(height: AppConstants.spacingLarge),
        
        // Carte de statut de sécurité
        Consumer2<AudioRecordingService, SyncService>(
          builder: (context, audio, sync, _) {
            final gpsActive = false; // TODO: Implémenter isTracking dans GeolocationService
            return VictimStatusCard(
              gpsActive: gpsActive,
              audioActive: audio.isRecording,
              online: sync.isOnline,
              syncing: sync.isSyncing,
              pendingItems: sync.pendingItemsCount,
              failedItems: sync.failedItemsCount,
            );
          },
        ),
        
        const SizedBox(height: AppConstants.spacingLarge),
        
        // Bouton SOS principal
        Center(
          child: SOSButton(
            onPressed: _triggerEmergencyAlert,
            isLoading: _isLoading,
            pulseController: _pulseController,
          ),
        ),
        
        const SizedBox(height: AppConstants.spacingLarge),
        
        // Panneau d'actions rapides
        const QuickActionsPanel(),
        
        const SizedBox(height: AppConstants.spacingLarge),

        // Résumé du plan d'urgence
        EmergencyPlanWidget(
          instructions: '',
          safePlaces: '',
          escapeRoutes: '',
          medicalInfo: '',
          onOpenPlan: () => context.push('/victim/emergency-plan'),
        ),
        
        const SizedBox(height: AppConstants.spacingMedium),
      ],
    );
  }

  /// Layout pour tablette
  Widget _buildTabletLayout(AppLocalizations l10n, user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne gauche (en-tête + SOS)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildHeader(l10n.helloUser(user?.prenom ?? '')),
              const SizedBox(height: AppConstants.spacingLarge),
              Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: SOSButton(
                    onPressed: _triggerEmergencyAlert,
                    isLoading: _isLoading,
                    pulseController: _pulseController,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Colonne droite (statut + actions)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Consumer2<AudioRecordingService, SyncService>(
                builder: (context, audio, sync, _) {
                  final gpsActive = false; // TODO: Implémenter isTracking dans GeolocationService
                  return VictimStatusCard(
                    gpsActive: gpsActive,
                    audioActive: audio.isRecording,
                    online: sync.isOnline,
                    syncing: sync.isSyncing,
                    pendingItems: sync.pendingItemsCount,
                    failedItems: sync.failedItemsCount,
                  );
                },
              ),
              const SizedBox(height: AppConstants.spacingLarge),
              const QuickActionsPanel(),
              const SizedBox(height: AppConstants.spacingLarge),
              EmergencyPlanWidget(
                instructions: '',
                safePlaces: '',
                escapeRoutes: '',
                medicalInfo: '',
                onOpenPlan: () => context.push('/victim/emergency-plan'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Layout pour desktop
  Widget _buildDesktopLayout(AppLocalizations l10n, user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne gauche (en-tête + statut)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildHeader(l10n.helloUser(user?.prenom ?? '')),
              const SizedBox(height: AppConstants.spacingLarge),
              Consumer2<AudioRecordingService, SyncService>(
                builder: (context, audio, sync, _) {
                  final gpsActive = false; // TODO: Implémenter isTracking dans GeolocationService
                  return VictimStatusCard(
                    gpsActive: gpsActive,
                    audioActive: audio.isRecording,
                    online: sync.isOnline,
                    syncing: sync.isSyncing,
                    pendingItems: sync.pendingItemsCount,
                    failedItems: sync.failedItemsCount,
                  );
                },
              ),
            ],
          ),
        ),
        
        // Colonne centrale (SOS)
        Expanded(
          flex: 2,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: SOSButton(
                onPressed: _triggerEmergencyAlert,
                isLoading: _isLoading,
                pulseController: _pulseController,
              ),
            ),
          ),
        ),
        
        // Colonne droite (actions + plan)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const QuickActionsPanel(),
              const SizedBox(height: AppConstants.spacingLarge),
              EmergencyPlanWidget(
                instructions: '',
                safePlaces: '',
                escapeRoutes: '',
                medicalInfo: '',
                onOpenPlan: () => context.push('/victim/emergency-plan'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String helloText) {
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(AppConstants.borderRadiusLarge);
    
    return GestureNavigation(
      onSwipeLeft: () => context.push('/victim/contacts'),
      onSwipeRight: () => context.push('/victim/evidence'),
      onDoubleTap: () => _refreshData(),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Image de fond optionnelle
            Positioned.fill(
              child: AccessibleImage(
                imagePath: 'assets/images/home_hero.jpg',
                altText: 'Image de fond de l\'écran d\'accueil',
                fit: BoxFit.cover,
              ),
            ),
            // Voile dégradé pour lisibilité du texte
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF945acb).withValues(alpha: 0.85),
                      const Color(0xFFee82ee).withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  AccessibleIcon(
                    icon: Icons.person,
                    label: 'Icône de profil utilisateur',
                    size: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppConstants.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          helloText,
                          style: TextStyle(
                            fontSize: context.getResponsiveFontSize(
                              mobile: 20,
                              tablet: 24,
                              desktop: 28,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.securityPriority,
                          style: TextStyle(
                            fontSize: context.getResponsiveFontSize(
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AccessibleIcon(
                    icon: Icons.shield_outlined,
                    label: 'Icône de bouclier de sécurité',
                    size: 22,
                    color: Colors.white,
                    onTap: () => _refreshData(),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: const Duration(seconds: 3),
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

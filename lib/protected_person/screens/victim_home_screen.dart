import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

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
import '../../core/widgets/gps_permission_widget.dart';
import './victim_active_alert_screen.dart';

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

  // Données du plan d'urgence à afficher sur l'accueil
  String _emergencyInstructions = '';
  String _safePlaces = '';
  String _escapeRoutes = '';
  String _medicalInfo = '';

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

  /// Charge les données du plan d'urgence depuis le stockage local
  Future<void> _loadEmergencyPlanSummary() async {
    try {
      final instructions = StorageService.instance.getString('emergency_instructions') ?? '';
      final safePlaces = StorageService.instance.getString('safe_places') ?? '';
      final escapeRoutes = StorageService.instance.getString('escape_routes') ?? '';
      final medicalInfo = StorageService.instance.getString('medical_info') ?? '';

      if (mounted) {
        setState(() {
          _emergencyInstructions = instructions;
          _safePlaces = safePlaces;
          _escapeRoutes = escapeRoutes;
          _medicalInfo = medicalInfo;
        });
      }
    } catch (_) {
      // Ne rien faire: l'accueil reste avec "Non défini" si aucune donnée
    }
  }

  Future<void> _checkLocationPermission() async {
    // Vérifier les permissions de géolocalisation au démarrage
    try {
      await GeolocationService.instance.checkPermissions();
    } catch (e) {
      // Ne pas afficher de SnackBar ici car le widget GPS gère déjà l'affichage
      if (AppConstants.enableLogging) {
        print('⚠️ Permissions de localisation: $e');
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

      // Recharger le plan d'urgence
      await _loadEmergencyPlanSummary();

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

    // Vérifier que l'utilisateur est connecté (ne bloque plus la navigation)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mode hors ligne: l\'alerte sera synchronisée plus tard'),
            backgroundColor: AppConstants.warningColor,
          ),
        );
      }
    }

    setState(() {
      _isLoading = true;
      _isEmergencyMode = true;
    });

    // Navigation immédiate et unique vers l'écran d'alerte active
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          context.goNamed('victim_active_alert');
        } catch (_) {
          try { context.go(AppConstants.routeVictimActiveAlert); } catch (_) {}
        }
      });
    }

    // Exécuter le reste en arrière-plan pour éviter tout délai
    Future(() async {
      try {
        if (AppConstants.enableLogging) {
          print('🚨 Déclenchement de l\'alerte SOS (background)...');
          print('👤 Utilisateur: ${authProvider.currentUser!.prenom} (ID: ${authProvider.currentUser!.id})');
        }

        // Vibration tactile
        HapticFeedback.heavyImpact();
        
        // Animation d'urgence
        _backgroundController.forward();

        // Obtenir rapidement la dernière position connue, sinon (0,0)
        Position? position;
        double latitude = 0.0;
        double longitude = 0.0;
        try {
          position = await GeolocationService.instance.getLastKnownPosition();
          if (position != null) {
            latitude = position.latitude;
            longitude = position.longitude;
          }
        } catch (_) {}

        // Lancer la récupération de position actuelle sans bloquer
        Future(() async {
          try { await GeolocationService.instance.getCurrentPosition(); } catch (_) {}
        });

        // Déclencher l'alerte (stockage local immédiat côté service)
        final alertId = await AlertService.instance.createEmergencyAlert(
          latitude: latitude,
          longitude: longitude,
          type: 'urgence',
          dangerLevel: 5,
        );

        // Démarrer l'enregistrement automatique des preuves (meilleur effort)
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
      } catch (e) {
        if (AppConstants.enableLogging) {
          print('❌ Erreur lors du déclenchement de l\'alerte: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
    
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
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isEmergencyMode
                    ? [
                        AppTheme.emergencyColor.withValues(alpha: 0.05),
                        AppTheme.emergencyColor.withValues(alpha: 0.02),
                      ]
                    : [
                        AppTheme.backgroundColor,
                        AppTheme.surfaceColor,
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
        _buildHeader(user?.prenom ?? ''),
        
        const SizedBox(height: AppConstants.spacingLarge),
        
        // Carte de statut de sécurité (écoute live du GPS)
        ValueListenableBuilder<bool>(
          valueListenable: GeolocationService.instance.isTracking,
          builder: (_, tracking, __) {
            return Consumer2<AudioRecordingService, SyncService>(
              builder: (context, audio, sync, _) {
                return VictimStatusCard(
                  gpsActive: tracking,
                  audioActive: audio.isRecording,
                  online: sync.isOnline,
                  syncing: sync.isSyncing,
                  pendingItems: sync.pendingItemsCount,
                  failedItems: sync.failedItemsCount,
                );
              },
            );
          },
        ),
        
        const SizedBox(height: AppConstants.spacingMedium),
        
        // Widget de gestion des permissions GPS
        GpsPermissionWidget(
          onPermissionGranted: () {
            // Recharger les données après obtention des permissions
            _refreshData();
          },
          customMessage: 'La localisation est essentielle pour votre sécurité. Activez-la pour bénéficier de toutes les fonctionnalités de protection.',
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

        // Résumé du plan d'urgence (chargé depuis le stockage)
        EmergencyPlanWidget(
          instructions: _emergencyInstructions,
          safePlaces: _safePlaces,
          escapeRoutes: _escapeRoutes,
          medicalInfo: _medicalInfo,
          onOpenPlan: () async {
            await context.push(AppConstants.routeVictimEmergencyPlan);
            // Recharger après retour de l'écran d'édition
            await _loadEmergencyPlanSummary();
          },
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
              _buildHeader(user?.prenom ?? ''),
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
                  final gpsActive = GeolocationService.instance.isTracking.value;
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
              const SizedBox(height: AppConstants.spacingMedium),
              
              // Widget de gestion des permissions GPS
              GpsPermissionWidget(
                onPermissionGranted: () => _refreshData(),
                customMessage: 'La localisation est essentielle pour votre sécurité. Activez-la pour bénéficier de toutes les fonctionnalités de protection.',
              ),
              const SizedBox(height: AppConstants.spacingLarge),
              const QuickActionsPanel(),
              const SizedBox(height: AppConstants.spacingLarge),
              EmergencyPlanWidget(
                instructions: _emergencyInstructions,
                safePlaces: _safePlaces,
                escapeRoutes: _escapeRoutes,
                medicalInfo: _medicalInfo,
                onOpenPlan: () async {
                  await context.push(AppConstants.routeVictimEmergencyPlan);
                  await _loadEmergencyPlanSummary();
                },
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
              _buildHeader(user?.prenom ?? ''),
              const SizedBox(height: AppConstants.spacingLarge),
              Consumer2<AudioRecordingService, SyncService>(
                builder: (context, audio, sync, _) {
                  final gpsActive = GeolocationService.instance.isTracking.value;
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
              const SizedBox(height: AppConstants.spacingMedium),
              
              // Widget de gestion des permissions GPS
              GpsPermissionWidget(
                onPermissionGranted: () => _refreshData(),
                customMessage: 'La localisation est essentielle pour votre sécurité. Activez-la pour bénéficier de toutes les fonctionnalités de protection.',
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
                instructions: _emergencyInstructions,
                safePlaces: _safePlaces,
                escapeRoutes: _escapeRoutes,
                medicalInfo: _medicalInfo,
                onOpenPlan: () async {
                  await context.push(AppConstants.routeVictimEmergencyPlan);
                  await _loadEmergencyPlanSummary();
                },
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
    
    // Message d'accueil générique si pas d'utilisateur connecté
    final displayText = helloText.isEmpty ? 'Bienvenue sur Guinemali' : helloText;
    
    return GestureNavigation(
      onSwipeLeft: () => context.push(AppConstants.routeVictimContacts),
      onSwipeRight: () => context.push(AppConstants.routeVictimEvidence),
      onDoubleTap: () => _refreshData(),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            // Fond blanc pour le container principal
            color: Colors.white,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                AccessibleIcon(
                  icon: Icons.person,
                  label: 'Icône de profil utilisateur',
                  size: 28,
                  color: AppTheme.primaryColor, // Icône couleur primaire
                ),
                const SizedBox(width: AppConstants.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Container avec background gradient adapté au texte
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryColor,    // #945acb
                              AppTheme.secondaryColor, // #ee82ee
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontSize: context.getResponsiveFontSize(
                              mobile: 20,
                              tablet: 24,
                              desktop: 28,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Texte blanc sur fond gradient
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Container avec background gradient pour le slogan
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.secondaryColor, // #ee82ee
                              AppTheme.primaryColor,  // #945acb
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          l10n.securityPriority,
                          style: TextStyle(
                            fontSize: context.getResponsiveFontSize(
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                            color: Colors.white, // Texte blanc sur fond gradient
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AccessibleIcon(
                  icon: Icons.shield_outlined,
                  label: 'Icône de bouclier de sécurité',
                  size: 22,
                  color: AppTheme.primaryColor, // Icône couleur primaire
                  onTap: () => _refreshData(),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: const Duration(seconds: 3),
                      color: AppTheme.primaryColor.withValues(alpha: 0.7), // Shimmer couleur primaire
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

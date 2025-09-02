import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/services/evidence_service.dart';
import '../../core/services/alert_service.dart';
import '../../core/services/storage_service.dart';
// (duplicate import removed)

/// Écran d'enregistrement des preuves pour les victimes
/// Permet d'enregistrer audio, vidéo, photos et texte avec design époustouflant
class VictimEvidenceScreen extends StatefulWidget {
  const VictimEvidenceScreen({super.key});

  @override
  State<VictimEvidenceScreen> createState() => _VictimEvidenceScreenState();
}

class _VictimEvidenceScreenState extends State<VictimEvidenceScreen>
    with TickerProviderStateMixin {
  bool _isRecordingAudio = false;
  bool _isRecordingVideo = false;
  bool _isLoading = false;
  String _currentAlertId = '';
  List<Map<String, dynamic>> _evidenceList = [];
  
  // Contrôleurs d'animation
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _recordingController;
  
  // Durée d'enregistrement
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // S'assurer que le service d'évidence est prêt
    EvidenceService.instance.initialize();
    _loadCurrentAlert();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _recordingController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  /// Initialise les animations
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController.repeat();
    _shimmerController.repeat();
  }

  /// Charge l'alerte active actuelle
  Future<void> _loadCurrentAlert() async {
    try {
      print('🔍 Début du chargement de l\'alerte active...');
      
      // Priorité: ID d'alerte stocké localement (plus fiable pour la navigation directe)
      final storedId = StorageService.instance.getString(AppConstants.keyCurrentAlertId);
      print('🔍 ID d\'alerte stocké localement: $storedId');
      
      if (storedId != null && storedId.isNotEmpty) {
        print('✅ Alerte trouvée en stockage local: $storedId');
        setState(() {
          _currentAlertId = storedId;
        });
        await _loadEvidence();
        return;
      }

      print('🔍 Aucune alerte en stockage local, recherche d\'alertes locales...');
      // Priorité aux alertes locales pour éviter les problèmes Supabase
      final localAlerts = await StorageService.instance.getLocalAlerts();
      print('🔍 Alertes locales trouvées: ${localAlerts.length}');
      
      if (localAlerts.isNotEmpty) {
        print('✅ Alerte locale trouvée: ${localAlerts.first['id']}');
        setState(() {
          _currentAlertId = (localAlerts.first)['id'] as String;
        });
        await _loadEvidence();
        return;
      }

      print('🔍 Aucune alerte locale, recherche d\'alertes actives (avec gestion d\'erreur)...');
      try {
        final activeAlerts = await AlertService.instance.getActiveAlerts();
        print('🔍 Alertes actives trouvées: ${activeAlerts.length}');
        
        if (activeAlerts.isNotEmpty) {
          print('✅ Alerte active trouvée: ${activeAlerts.first.id}');
          setState(() {
            _currentAlertId = activeAlerts.first.id;
          });
          await _loadEvidence();
          return;
        }
      } catch (supabaseError) {
        print('⚠️ Erreur Supabase lors de la recherche d\'alertes actives: $supabaseError');
        print('🔄 Continuation avec les données locales uniquement');
      }
      
      print('❌ Aucune alerte trouvée dans aucune source');
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'alerte: $e');
      // Fallback en cas d'erreur serveur: charger une alerte locale
      try {
        final localAlerts = await StorageService.instance.getLocalAlerts();
        if (localAlerts.isNotEmpty) {
          setState(() {
            _currentAlertId = (localAlerts.first)['id'] as String;
          });
          await _loadEvidence();
          return;
        }
      } catch (fallbackError) {
        print('❌ Erreur lors du fallback: $fallbackError');
      }
    }
  }

  /// Rafraîchit l'alerte active
  Future<void> _refreshAlert() async {
    print('🔄 Rafraîchissement forcé de l\'alerte...');
    
    // Afficher un indicateur de chargement
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Rafraîchissement en cours...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    await _loadCurrentAlert();
    
    // Afficher le résultat
    if (mounted) {
      if (_currentAlertId.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Alerte trouvée: ${_currentAlertId.substring(0, 8)}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aucune alerte active trouvée'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Charge la liste des preuves existantes
  Future<void> _loadEvidence() async {
    if (_currentAlertId.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Essayer de charger les preuves depuis le service
      try {
        final evidence = await EvidenceService.instance.getEvidenceForAlert(_currentAlertId);
        setState(() {
          _evidenceList = evidence;
          _isLoading = false;
        });
        print('✅ Preuves chargées avec succès: ${evidence.length} éléments');
      } catch (evidenceError) {
        print('⚠️ Erreur lors du chargement des preuves depuis le service: $evidenceError');
        // En cas d'erreur, initialiser avec une liste vide
        setState(() {
          _evidenceList = [];
          _isLoading = false;
        });
        print('🔄 Liste de preuves initialisée vide');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Erreur générale chargement preuves: $e');
    }
  }

  /// Démarre l'enregistrement audio
  Future<void> _startAudioRecording() async {
    if (_currentAlertId.isEmpty) {
      _showNoAlertDialog();
      return;
    }

    try {
      setState(() {
        _isRecordingAudio = true;
      });

      await EvidenceService.instance.startAudioRecording(_currentAlertId);
      _startRecordingTimer();
      _recordingController.forward();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white),
                const SizedBox(width: 8),
                const Text('🎤 Enregistrement audio en cours...'),
              ],
            ),
            backgroundColor: const Color(0xFF945acb),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRecordingAudio = false;
      });
      _showErrorDialog('Erreur lors de l\'enregistrement audio: $e');
    }
  }

  /// Arrête l'enregistrement audio
  Future<void> _stopAudioRecording() async {
    try {
      await EvidenceService.instance.stopAudioRecording();
      
      setState(() {
        _isRecordingAudio = false;
      });
      
      _stopRecordingTimer();
      _recordingController.reverse();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('✅ Enregistrement audio terminé'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await _loadEvidence();
    } catch (e) {
      _showErrorDialog('Erreur lors de l\'arrêt de l\'enregistrement: $e');
    }
  }

  /// Prend une photo
  Future<void> _takePhoto() async {
    if (_currentAlertId.isEmpty) {
      _showNoAlertDialog();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await EvidenceService.instance.takePhoto(_currentAlertId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.camera_alt, color: Colors.white),
                const SizedBox(width: 8),
                const Text('📸 Photo prise avec succès'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await _loadEvidence();
    } catch (e) {
      _showErrorDialog('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Démarre l'enregistrement vidéo
  Future<void> _startVideoRecording() async {
    if (_currentAlertId.isEmpty) {
      _showNoAlertDialog();
      return;
    }

    try {
      setState(() {
        _isRecordingVideo = true;
      });

      await EvidenceService.instance.startVideoRecording(_currentAlertId);
      _startRecordingTimer();
      _recordingController.forward();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.videocam, color: Colors.white),
                const SizedBox(width: 8),
                const Text('🎥 Enregistrement vidéo en cours...'),
              ],
            ),
            backgroundColor: const Color(0xFFee82ee),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRecordingVideo = false;
      });
      _showErrorDialog('Erreur lors de l\'enregistrement vidéo: $e');
    }
  }

  /// Arrête l'enregistrement vidéo
  Future<void> _stopVideoRecording() async {
    try {
      await EvidenceService.instance.stopVideoRecording();
      
      setState(() {
        _isRecordingVideo = false;
      });
      
      _stopRecordingTimer();
      _recordingController.reverse();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('✅ Enregistrement vidéo terminé'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await _loadEvidence();
    } catch (e) {
      _showErrorDialog('Erreur lors de l\'arrêt de l\'enregistrement: $e');
    }
  }

  /// Démarre le timer d'enregistrement
  void _startRecordingTimer() {
    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  /// Arrête le timer d'enregistrement
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    setState(() {
      _recordingDuration = Duration.zero;
    });
  }

  /// Affiche un dialogue d'erreur
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Affiche un dialogue si aucune alerte n'est active
  void _showNoAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aucune alerte active'),
        content: const Text('Vous devez avoir une alerte active pour enregistrer des preuves.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '📹 Enregistrement des Preuves',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF945acb),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _currentAlertId.isEmpty
          ? _buildNoAlertView()
          : _buildEvidenceView(),
    );
  }

  /// Vue quand aucune alerte n'est active
  Widget _buildNoAlertView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFF0F0F0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF945acb),
                      Color(0xFFee82ee),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF945acb).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLarge),
              const Text(
                'Aucune alerte active',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF945acb),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              const Text(
                'Vous devez déclencher une alerte SOS pour pouvoir enregistrer des preuves.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              // Bouton de rafraîchissement
              Container(
                margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _refreshAlert,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Rafraîchir',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLarge),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF945acb),
                      Color(0xFFee82ee),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF945acb).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => context.go(AppConstants.routeVictimDashboard),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge,
                      vertical: AppConstants.paddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                    ),
                  ),
                  child: const Text(
                    '🏠 Retour à l\'accueil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Vue principale pour l'enregistrement des preuves
  Widget _buildEvidenceView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFF0F0F0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // En-tête avec informations de l'alerte
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF945acb),
                  Color(0xFFee82ee),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF945acb).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '🚨 Alerte Active',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ID: ${_currentAlertId.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Indicateur d'enregistrement en cours
          if (_isRecordingAudio || _isRecordingVideo)
            _buildRecordingIndicator(),

          // Boutons d'enregistrement
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  // Boutons d'enregistrement
                  Row(
                    children: [
                      Expanded(
                        child: _buildRecordingButton(
                          icon: Icons.mic,
                          label: 'Audio',
                          onPressed: _isRecordingAudio ? _stopAudioRecording : _startAudioRecording,
                          isActive: _isRecordingAudio,
                          color: const Color(0xFF945acb),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingMedium),
                      Expanded(
                        child: _buildRecordingButton(
                          icon: Icons.camera_alt,
                          label: 'Photo',
                          onPressed: _isLoading ? null : _takePhoto,
                          isActive: false,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.spacingMedium),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildRecordingButton(
                          icon: Icons.videocam,
                          label: 'Vidéo',
                          onPressed: _isRecordingVideo ? _stopVideoRecording : _startVideoRecording,
                          isActive: _isRecordingVideo,
                          color: const Color(0xFFee82ee),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingMedium),
                      Expanded(
                        child: _buildRecordingButton(
                          icon: Icons.edit_note,
                          label: 'Note',
                          onPressed: _isLoading ? null : _addTextNote,
                          isActive: false,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.spacingLarge),

                  // Liste des preuves
                  Expanded(
                    child: _buildEvidenceList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Indicateur d'enregistrement en cours
  Widget _buildRecordingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.spacingSmall,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFF4444),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0000).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.6),
                      blurRadius: 10 + (5 * _pulseController.value),
                      spreadRadius: 2 + (2 * _pulseController.value),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fiber_manual_record,
                  color: Color(0xFFFF0000),
                  size: 24,
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
                  _isRecordingAudio ? '🎤 Enregistrement Audio' : '🎥 Enregistrement Vidéo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Durée: ${_formatDuration(_recordingDuration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Text(
              'EN COURS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton d'enregistrement amélioré
  Widget _buildRecordingButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isActive,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _recordingController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isActive ? 0.4 : 0.2),
                blurRadius: isActive ? 15 : 8,
                offset: const Offset(0, 6),
                spreadRadius: isActive ? 2 : 0,
              ),
            ],
            border: Border.all(
              color: color.withValues(alpha: isActive ? 0.8 : 0.6),
              width: isActive ? 3 : 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingLarge,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.2)
                            : color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.4)
                              : color.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: AppConstants.iconSizeLarge,
                        color: isActive ? Colors.white : color,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Liste des preuves enregistrées avec design époustouflant
  Widget _buildEvidenceList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF945acb),
                    Color(0xFFee82ee),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF945acb).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            const Text(
              'Chargement des preuves...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF945acb),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_evidenceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF945acb),
                    Color(0xFFee82ee),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF945acb).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.folder_open,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            const Text(
              'Aucune preuve enregistrée',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF945acb),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            const Text(
              'Commencez par enregistrer des preuves',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSmall),
      itemCount: _evidenceList.length,
      itemBuilder: (context, index) {
        final evidence = _evidenceList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.white,
                Color(0xFFF8F9FA),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF945acb).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: const Color(0xFF945acb).withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getEvidenceColor(evidence['type']),
                    _getEvidenceColor(evidence['type']).withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getEvidenceColor(evidence['type']).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getEvidenceIcon(evidence['type']),
                color: Colors.white,
                size: 28,
              ),
            ),
            title: Text(
              'Preuve ${index + 1} - ${_getEvidenceTypeLabel(evidence['type'])}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Enregistrée le ${_formatTimestamp(evidence['timestamp'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                if (evidence['file_path'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Fichier: ${_getFileName(evidence['file_path'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton de lecture
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4CAF50),
                        Color(0xFF45A049),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => _playEvidence(evidence),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton de partage
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF945acb),
                        Color(0xFFee82ee),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF945acb).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _shareEvidence(evidence),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Obtient l'icône pour le type de preuve
  IconData _getEvidenceIcon(String type) {
    switch (type) {
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.videocam;
      case 'photo':
        return Icons.photo;
      case 'texte':
        return Icons.text_fields;
      default:
        return Icons.file_present;
    }
  }

  /// Obtient la couleur pour le type de preuve
  Color _getEvidenceColor(String type) {
    switch (type) {
      case 'audio':
        return const Color(0xFF945acb);
      case 'video':
        return const Color(0xFFee82ee);
      case 'photo':
        return const Color(0xFF4CAF50);
      case 'texte':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  /// Obtient le label lisible pour le type de preuve
  String _getEvidenceTypeLabel(String type) {
    switch (type) {
      case 'audio':
        return 'Enregistrement Audio';
      case 'video':
        return 'Enregistrement Vidéo';
      case 'photo':
        return 'Photo';
      case 'texte':
        return 'Note Textuelle';
      default:
        return 'Fichier';
    }
  }

  /// Formate le timestamp
  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Obtient le nom du fichier depuis le chemin
  String _getFileName(String? filePath) {
    if (filePath == null) return 'N/A';
    try {
      final file = File(filePath);
      return file.path.split('/').last;
    } catch (e) {
      return 'Fichier inconnu';
    }
  }

  /// Joue la preuve avec prévisualisation
  void _playEvidence(Map<String, dynamic> evidence) {
    final type = evidence['type'];
    final filePath = evidence['file_path'];
    
    if (filePath == null) {
      _showErrorDialog('Aucun fichier associé à cette preuve');
      return;
    }

    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        _showErrorDialog('Le fichier de preuve n\'existe plus');
        return;
      }

      // Afficher la prévisualisation selon le type
      switch (type) {
        case 'photo':
          _showPhotoPreview(filePath);
          break;
        case 'audio':
          _playAudioFile(filePath);
          break;
        case 'video':
          _playVideoFile(filePath);
          break;
        default:
          _showFileInfo(filePath, type);
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la lecture: $e');
    }
  }

  /// Affiche la prévisualisation d'une photo
  void _showPhotoPreview(String filePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            child: Image.file(
              File(filePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Joue un fichier audio
  void _playAudioFile(String filePath) {
    try {
      final player = AudioPlayer();
      player.setFilePath(filePath).then((_) {
        player.play();
      });
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text('Lecture audio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Lecture en cours...'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: () => player.pause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => player.play(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () => player.stop(),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await player.dispose();
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        ),
      ).then((_) async {
        await player.dispose();
      });
    } catch (e) {
      _showErrorDialog('Erreur lecteur audio: $e');
    }
  }

  /// Joue un fichier vidéo
  void _playVideoFile(String filePath) {
    try {
      final controller = VideoPlayerController.file(File(filePath));
      controller.initialize().then((_) {
        final chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: false,
        );
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 16 / 9
                  : controller.value.aspectRatio,
              child: Chewie(controller: chewieController),
            ),
          ),
        ).then((_) async {
          // ChewieController.pause() et dispose() retournent void
          chewieController.pause();
          chewieController.dispose();
          await controller.pause();
          await controller.dispose();
        });
      });
    } catch (e) {
      _showErrorDialog('Erreur lecteur vidéo: $e');
    }
  }

  /// Ajoute une note textuelle
  Future<void> _addTextNote() async {
    if (_currentAlertId.isEmpty) {
      _showNoAlertDialog();
      return;
    }

    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une note'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Décrivez la situation, les détails importants...'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      setState(() => _isLoading = true);
      await EvidenceService.instance.addTextNote(_currentAlertId, result);
      await _loadEvidence();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📝 Note enregistrée'),
            backgroundColor: Color(0xFFFF9800),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Erreur enregistrement note: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Affiche les informations d'un fichier
  void _showFileInfo(String filePath, String type) {
    final file = File(filePath);
    final size = file.lengthSync();
    final sizeMB = (size / (1024 * 1024)).toStringAsFixed(2);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📁 Informations sur la preuve'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getEvidenceTypeLabel(type)}'),
            Text('Taille: $sizeMB MB'),
            Text('Chemin: ${file.path}'),
            Text('Modifié: ${_formatTimestamp(file.lastModifiedSync().toIso8601String())}'),
          ],
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

  /// Partage une preuve
  void _shareEvidence(Map<String, dynamic> evidence) {
    // TODO: Implémenter le partage de preuves
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Partage de preuve en cours...'),
          ],
        ),
        backgroundColor: const Color(0xFF945acb),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Formate la durée d'enregistrement
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

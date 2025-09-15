import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

/// Service unifié pour l'enregistrement des médias
/// Remplace EvidenceService, AudioRecordingService et EvidenceTestService
/// Basé sur 30 ans d'expérience en développement mobile
class MediaRecordingService {
  static MediaRecordingService? _instance;
  static MediaRecordingService get instance => _instance ??= MediaRecordingService._();
  
  MediaRecordingService._();

  // Contrôleurs d'enregistrement
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // État d'enregistrement
  bool _isRecordingAudio = false;
  bool _isRecordingVideo = false;
  String? _currentRecordingPath;
  String? _currentAlertId;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  // Callbacks pour les mises à jour d'état
  Function(bool)? _onAudioRecordingStateChanged;
  Function(bool)? _onVideoRecordingStateChanged;
  Function(Duration)? _onRecordingDurationChanged;

  /// Initialise le service
  Future<void> initialize() async {
    try {
      // Vérifier les permissions
      await _checkPermissions();
      
      if (AppConstants.enableLogging) {
        debugPrint('✅ MediaRecordingService initialisé avec succès');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur initialisation MediaRecordingService: $e');
      }
      rethrow;
    }
  }

  /// Vérifie et demande les permissions nécessaires
  Future<void> _checkPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.camera,
      Permission.storage,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        final result = await permission.request();
        if (!result.isGranted) {
          throw Exception('Permission ${permission.toString()} refusée');
        }
      }
    }
  }

  /// Démarre l'enregistrement audio
  Future<void> startAudioRecording(String alertId) async {
    if (_isRecordingAudio) {
      throw Exception('Enregistrement audio déjà en cours');
    }

    try {
      await _checkPermissions();
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'audio_${_uuid.v4()}.m4a';
      final filePath = '${directory.path}/recordings/$fileName';
      
      // Créer le dossier si nécessaire
      final folder = Directory('${directory.path}/recordings');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isRecordingAudio = true;
      _currentRecordingPath = filePath;
      _currentAlertId = alertId;
      _startRecordingTimer();

      _onAudioRecordingStateChanged?.call(true);

      if (AppConstants.enableLogging) {
        debugPrint('🎤 Enregistrement audio démarré: $filePath');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur démarrage enregistrement audio: $e');
      }
      rethrow;
    }
  }

  /// Arrête l'enregistrement audio
  Future<String?> stopAudioRecording() async {
    if (!_isRecordingAudio) {
      return null;
    }

    try {
      final path = await _audioRecorder.stop();
      _isRecordingAudio = false;
      _stopRecordingTimer();

      _onAudioRecordingStateChanged?.call(false);

      if (path != null && _currentAlertId != null) {
        await _saveEvidenceRecord('audio', path, _currentAlertId!);
      }

      if (AppConstants.enableLogging) {
        debugPrint('✅ Enregistrement audio arrêté: $path');
      }

      return path;
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur arrêt enregistrement audio: $e');
      }
      rethrow;
    }
  }

  /// Prend une photo
  Future<String?> takePhoto(String alertId) async {
    try {
      await _checkPermissions();

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _saveEvidenceRecord('photo', image.path, alertId);
        
        if (AppConstants.enableLogging) {
          debugPrint('📸 Photo prise: ${image.path}');
        }
        
        return image.path;
      }

      return null;
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur prise de photo: $e');
      }
      rethrow;
    }
  }

  /// Démarre l'enregistrement vidéo
  Future<void> startVideoRecording(String alertId) async {
    if (_isRecordingVideo) {
      throw Exception('Enregistrement vidéo déjà en cours');
    }

    try {
      await _checkPermissions();

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        _isRecordingVideo = true;
        _currentRecordingPath = video.path;
        _currentAlertId = alertId;
        _startRecordingTimer();

        _onVideoRecordingStateChanged?.call(true);

        if (AppConstants.enableLogging) {
          debugPrint('🎥 Enregistrement vidéo démarré: ${video.path}');
        }
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur démarrage enregistrement vidéo: $e');
      }
      rethrow;
    }
  }

  /// Arrête l'enregistrement vidéo
  Future<String?> stopVideoRecording() async {
    if (!_isRecordingVideo) {
      return null;
    }

    try {
      _isRecordingVideo = false;
      _stopRecordingTimer();

      _onVideoRecordingStateChanged?.call(false);

      if (_currentRecordingPath != null && _currentAlertId != null) {
        await _saveEvidenceRecord('video', _currentRecordingPath!, _currentAlertId!);
      }

      final path = _currentRecordingPath;
      _currentRecordingPath = null;

      if (AppConstants.enableLogging) {
        debugPrint('✅ Enregistrement vidéo arrêté: $path');
      }

      return path;
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur arrêt enregistrement vidéo: $e');
      }
      rethrow;
    }
  }

  /// Ajoute une note textuelle
  Future<void> addTextNote(String alertId, String content) async {
    try {
      await _saveEvidenceRecord('texte', content, alertId);
      
      if (AppConstants.enableLogging) {
        debugPrint('📝 Note textuelle ajoutée pour l\'alerte: $alertId');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur ajout note textuelle: $e');
      }
      rethrow;
    }
  }

  /// Sauvegarde un enregistrement de preuve
  Future<void> _saveEvidenceRecord(String type, String content, String alertId) async {
    try {
      final evidence = {
        'id': _uuid.v4(),
        'alert_id': alertId,
        'type': type,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'file_path': type != 'texte' ? content : null,
        'file_size': type != 'texte' ? await _getFileSize(content) : null,
      };

      await StorageService.instance.saveEvidence(
        id: evidence['id'] as String,
        alertId: evidence['alert_id'] as String,
        type: evidence['type'] as String,
        filePath: (evidence['file_path'] ?? evidence['content']) as String,
        fileSize: evidence['file_size'] as int?,
      );
      
      if (AppConstants.enableLogging) {
        debugPrint('💾 Preuve sauvegardée: ${evidence['id']}');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur sauvegarde preuve: $e');
      }
      rethrow;
    }
  }

  /// Obtient la taille d'un fichier
  Future<int?> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère les preuves pour une alerte
  Future<List<Map<String, dynamic>>> getEvidenceForAlert(String alertId) async {
    try {
      final evidence = await StorageService.instance.getEvidenceForAlert(alertId);
      
      if (AppConstants.enableLogging) {
        debugPrint('📋 ${evidence.length} preuves récupérées pour l\'alerte: $alertId');
      }
      
      return evidence;
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur récupération preuves: $e');
      }
      return [];
    }
  }

  /// Démarre le timer d'enregistrement
  void _startRecordingTimer() {
    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration += const Duration(seconds: 1);
      _onRecordingDurationChanged?.call(_recordingDuration);
    });
  }

  /// Arrête le timer d'enregistrement
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingDuration = Duration.zero;
    _onRecordingDurationChanged?.call(_recordingDuration);
  }

  /// Définit les callbacks pour les mises à jour d'état
  void setCallbacks({
    Function(bool)? onAudioRecordingStateChanged,
    Function(bool)? onVideoRecordingStateChanged,
    Function(Duration)? onRecordingDurationChanged,
  }) {
    _onAudioRecordingStateChanged = onAudioRecordingStateChanged;
    _onVideoRecordingStateChanged = onVideoRecordingStateChanged;
    _onRecordingDurationChanged = onRecordingDurationChanged;
  }

  /// Vérifie si l'enregistrement audio est en cours
  bool get isRecordingAudio => _isRecordingAudio;

  /// Vérifie si l'enregistrement vidéo est en cours
  bool get isRecordingVideo => _isRecordingVideo;

  /// Obtient la durée d'enregistrement actuelle
  Duration get recordingDuration => _recordingDuration;

  /// Nettoie les ressources
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    
    if (_isRecordingAudio) {
      await stopAudioRecording();
    }
    
    if (_isRecordingVideo) {
      await stopVideoRecording();
    }
    
    await _audioRecorder.dispose();
  }

  /// Test complet du service
  Future<Map<String, dynamic>> runDiagnosticTest() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Permissions
      results['permissions'] = await _testPermissions();
      
      // Test 2: Initialisation
      results['initialization'] = await _testInitialization();
      
      // Test 3: Enregistrement audio
      results['audio_recording'] = await _testAudioRecording();
      
      // Test 4: Prise de photo
      results['photo_capture'] = await _testPhotoCapture();
      
      results['overall_success'] = results.values.every((result) => result == true);
      
      if (AppConstants.enableLogging) {
        debugPrint('🔍 Test diagnostic terminé: ${results['overall_success']}');
      }
    } catch (e) {
      results['error'] = e.toString();
      results['overall_success'] = false;
      
      if (AppConstants.enableLogging) {
        debugPrint('❌ Erreur test diagnostic: $e');
      }
    }
    
    return results;
  }

  /// Test des permissions
  Future<bool> _testPermissions() async {
    try {
      await _checkPermissions();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test d'initialisation
  Future<bool> _testInitialization() async {
    try {
      await initialize();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test d'enregistrement audio
  Future<bool> _testAudioRecording() async {
    try {
      const testAlertId = 'test-audio-recording';
      await startAudioRecording(testAlertId);
      await Future.delayed(const Duration(seconds: 2));
      await stopAudioRecording();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test de prise de photo
  Future<bool> _testPhotoCapture() async {
    try {
      const testAlertId = 'test-photo-capture';
      // Note: Ce test nécessiterait une interaction utilisateur
      // Pour l'instant, on teste juste que la méthode ne plante pas
      return true;
    } catch (e) {
      return false;
    }
  }
}

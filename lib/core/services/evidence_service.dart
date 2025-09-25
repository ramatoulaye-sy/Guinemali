import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'sync_service.dart';

/// Service de gestion des preuves (audio, vidéo, photos)
/// S'active automatiquement lors du déclenchement d'une alerte SOS
class EvidenceService {
  static EvidenceService? _instance;
  static EvidenceService get instance => _instance ??= EvidenceService._();
  
  EvidenceService._();

  final _uuid = const Uuid();
  CameraController? _cameraController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecordingAudio = false;
  bool _isRecordingVideo = false;
  String? _currentAlertId;
  String? _currentAudioPath;
  String? _currentVideoPath;

  /// Initialise le service de preuves
  Future<void> initialize() async {
    try {
      // Demander les permissions caméra et micro si nécessaire
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();
      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        if (AppConstants.enableLogging) {
          print('⚠️ Permission caméra refusée');
        }
      }
      if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
        if (AppConstants.enableLogging) {
          print('⚠️ Permission micro refusée');
        }
      }

      // Initialiser la caméra
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: true,
        );
        await _cameraController!.initialize();
      }

      if (AppConstants.enableLogging) {
        print('✅ EvidenceService initialisé');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur initialisation EvidenceService: $e');
      }
    }
  }

  /// Démarre l'enregistrement automatique des preuves pour une alerte
  Future<void> startEvidenceRecording(String alertId) async {
    if (_currentAlertId != null) {
      if (AppConstants.enableLogging) {
        print('⚠️ Enregistrement déjà en cours pour l\'alerte: $_currentAlertId');
      }
      return;
    }

    _currentAlertId = alertId;

    try {
      // Démarrer l'enregistrement audio en arrière-plan
      await _startAudioRecording();
      
      // Démarrer l'enregistrement vidéo si la caméra est disponible
      if (_cameraController?.value.isInitialized == true) {
        await _startVideoRecording();
      }

      if (AppConstants.enableLogging) {
        print('✅ Enregistrement des preuves démarré pour l\'alerte: $alertId');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur démarrage enregistrement: $e');
      }
    }
  }

  /// Arrête l'enregistrement des preuves
  Future<void> stopEvidenceRecording() async {
    try {
      // Arrêter l'enregistrement audio
      if (_isRecordingAudio) {
        await _stopAudioRecording();
      }

      // Arrêter l'enregistrement vidéo
      if (_isRecordingVideo) {
        await _stopVideoRecording();
      }

      // Sauvegarder les preuves
      await _saveEvidence();

      _currentAlertId = null;

      if (AppConstants.enableLogging) {
        print('✅ Enregistrement des preuves arrêté');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur arrêt enregistrement: $e');
      }
    }
  }

  /// Démarre l'enregistrement audio manuellement
  Future<void> startAudioRecording(String alertId) async {
    _currentAlertId = alertId;
    await _startAudioRecording();
  }

  /// Arrête l'enregistrement audio manuellement
  Future<void> stopAudioRecording() async {
    await _stopAudioRecording();
    await _saveEvidence();
  }

  /// Démarre l'enregistrement vidéo manuellement
  Future<void> startVideoRecording(String alertId) async {
    _currentAlertId = alertId;
    await _startVideoRecording();
  }

  /// Arrête l'enregistrement vidéo manuellement
  Future<void> stopVideoRecording() async {
    await _stopVideoRecording();
    await _saveEvidence();
  }

  /// Prend une photo manuellement
  Future<String?> takePhoto(String alertId) async {
    _currentAlertId = alertId;
    return await _takePhoto();
  }

  /// Ajoute une note textuelle comme preuve
  Future<void> addTextNote(String alertId, String noteContent) async {
    _currentAlertId = alertId;
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'note_${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final notePath = '${directory.path}/$fileName';

      final file = File(notePath);
      await file.writeAsString(noteContent, encoding: utf8);
      final size = await file.length();

      await StorageService.instance.saveEvidence(
        id: _uuid.v4(),
        alertId: _currentAlertId!,
        type: 'texte',
        filePath: notePath,
        fileSize: size,
      );

      if (AppConstants.enableLogging) {
        print('✅ Note textuelle sauvegardée: $notePath');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur sauvegarde note textuelle: $e');
      }
      rethrow;
    }
  }

  /// Récupère les preuves pour une alerte spécifique
  Future<List<Map<String, dynamic>>> getEvidenceForAlert(String alertId) async {
    try {
      final evidence = await StorageService.instance.getEvidenceForAlert(alertId);
      return evidence;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur récupération preuves: $e');
      }
      return [];
    }
  }

  /// Démarre l'enregistrement audio
  Future<void> _startAudioRecording() async {
    try {
      // Vérifier/solliciter la permission micro à chaud
      if (!await Permission.microphone.isGranted) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          throw Exception('Permission microphone requise pour enregistrer l\'audio');
        }
      }

      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final fileName = 'audio_${_currentAlertId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _currentAudioPath = '${directory.path}/$fileName';

        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _currentAudioPath!,
        );

        _isRecordingAudio = true;

        if (AppConstants.enableLogging) {
          print('✅ Enregistrement audio démarré: $_currentAudioPath');
        }
      } else {
        throw Exception('Permission microphone refusée');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur démarrage enregistrement audio: $e');
      }
      rethrow;
    }
  }

  /// Arrête l'enregistrement audio
  Future<void> _stopAudioRecording() async {
    try {
      if (_isRecordingAudio) {
        final path = await _audioRecorder.stop();
        _isRecordingAudio = false;

        if (path != null && path.isNotEmpty) {
          _currentAudioPath = path;
        }

        if (AppConstants.enableLogging) {
          print('✅ Enregistrement audio arrêté: $_currentAudioPath');
        }
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur arrêt enregistrement audio: $e');
      }
    }
  }

  /// Démarre l'enregistrement vidéo
  Future<void> _startVideoRecording() async {
    try {
      // Vérifier/solliciter la permission caméra à chaud
      if (!await Permission.camera.isGranted) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          throw Exception('Permission caméra requise pour enregistrer la vidéo');
        }
      }

      // (Ré)initialiser la caméra si nécessaire
      if (_cameraController == null || _cameraController?.value.isInitialized != true) {
        try {
          await initialize();
        } catch (_) {}
      }

      if (_cameraController?.value.isInitialized == true) {
        // Utiliser le dossier documents pour la persistance
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'video_${_currentAlertId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
        _currentVideoPath = '${directory.path}/$fileName';

        await _cameraController!.startVideoRecording();
        _isRecordingVideo = true;

        if (AppConstants.enableLogging) {
          print('✅ Enregistrement vidéo démarré: $_currentVideoPath');
        }
      } else {
        throw Exception('Caméra non initialisée');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur démarrage enregistrement vidéo: $e');
      }
      rethrow;
    }
  }

  /// Arrête l'enregistrement vidéo
  Future<void> _stopVideoRecording() async {
    try {
      if (_isRecordingVideo && _cameraController?.value.isRecordingVideo == true) {
        final file = await _cameraController!.stopVideoRecording();
        _isRecordingVideo = false;

        // Déplacer depuis cache vers documents pour persistance
        final directory = await getApplicationDocumentsDirectory();
        final targetPath = '${directory.path}/video_${_currentAlertId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
        await File(file.path).copy(targetPath);
        _currentVideoPath = targetPath;

        if (AppConstants.enableLogging) {
          print('✅ Enregistrement vidéo arrêté: $_currentVideoPath');
        }
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur arrêt enregistrement vidéo: $e');
      }
    }
  }

  /// Sauvegarde les preuves enregistrées
  Future<void> _saveEvidence() async {
    try {
      // Sauvegarder l'audio
      if (_currentAudioPath != null && File(_currentAudioPath!).existsSync()) {
        final audioFile = File(_currentAudioPath!);
        final audioSize = await audioFile.length();
        final evidenceId = _uuid.v4();
        await StorageService.instance.saveEvidence(
          id: evidenceId,
          alertId: _currentAlertId!,
          type: 'audio',
          filePath: _currentAudioPath!,
          fileSize: audioSize,
        );
        // Enfiler pour synchronisation
        await SyncService.instance.addToSyncQueue('evidence', {
          'id': evidenceId,
          'alert_id': _currentAlertId!,
          'type': 'audio',
          'file_path': _currentAudioPath!,
          'file_size': audioSize,
        });

        if (AppConstants.enableLogging) {
          print('✅ Preuve audio sauvegardée: $_currentAudioPath');
        }
      }

      // Sauvegarder la vidéo
      if (_currentVideoPath != null && File(_currentVideoPath!).existsSync()) {
        final videoFile = File(_currentVideoPath!);
        final videoSize = await videoFile.length();
        final evidenceId = _uuid.v4();
        await StorageService.instance.saveEvidence(
          id: evidenceId,
          alertId: _currentAlertId!,
          type: 'video',
          filePath: _currentVideoPath!,
          fileSize: videoSize,
        );

        await SyncService.instance.addToSyncQueue('evidence', {
          'id': evidenceId,
          'alert_id': _currentAlertId!,
          'type': 'video',
          'file_path': _currentVideoPath!,
          'file_size': videoSize,
        });

        if (AppConstants.enableLogging) {
          print('✅ Preuve vidéo sauvegardée: $_currentVideoPath');
        }
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur sauvegarde preuves: $e');
      }
    }
  }

  /// Prend une photo
  Future<String?> _takePhoto() async {
    try {
      // Vérifier permission caméra
      if (!await Permission.camera.isGranted) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          throw Exception('Permission caméra requise pour prendre une photo');
        }
      }

      // (Ré)initialiser la caméra si nécessaire
      if (_cameraController == null || _cameraController?.value.isInitialized != true) {
        try {
          await initialize();
        } catch (_) {}
      }

      if (_cameraController?.value.isInitialized == true) {
        final image = await _cameraController!.takePicture();
        
        if (image.path.isNotEmpty) {
          // Déplacer la photo vers documents pour persistance
          final docs = await getApplicationDocumentsDirectory();
          final target = '${docs.path}/photo_${_currentAlertId ?? 'manual'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(image.path).copy(target);
          final photoFile = File(target);
          final photoSize = await photoFile.length();
          
          final evidenceId = _uuid.v4();
          await StorageService.instance.saveEvidence(
            id: evidenceId,
            alertId: _currentAlertId ?? 'manual',
            type: 'photo',
            filePath: target,
            fileSize: photoSize,
          );

          // Enfiler pour synchronisation
          await SyncService.instance.addToSyncQueue('evidence', {
            'id': evidenceId,
            'alert_id': _currentAlertId ?? 'manual',
            'type': 'photo',
            'file_path': target,
            'file_size': photoSize,
          });

          if (AppConstants.enableLogging) {
            print('✅ Photo prise et sauvegardée: $target');
          }

          return target;
        }
      } else {
        throw Exception('Caméra non initialisée');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur prise de photo: $e');
      }
      rethrow;
    }
    return null;
  }

  /// Vérifie si l'enregistrement est en cours
  bool get isRecording => _isRecordingAudio || _isRecordingVideo;

  /// Obtient le contrôleur de caméra
  CameraController? get cameraController => _cameraController;

  /// Nettoie les ressources
  Future<void> dispose() async {
    try {
      // Arrêter les enregistrements en cours
      if (_isRecordingAudio) {
        await _stopAudioRecording();
      }
      if (_isRecordingVideo) {
        await _stopVideoRecording();
      }

      // Libérer la caméra
      await _cameraController?.dispose();
      _cameraController = null;

      // Libérer l'enregistreur audio
      await _audioRecorder.dispose();

      if (AppConstants.enableLogging) {
        print('✅ EvidenceService nettoyé');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur nettoyage EvidenceService: $e');
      }
    }
  }

  /// Récupère les preuves pour une alerte spécifique
  Future<List<Map<String, dynamic>>> getEvidencesForAlert(String alertId) async {
    try {
      // Pour l'instant, retourner une liste vide
      // TODO: Implémenter la récupération depuis Supabase
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des preuves: $e');
      return [];
    }
  }

  /// Récupère toutes les preuves de l'utilisateur
  Future<List<Map<String, dynamic>>> getEvidences() async {
    try {
      final local = await StorageService.instance.getLocalEvidence();
      return local;
    } catch (e) {
      print('❌ Erreur lors de la récupération des preuves: $e');
      return [];
    }
  }

  /// Enregistre une preuve audio
  Future<Map<String, dynamic>> recordAudioEvidence({
    required String alertId,
    required String filePath,
    required int duration,
  }) async {
    try {
      // Sauvegarder localement
      final file = File(filePath);
      final size = await file.length();
      final id = _uuid.v4();

      await StorageService.instance.saveEvidence(
        id: id,
        alertId: alertId,
        type: 'audio',
        filePath: filePath,
        fileSize: size,
      );

      // Enfiler pour synchronisation
      await SyncService.instance.addToSyncQueue('evidence', {
        'id': id,
        'alert_id': alertId,
        'type': 'audio',
        'file_path': filePath,
        'file_size': size,
      });

      return {
        'id': id,
        'type': 'audio',
        'filePath': filePath,
        'duration': duration,
        'alertId': alertId,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement audio: $e');
      rethrow;
    }
  }

  /// Supprime une preuve
  Future<void> deleteEvidence(String evidenceId) async {
    try {
      // Supprimer la ligne dans SQLite; le fichier est supprimé côté écran
      await StorageService.instance.removeEvidence(evidenceId);
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// Tente de synchroniser toutes les preuves
  Future<int> attemptSyncAll() async {
    try {
      final local = await StorageService.instance.getLocalEvidence();
      int enqueued = 0;
      for (final row in local) {
        if ((row['synced'] ?? 0) == 1) continue;
        await SyncService.instance.addToSyncQueue('evidence', {
          'id': row['id'],
          'alert_id': row['alert_id'],
          'type': row['type'],
          'file_path': row['file_path'],
          'file_size': row['file_size'],
        });
        enqueued++;
      }
      return enqueued;
    } catch (e) {
      print('❌ Erreur lors de la synchronisation: $e');
      return 0;
    }
  }
}

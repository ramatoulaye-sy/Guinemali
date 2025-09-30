import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

class AudioRecordingService {
  static final AudioRecordingService _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  static AudioRecordingService get instance => _instance;
  AudioRecordingService._internal();

  static const MethodChannel _channel = MethodChannel('audio_recording_service');
  static const EventChannel _eventChannel = EventChannel('audio_recording_events');

  bool _isRecording = false;
  String? _currentAlertId;
  Timer? _syncTimer;
  final List<Map<String, dynamic>> _pendingAudioFiles = [];

  // Getters
  bool get isRecording => _isRecording;
  String? get currentAlertId => _currentAlertId;

  /// Initialiser le service
  Future<void> initialize() async {
    try {
      // Écouter les événements du service Android
      _eventChannel.receiveBroadcastStream().listen(_handleAudioEvent);
      
      // Vérifier les permissions (neutralisé pour éviter MissingPluginException si plugin absent)
      try {
        await _checkPermissions();
      } catch (_) {
        // ignore: avoid_print
        if (AppConstants.enableLogging) {
          print('⚠️ checkPermissions audio ignoré (plugin indisponible)');
        }
      }
      
      print('✅ Service d\'enregistrement audio initialisé');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du service audio: $e');
    }
  }

  /// Démarrer l'enregistrement audio en arrière-plan
  Future<bool> startBackgroundRecording(String alertId) async {
    try {
      if (_isRecording) {
        print('⚠️ L\'enregistrement audio est déjà en cours');
        return true;
      }

      // Vérifier les permissions (tolérant en prod si plugin indisponible)
      try {
        final ok = await _checkPermissions();
        if (!ok && AppConstants.enableLogging) {
          print('❌ Permissions audio refusées');
        }
      } catch (_) {
        // En production sans plugin, continuer silencieusement
      }

      // Démarrer le service Android
      final result = await _channel.invokeMethod('startRecording', {
        'alert_id': alertId,
      });

      if (result == true) {
        _isRecording = true;
        _currentAlertId = alertId;
        
        // Démarrer la synchronisation périodique
        _startAudioSyncTimer();
        
        print('✅ Enregistrement audio démarré pour l\'alerte: $alertId');
        return true;
      } else {
        print('❌ Échec du démarrage de l\'enregistrement audio');
        return false;
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors du démarrage de l\'enregistrement audio: $e');
      }
      return false;
    }
  }

  /// Arrêter l'enregistrement audio
  Future<bool> stopBackgroundRecording() async {
    try {
      if (!_isRecording) {
        print('⚠️ Aucun enregistrement audio en cours');
        return true;
      }

      // Arrêter le service Android
      final result = await _channel.invokeMethod('stopRecording');

      if (result == true) {
        _isRecording = false;
        _currentAlertId = null;
        
        // Arrêter le timer de synchronisation
        _stopAudioSyncTimer();
        
        // Synchroniser une dernière fois
        await _syncAudioFiles();
        
        print('✅ Enregistrement audio arrêté');
        return true;
      } else {
        print('❌ Échec de l\'arrêt de l\'enregistrement audio');
        return false;
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de l\'arrêt de l\'enregistrement audio: $e');
      }
      return false;
    }
  }

  /// Mettre en pause l'enregistrement audio
  Future<bool> pauseRecording() async {
    try {
      if (!_isRecording) return false;

      final result = await _channel.invokeMethod('pauseRecording');
      if (result == true) {
        print('✅ Enregistrement audio mis en pause');
        return true;
      }
      return false;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de la pause de l\'enregistrement: $e');
      }
      return false;
    }
  }

  /// Reprendre l'enregistrement audio
  Future<bool> resumeRecording() async {
    try {
      if (!_isRecording) return false;

      final result = await _channel.invokeMethod('resumeRecording');
      if (result == true) {
        print('✅ Enregistrement audio repris');
        return true;
      }
      return false;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de la reprise de l\'enregistrement: $e');
      }
      return false;
    }
  }

  /// Vérifier les permissions audio
  Future<bool> _checkPermissions() async {
    try {
      final result = await _channel.invokeMethod('checkPermissions');
      return result == true;
    } catch (e) {
      // Tolérer l'absence de plugin en production
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de la vérification des permissions: $e');
      }
      return false;
    }
  }

  /// Démarrer le timer de synchronisation audio
  void _startAudioSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _syncAudioFiles();
    });
  }

  /// Arrêter le timer de synchronisation audio
  void _stopAudioSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Synchroniser les fichiers audio avec Supabase
  Future<void> _syncAudioFiles() async {
    try {
      // Récupérer les fichiers audio locaux
      final audioFiles = await _getLocalAudioFiles();
      
      for (final audioFile in audioFiles) {
        if (!audioFile['synced']) {
          try {
            // Vérifier si le fichier existe
            final file = File(audioFile['file_path']);
            if (await file.exists()) {
              // Uploader vers Supabase Storage
              final uploadResult = await _uploadAudioToSupabase(file, audioFile);
              
              if (uploadResult != null) {
                // Insérer dans la table des preuves
                await _insertAudioEvidence(audioFile, uploadResult);
                
                // Marquer comme synchronisé
                await _markAudioAsSynced(audioFile['file_path']);
                
                print('✅ Fichier audio synchronisé: ${audioFile['file_name']}');
              }
            }
          } catch (e) {
            print('❌ Erreur lors de la synchronisation du fichier audio: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la synchronisation audio: $e');
    }
  }

  /// Récupérer les fichiers audio locaux
  Future<List<Map<String, dynamic>>> _getLocalAudioFiles() async {
    try {
      final recordingsDir = Directory('${(await getApplicationDocumentsDirectory()).path}/audio_recordings');
      if (!await recordingsDir.exists()) return [];

      final List<Map<String, dynamic>> audioFiles = [];
      final files = recordingsDir.listSync();

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final metadata = Map<String, dynamic>.from(
              jsonDecode(content) as Map<String, dynamic>
            );
            audioFiles.add(metadata);
          } catch (e) {
            print('❌ Erreur lors de la lecture des métadonnées: $e');
          }
        }
      }

      return audioFiles;
    } catch (e) {
      print('❌ Erreur lors de la récupération des fichiers audio: $e');
      return [];
    }
  }

  /// Uploader un fichier audio vers Supabase Storage
  Future<String?> _uploadAudioToSupabase(File audioFile, Map<String, dynamic> metadata) async {
    try {
      final fileName = 'audio_${metadata['alert_id']}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final fileBytes = await audioFile.readAsBytes();
      
      // Upload vers Supabase Storage
      final result = await SupabaseService.instance.uploadFile(
        bucket: 'audio_evidence',
        path: fileName,
        file: fileBytes,
        metadata: {'content-type': 'audio/mp4'},
      );
      
      return result;
    } catch (e) {
      print('❌ Erreur lors de l\'upload audio: $e');
      return null;
    }
  }

  /// Insérer l'évidence audio dans la base de données
  Future<void> _insertAudioEvidence(Map<String, dynamic> metadata, String storageUrl) async {
    try {
      final evidenceData = {
        'alerte_id': metadata['alert_id'],
        'type': 'audio',
        'chemin_fichier': storageUrl,
        'notes': 'Enregistrement audio automatique',
        'timestamp': DateTime.now().toIso8601String(),
        'duree_ms': metadata['duration_ms'],
        'taille_fichier': metadata['file_size'],
      };

      await SupabaseService.instance.insert('preuves', evidenceData);
      print('✅ Évidence audio insérée dans la base de données');
    } catch (e) {
      print('❌ Erreur lors de l\'insertion de l\'évidence audio: $e');
    }
  }

  /// Marquer un fichier audio comme synchronisé
  Future<void> _markAudioAsSynced(String filePath) async {
    try {
      final metadataFile = File('${filePath.substring(0, filePath.lastIndexOf('.'))}.json');
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final metadata = Map<String, dynamic>.from(
          jsonDecode(content) as Map<String, dynamic>
        );
        
        metadata['synced'] = true;
        await metadataFile.writeAsString(jsonEncode(metadata));
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut de synchronisation: $e');
    }
  }

  /// Gérer les événements du service Android
  void _handleAudioEvent(dynamic event) {
    try {
      final eventData = Map<String, dynamic>.from(event as Map<String, dynamic>);
      final eventType = eventData['type'];
      
      switch (eventType) {
        case 'recording_started':
          print('✅ Enregistrement audio démarré côté Android');
          break;
        case 'recording_stopped':
          print('✅ Enregistrement audio arrêté côté Android');
          _isRecording = false;
          break;
        case 'recording_paused':
          print('✅ Enregistrement audio mis en pause côté Android');
          break;
        case 'recording_resumed':
          print('✅ Enregistrement audio repris côté Android');
          break;
        case 'file_created':
          final filePath = eventData['file_path'];
          print('✅ Nouveau fichier audio créé: $filePath');
          // Ajouter à la liste des fichiers en attente de synchronisation
          _pendingAudioFiles.add({
            'file_path': filePath,
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
        case 'error':
          final error = eventData['error'];
          print('❌ Erreur du service audio Android: $error');
          break;
        default:
          print('ℹ️ Événement audio inconnu: $eventType');
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de l\'événement audio: $e');
    }
  }

  /// Obtenir le statut de l'enregistrement
  Future<Map<String, dynamic>> getRecordingStatus() async {
    try {
      final result = await _channel.invokeMethod('getStatus');
      return Map<String, dynamic>.from(result as Map<String, dynamic>);
    } catch (e) {
      print('❌ Erreur lors de la récupération du statut: $e');
      return {
        'is_recording': _isRecording,
        'duration_ms': 0,
        'file_path': null,
      };
    }
  }

  /// Nettoyer les fichiers audio synchronisés
  Future<void> cleanupSyncedFiles() async {
    try {
      final audioFiles = await _getLocalAudioFiles();
      
      for (final audioFile in audioFiles) {
        if (audioFile['synced'] == true) {
          try {
            // Supprimer le fichier audio
            final audioFilePath = audioFile['file_path'];
            final audioFileObj = File(audioFilePath);
            if (await audioFileObj.exists()) {
              await audioFileObj.delete();
            }
            
            // Supprimer le fichier de métadonnées
            final metadataPath = '${audioFilePath.substring(0, audioFilePath.lastIndexOf('.'))}.json';
            final metadataFile = File(metadataPath);
            if (await metadataFile.exists()) {
              await metadataFile.delete();
            }
            
            print('✅ Fichier audio nettoyé: ${audioFile['file_name']}');
          } catch (e) {
            print('❌ Erreur lors du nettoyage du fichier: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Erreur lors du nettoyage des fichiers audio: $e');
    }
  }

  /// Disposer le service
  void dispose() {
    _stopAudioSyncTimer();
    _channel.setMethodCallHandler(null);
  }
}

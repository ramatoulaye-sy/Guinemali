import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

/// Service de test simplifié pour diagnostiquer les problèmes d'enregistrement
class EvidenceTestService {
  static EvidenceTestService? _instance;
  static EvidenceTestService get instance => _instance ??= EvidenceTestService._();
  
  EvidenceTestService._();

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  /// Test complet de l'enregistrement audio
  Future<Map<String, dynamic>> runFullTest() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Vérification des permissions
      results['permissions'] = await _testPermissions();
      
      // Test 2: Vérification de l'enregistreur
      results['recorder'] = await _testRecorder();
      
      // Test 3: Test d'enregistrement simple
      if (results['permissions']['success'] && results['recorder']['success']) {
        results['recording'] = await _testSimpleRecording();
      } else {
        results['recording'] = {'success': false, 'error': 'Prérequis non satisfaits'};
      }
      
      // Test 4: Vérification du fichier
      if (results['recording']['success']) {
        results['file'] = await _testFileCreation();
      } else {
        results['file'] = {'success': false, 'error': 'Enregistrement échoué'};
      }
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Test des permissions microphone
  Future<Map<String, dynamic>> _testPermissions() async {
    try {
      final status = await Permission.microphone.status;
      
      if (status.isGranted) {
        return {'success': true, 'status': 'granted'};
      } else if (status.isDenied) {
        final requestResult = await Permission.microphone.request();
        return {
          'success': requestResult.isGranted,
          'status': requestResult.isGranted ? 'granted' : 'denied',
          'requested': true
        };
      } else {
        return {'success': false, 'status': status.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test de l'enregistreur audio
  Future<Map<String, dynamic>> _testRecorder() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      final isRecording = await _audioRecorder.isRecording();
      
      return {
        'success': hasPermission,
        'hasPermission': hasPermission,
        'isRecording': isRecording,
        'available': true
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test d'enregistrement simple
  Future<Map<String, dynamic>> _testSimpleRecording() async {
    try {
      if (_isRecording) {
        return {'success': false, 'error': 'Enregistrement déjà en cours'};
      }

      // Créer le dossier temporaire
      final directory = await getTemporaryDirectory();
      final fileName = 'test_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${directory.path}/$fileName';
      
      // Démarrer l'enregistrement
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
      
      _isRecording = true;
      _currentRecordingPath = filePath;
      
      // Attendre 2 secondes
      await Future.delayed(const Duration(seconds: 2));
      
      // Arrêter l'enregistrement
      final recordedPath = await _audioRecorder.stop();
      _isRecording = false;
      
      return {
        'success': true,
        'filePath': recordedPath ?? filePath,
        'duration': '2 secondes'
      };
    } catch (e) {
      _isRecording = false;
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test de création de fichier
  Future<Map<String, dynamic>> _testFileCreation() async {
    try {
      if (_currentRecordingPath == null) {
        return {'success': false, 'error': 'Aucun fichier enregistré'};
      }
      
      final file = File(_currentRecordingPath!);
      final exists = await file.exists();
      
      if (!exists) {
        return {'success': false, 'error': 'Fichier non trouvé'};
      }
      
      final size = await file.length();
      final lastModified = await file.lastModified();
      
      return {
        'success': true,
        'exists': true,
        'size': size,
        'sizeKB': (size / 1024).toStringAsFixed(2),
        'lastModified': lastModified.toIso8601String(),
        'path': _currentRecordingPath
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Nettoyer les fichiers de test
  Future<void> cleanupTestFiles() async {
    try {
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          if (AppConstants.enableLogging) {
            print('✅ Fichier de test supprimé: $_currentRecordingPath');
          }
        }
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur nettoyage: $e');
      }
    }
  }

  /// Obtenir un rapport de test formaté
  String getTestReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('🔍 RAPPORT DE TEST - ENREGISTREMENT AUDIO');
    buffer.writeln('=' * 50);
    
    // Permissions
    final permissions = results['permissions'] as Map<String, dynamic>?;
    if (permissions != null) {
      buffer.writeln('📱 PERMISSIONS:');
      buffer.writeln('  ✅ Succès: ${permissions['success']}');
      buffer.writeln('  📊 Statut: ${permissions['status']}');
      if (permissions['error'] != null) {
        buffer.writeln('  ❌ Erreur: ${permissions['error']}');
      }
    }
    
    // Enregistreur
    final recorder = results['recorder'] as Map<String, dynamic>?;
    if (recorder != null) {
      buffer.writeln('\n🎙️ ENREGISTREUR:');
      buffer.writeln('  ✅ Succès: ${recorder['success']}');
      buffer.writeln('  🔐 Permission: ${recorder['hasPermission']}');
      buffer.writeln('  ⏺️ En cours: ${recorder['isRecording']}');
      if (recorder['error'] != null) {
        buffer.writeln('  ❌ Erreur: ${recorder['error']}');
      }
    }
    
    // Enregistrement
    final recording = results['recording'] as Map<String, dynamic>?;
    if (recording != null) {
      buffer.writeln('\n🎵 ENREGISTREMENT:');
      buffer.writeln('  ✅ Succès: ${recording['success']}');
      if (recording['success']) {
        buffer.writeln('  📁 Fichier: ${recording['filePath']}');
        buffer.writeln('  ⏱️ Durée: ${recording['duration']}');
      }
      if (recording['error'] != null) {
        buffer.writeln('  ❌ Erreur: ${recording['error']}');
      }
    }
    
    // Fichier
    final file = results['file'] as Map<String, dynamic>?;
    if (file != null) {
      buffer.writeln('\n📄 FICHIER:');
      buffer.writeln('  ✅ Succès: ${file['success']}');
      if (file['success']) {
        buffer.writeln('  📊 Taille: ${file['sizeKB']} KB');
        buffer.writeln('  📅 Modifié: ${file['lastModified']}');
      }
      if (file['error'] != null) {
        buffer.writeln('  ❌ Erreur: ${file['error']}');
      }
    }
    
    // Erreur générale
    if (results['error'] != null) {
      buffer.writeln('\n❌ ERREUR GÉNÉRALE:');
      buffer.writeln('  ${results['error']}');
    }
    
    buffer.writeln('\n' + '=' * 50);
    return buffer.toString();
  }
}

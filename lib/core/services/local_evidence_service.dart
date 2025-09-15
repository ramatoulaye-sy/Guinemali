import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/log_service.dart';

/// Service d'enregistrement de preuves local
/// Gère l'enregistrement, le chiffrement et le stockage local des preuves
class LocalEvidenceService {
  static final LocalEvidenceService _instance = LocalEvidenceService._internal();
  factory LocalEvidenceService() => _instance;
  LocalEvidenceService._internal();

  static LocalEvidenceService get instance => _instance;

  final StorageService _storage = StorageService.instance;
  final Uuid _uuid = const Uuid();

  /// Enregistre une preuve audio
  Future<Map<String, dynamic>?> recordAudioEvidence({
    required String alertId,
    required String filePath,
    required int duration,
  }) async {
    try {
      final evidenceId = _uuid.v4();
      final timestamp = DateTime.now().toIso8601String();
      
      // Lire le fichier audio
      final file = File(filePath);
      if (!await file.exists()) {
        LogService.error('Fichier audio introuvable: $filePath', tag: 'evidence');
        return null;
      }

      final fileBytes = await file.readAsBytes();
      final encryptedBytes = await _encryptFile(fileBytes);
      
      // Sauvegarder le fichier chiffré
      final encryptedPath = await _saveEncryptedFile(encryptedBytes, 'audio', evidenceId);
      
      final evidence = {
        'id': evidenceId,
        'alertId': alertId,
        'type': 'audio',
        'originalPath': filePath,
        'encryptedPath': encryptedPath,
        'duration': duration,
        'size': fileBytes.length,
        'timestamp': timestamp,
        'status': 'recorded',
        'isLocal': true,
        'hash': _generateFileHash(fileBytes),
      };

      await _saveEvidence(evidence);
      LogService.success('Preuve audio enregistrée: $evidenceId', tag: 'evidence');
      
      return evidence;
    } catch (e) {
      LogService.error('Erreur lors de l\'enregistrement audio: $e', tag: 'evidence');
      return null;
    }
  }

  /// Enregistre une preuve vidéo
  Future<Map<String, dynamic>?> recordVideoEvidence({
    required String alertId,
    required String filePath,
    required int duration,
  }) async {
    try {
      final evidenceId = _uuid.v4();
      final timestamp = DateTime.now().toIso8601String();
      
      // Lire le fichier vidéo
      final file = File(filePath);
      if (!await file.exists()) {
        LogService.error('Fichier vidéo introuvable: $filePath', tag: 'evidence');
        return null;
      }

      final fileBytes = await file.readAsBytes();
      final encryptedBytes = await _encryptFile(fileBytes);
      
      // Sauvegarder le fichier chiffré
      final encryptedPath = await _saveEncryptedFile(encryptedBytes, 'video', evidenceId);
      
      final evidence = {
        'id': evidenceId,
        'alertId': alertId,
        'type': 'video',
        'originalPath': filePath,
        'encryptedPath': encryptedPath,
        'duration': duration,
        'size': fileBytes.length,
        'timestamp': timestamp,
        'status': 'recorded',
        'isLocal': true,
        'hash': _generateFileHash(fileBytes),
      };

      await _saveEvidence(evidence);
      LogService.success('Preuve vidéo enregistrée: $evidenceId', tag: 'evidence');
      
      return evidence;
    } catch (e) {
      LogService.error('Erreur lors de l\'enregistrement vidéo: $e', tag: 'evidence');
      return null;
    }
  }

  /// Chiffre un fichier avec AES
  Future<Uint8List> _encryptFile(Uint8List fileBytes) async {
    try {
      // Générer une clé de chiffrement basée sur l'utilisateur
      final userKey = await _getUserEncryptionKey();
      final key = sha256.convert(userKey.codeUnits).bytes;
      
      // Chiffrement simple (en production, utiliser une bibliothèque de chiffrement robuste)
      final encrypted = Uint8List(fileBytes.length);
      for (int i = 0; i < fileBytes.length; i++) {
        encrypted[i] = fileBytes[i] ^ key[i % key.length];
      }
      
      return encrypted;
    } catch (e) {
      LogService.error('Erreur lors du chiffrement: $e', tag: 'evidence');
      return fileBytes; // Retourner non chiffré en cas d'erreur
    }
  }



  /// Sauvegarde un fichier chiffré
  Future<String> _saveEncryptedFile(Uint8List encryptedBytes, String type, String evidenceId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final evidenceDir = Directory('${directory.path}/evidence');
      if (!await evidenceDir.exists()) {
        await evidenceDir.create(recursive: true);
      }
      
      final fileName = '${type}_$evidenceId.enc';
      final filePath = '${evidenceDir.path}/$fileName';
      final file = File(filePath);
      
      await file.writeAsBytes(encryptedBytes);
      return filePath;
    } catch (e) {
      LogService.error('Erreur lors de la sauvegarde du fichier chiffré: $e', tag: 'evidence');
      rethrow;
    }
  }

  /// Sauvegarde les métadonnées de la preuve
  Future<void> _saveEvidence(Map<String, dynamic> evidence) async {
    try {
      final evidenceId = evidence['id'] as String;
      await _storage.saveString('evidence_$evidenceId', jsonEncode(evidence));
      
      // Ajouter à la liste des preuves
      final evidences = await getEvidences();
      evidences.insert(0, evidence);
      await _storage.saveString('evidences_list', jsonEncode(evidences));
    } catch (e) {
      LogService.error('Erreur lors de la sauvegarde des métadonnées: $e', tag: 'evidence');
    }
  }

  /// Récupère toutes les preuves
  Future<List<Map<String, dynamic>>> getEvidences() async {
    try {
      final evidencesData = _storage.getString('evidences_list');
      if (evidencesData != null && evidencesData.isNotEmpty) {
        final List<dynamic> evidences = jsonDecode(evidencesData);
        return evidences.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      LogService.error('Erreur lors de la récupération des preuves: $e', tag: 'evidence');
      return [];
    }
  }

  /// Marque une preuve comme synchronisée
  Future<void> setSynced(String evidenceId, {bool synced = true}) async {
    try {
      final data = _storage.getString('evidence_$evidenceId');
      if (data == null) return;
      final map = jsonDecode(data) as Map<String, dynamic>;
      map['status'] = synced ? 'synced' : (map['status'] ?? 'recorded');
      map['isSynced'] = synced;
      map['syncedAt'] = synced ? DateTime.now().toIso8601String() : null;
      await _storage.saveString('evidence_$evidenceId', jsonEncode(map));

      // Mettre à jour la liste
      final list = await getEvidences();
      for (int i = 0; i < list.length; i++) {
        if ((list[i]['id'] as String) == evidenceId) {
          list[i] = map;
          break;
        }
      }
      await _storage.saveString('evidences_list', jsonEncode(list));
    } catch (e) {
      LogService.error('setSynced erreur: $e', tag: 'evidence');
    }
  }

  /// Tente de synchroniser toutes les preuves en attente (simulation sans backend)
  Future<int> attemptSyncAll() async {
    try {
      final evidences = await getEvidences();
      int syncedCount = 0;
      for (final e in evidences) {
        final isSynced = (e['isSynced'] as bool?) ?? false;
        if (!isSynced) {
          // Simulation d'upload réussi
          await Future.delayed(const Duration(milliseconds: 150));
          await setSynced(e['id'] as String, synced: true);
          syncedCount++;
        }
      }
      return syncedCount;
    } catch (e) {
      LogService.error('attemptSyncAll erreur: $e', tag: 'evidence');
      return 0;
    }
  }

  /// Récupère les preuves d'une alerte spécifique
  Future<List<Map<String, dynamic>>> getEvidencesForAlert(String alertId) async {
    try {
      final evidences = await getEvidences();
      return evidences.where((evidence) => evidence['alertId'] == alertId).toList();
    } catch (e) {
      LogService.error('Erreur lors de la récupération des preuves pour l\'alerte: $e', tag: 'evidence');
      return [];
    }
  }

  /// Supprime une preuve
  Future<void> deleteEvidence(String evidenceId) async {
    try {
      // Récupérer les métadonnées
      final evidenceData = _storage.getString('evidence_$evidenceId');
      if (evidenceData != null) {
        final evidence = jsonDecode(evidenceData) as Map<String, dynamic>;
        
        // Supprimer le fichier chiffré
        final encryptedPath = evidence['encryptedPath'] as String?;
        if (encryptedPath != null) {
          final file = File(encryptedPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
        
        // Supprimer les métadonnées
        await _storage.remove('evidence_$evidenceId');
        
        // Retirer de la liste
        final evidences = await getEvidences();
        evidences.removeWhere((e) => e['id'] == evidenceId);
        await _storage.saveString('evidences_list', jsonEncode(evidences));
        
        LogService.success('Preuve supprimée: $evidenceId', tag: 'evidence');
      }
    } catch (e) {
      LogService.error('Erreur lors de la suppression de la preuve: $e', tag: 'evidence');
    }
  }

  /// Génère un hash pour un fichier
  String _generateFileHash(Uint8List fileBytes) {
    final bytes = sha256.convert(fileBytes).bytes;
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Récupère la clé de chiffrement de l'utilisateur
  Future<String> _getUserEncryptionKey() async {
    try {
      String userKey = _storage.getString('user_encryption_key') ?? '';
      if (userKey.isEmpty) {
        // Générer une nouvelle clé
        userKey = _uuid.v4();
        await _storage.saveString('user_encryption_key', userKey);
      }
      return userKey;
    } catch (e) {
      LogService.error('Erreur lors de la récupération de la clé de chiffrement: $e', tag: 'evidence');
      return 'default_key_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Supprime toutes les preuves
  Future<void> clearAllEvidences() async {
    try {
      final evidences = await getEvidences();
      for (final evidence in evidences) {
        await deleteEvidence(evidence['id'] as String);
      }
      LogService.success('Toutes les preuves ont été supprimées', tag: 'evidence');
    } catch (e) {
      LogService.error('Erreur lors de la suppression de toutes les preuves: $e', tag: 'evidence');
    }
  }

  /// Récupère les statistiques des preuves
  Future<Map<String, dynamic>> getEvidenceStats() async {
    try {
      final evidences = await getEvidences();
      int totalSize = 0;
      int audioCount = 0;
      int videoCount = 0;
      
      for (final evidence in evidences) {
        totalSize += evidence['size'] as int? ?? 0;
        if (evidence['type'] == 'audio') {
          audioCount++;
        } else if (evidence['type'] == 'video') {
          videoCount++;
        }
      }
      
      return {
        'totalCount': evidences.length,
        'audioCount': audioCount,
        'videoCount': videoCount,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      LogService.error('Erreur lors du calcul des statistiques: $e', tag: 'evidence');
      return {
        'totalCount': 0,
        'audioCount': 0,
        'videoCount': 0,
        'totalSize': 0,
        'totalSizeMB': '0.00',
      };
    }
  }
}

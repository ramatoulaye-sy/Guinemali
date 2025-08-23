import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/supabase_service.dart';

/// Service de synchronisation robuste pour la gestion hors-ligne → en ligne
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  static SyncService get instance => _instance;
  SyncService._internal();

  // Timers et état
  Timer? _syncTimer;
  Timer? _connectivityTimer;
  bool _isOnline = true;
  bool _isSyncing = false;
  int _retryCount = 0;
  final int _maxRetries = 5;
  
  // File d'attente des données à synchroniser
  final List<Map<String, dynamic>> _syncQueue = [];
  final List<Map<String, dynamic>> _failedItems = [];
  
  // Configuration
  static const Duration _syncInterval = Duration(minutes: 2);
  static const Duration _connectivityCheckInterval = Duration(seconds: 30);
  static const Duration _initialRetryDelay = Duration(seconds: 10);
  
  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingItemsCount => _syncQueue.length;
  int get failedItemsCount => _failedItems.length;

  /// Initialiser le service de synchronisation
  Future<void> initialize() async {
    try {
      // Vérifier l'état initial de la connexion
      await _checkConnectivity();
      
      // Démarrer le monitoring de la connectivité
      _startConnectivityMonitoring();
      
      // Démarrer la synchronisation périodique
      _startPeriodicSync();
      
      // Tenter une synchronisation immédiate si en ligne
      if (_isOnline) {
        await _performSync();
      }
      
      print('✅ Service de synchronisation initialisé');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du service de sync: $e');
    }
  }

  /// Démarrer le monitoring de la connectivité
  void _startConnectivityMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(_connectivityCheckInterval, (_) {
      _checkConnectivity();
    });
  }

  /// Vérifier l'état de la connexion
  Future<void> _checkConnectivity() async {
    try {
      // Test simple de connectivité en tentant une requête vers Supabase
      final connectivityResults = await Connectivity().checkConnectivity();
      final wasOnline = _isOnline;
      
      _isOnline = connectivityResults.isNotEmpty && connectivityResults.any((result) => result != ConnectivityResult.none);
      
      // Si on repasse en ligne, tenter une synchronisation
      if (!wasOnline && _isOnline) {
        print('🌐 Connexion rétablie - Lancement de la synchronisation');
        await _performSync();
      } else if (wasOnline && !_isOnline) {
        print('📡 Connexion perdue - Mode hors-ligne activé');
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification de la connectivité: $e');
      _isOnline = false;
    }
  }

  /// Démarrer la synchronisation périodique
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isOnline && !_isSyncing) {
        _performSync();
      }
    });
  }

  /// Ajouter un élément à la file de synchronisation
  Future<void> addToSyncQueue(String type, Map<String, dynamic> data) async {
    try {
      final syncItem = {
        'id': '${type}_${DateTime.now().millisecondsSinceEpoch}',
        'type': type,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'last_attempt': null,
        'next_retry': null,
      };
      
      _syncQueue.add(syncItem);
      
      // Sauvegarder localement
      await StorageService.instance.saveSyncQueueItem(syncItem);
      
      print('✅ Élément ajouté à la file de sync: ${syncItem['id']}');
      
      // Tenter une synchronisation immédiate si en ligne
      if (_isOnline && !_isSyncing) {
        await _performSync();
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ajout à la file de sync: $e');
    }
  }

  /// Effectuer la synchronisation
  Future<void> _performSync() async {
    if (_isSyncing || !_isOnline || _syncQueue.isEmpty) return;
    
    _isSyncing = true;
    print('🔄 Début de la synchronisation (${_syncQueue.length} éléments)');
    
    try {
      // Traiter chaque élément de la file
      final itemsToProcess = List.from(_syncQueue);
      
      for (final item in itemsToProcess) {
        try {
          await _processSyncItem(item);
          
          // Retirer de la file si succès
          _syncQueue.removeWhere((element) => element['id'] == item['id']);
          await StorageService.instance.removeSyncQueueItem(item['id']);
          
          print('✅ Élément synchronisé avec succès: ${item['id']}');
        } catch (e) {
          print('❌ Échec de synchronisation de ${item['id']}: $e');
          await _handleSyncFailure(item, e.toString());
        }
      }
      
      // Réinitialiser le compteur de retry en cas de succès
      _retryCount = 0;
      
    } catch (e) {
      print('❌ Erreur générale lors de la synchronisation: $e');
    } finally {
      _isSyncing = false;
      print('🔄 Synchronisation terminée');
    }
  }

  /// Traiter un élément de synchronisation
  Future<void> _processSyncItem(Map<String, dynamic> item) async {
    final type = item['type'];
    final data = item['data'];
    
    switch (type) {
      case 'alerte':
        await _syncAlert(data);
        break;
      case 'position':
        await _syncPosition(data);
        break;
      case 'evidence':
        await _syncEvidence(data);
        break;
      case 'contact':
        await _syncContact(data);
        break;
      case 'audio':
        await _syncAudio(data);
        break;
      default:
        throw Exception('Type de synchronisation inconnu: $type');
    }
  }

  /// Synchroniser une alerte
  Future<void> _syncAlert(Map<String, dynamic> alertData) async {
    try {
      await SupabaseService.instance.insert('alertes', alertData);
      print('✅ Alerte synchronisée: ${alertData['id']}');
    } catch (e) {
      throw Exception('Échec sync alerte: $e');
    }
  }

  /// Synchroniser une position GPS
  Future<void> _syncPosition(Map<String, dynamic> positionData) async {
    try {
      await SupabaseService.instance.insert('positions_alertes', positionData);
      print('✅ Position synchronisée: ${positionData['id']}');
    } catch (e) {
      throw Exception('Échec sync position: $e');
    }
  }

  /// Synchroniser une preuve
  Future<void> _syncEvidence(Map<String, dynamic> evidenceData) async {
    try {
      await SupabaseService.instance.insert('preuves', evidenceData);
      print('✅ Preuve synchronisée: ${evidenceData['id']}');
    } catch (e) {
      throw Exception('Échec sync preuve: $e');
    }
  }

  /// Synchroniser un contact
  Future<void> _syncContact(Map<String, dynamic> contactData) async {
    try {
      await SupabaseService.instance.insert('contacts_urgence', contactData);
      print('✅ Contact synchronisé: ${contactData['id']}');
    } catch (e) {
      throw Exception('Échec sync contact: $e');
    }
  }

  /// Synchroniser un fichier audio
  Future<void> _syncAudio(Map<String, dynamic> audioData) async {
    try {
      // Upload du fichier audio vers Supabase Storage
      final filePath = audioData['file_path'];
      final file = File(filePath);
      
      if (await file.exists()) {
        final fileBytes = await file.readAsBytes();
        final fileName = audioData['file_name'];
        
        final uploadResult = await SupabaseService.instance.uploadFile(
          bucket: 'audio_evidence',
          path: fileName,
          file: fileBytes,
          metadata: {'content-type': 'audio/mp4'},
        );
        
        // Insérer dans la table des preuves
        final evidenceData = {
          'alerte_id': audioData['alert_id'],
          'type': 'audio',
          'chemin_fichier': uploadResult,
          'notes': 'Enregistrement audio automatique',
          'timestamp': DateTime.now().toIso8601String(),
          'duree_ms': audioData['duration_ms'],
          'taille_fichier': audioData['file_size'],
        };
        
        await SupabaseService.instance.insert('preuves', evidenceData);
        print('✅ Audio synchronisé: $fileName');
      } else {
        throw Exception('Fichier audio introuvable: $filePath');
      }
    } catch (e) {
      throw Exception('Échec sync audio: $e');
    }
  }

  /// Gérer l'échec de synchronisation d'un élément
  Future<void> _handleSyncFailure(Map<String, dynamic> item, String error) async {
    try {
      final retryCount = (item['retry_count'] ?? 0) + 1;
      
      if (retryCount <= _maxRetries) {
        // Calculer le délai de retry avec backoff exponentiel
        final delay = _initialRetryDelay * (1 << (retryCount - 1));
        final nextRetry = DateTime.now().add(delay);
        
        // Mettre à jour l'élément
        item['retry_count'] = retryCount;
        item['last_attempt'] = DateTime.now().toIso8601String();
        item['next_retry'] = nextRetry.toIso8601String();
        item['last_error'] = error;
        
        // Sauvegarder les modifications
        await StorageService.instance.updateSyncQueueItem(item);
        
        print('⏰ Retry programmé pour ${item['id']} dans ${delay.inSeconds}s (tentative $retryCount/$_maxRetries)');
        
        // Programmer le retry
        Timer(delay, () {
          if (_isOnline && !_isSyncing) {
            _performSync();
          }
        });
      } else {
        // Déplacer vers la liste des échecs
        _failedItems.add(item);
        _syncQueue.removeWhere((element) => element['id'] == item['id']);
        
        // Sauvegarder localement
        await StorageService.instance.saveFailedSyncItem(item);
        await StorageService.instance.removeSyncQueueItem(item['id']);
        
        print('❌ Élément ${item['id']} marqué comme échec définitif après $_maxRetries tentatives');
      }
    } catch (e) {
      print('❌ Erreur lors de la gestion de l\'échec: $e');
    }
  }

  /// Forcer une synchronisation immédiate
  Future<void> forceSync() async {
    if (_isSyncing) {
      print('⚠️ Synchronisation déjà en cours');
      return;
    }
    
    print('🚀 Synchronisation forcée lancée');
    await _performSync();
  }

  /// Nettoyer les éléments échoués
  Future<void> clearFailedItems() async {
    try {
      _failedItems.clear();
      await StorageService.instance.clearFailedSyncItems();
      print('✅ Éléments échoués nettoyés');
    } catch (e) {
      print('❌ Erreur lors du nettoyage des éléments échoués: $e');
    }
  }

  /// Obtenir le statut de la synchronisation
  Map<String, dynamic> getSyncStatus() {
    return {
      'is_online': _isOnline,
      'is_syncing': _isSyncing,
      'pending_items': _syncQueue.length,
      'failed_items': _failedItems.length,
      'retry_count': _retryCount,
      'last_sync': _syncTimer?.isActive == true ? 'Active' : 'Inactive',
    };
  }

  /// Nettoyer les ressources
  void dispose() {
    _syncTimer?.cancel();
    _connectivityTimer?.cancel();
    print('✅ Service de synchronisation nettoyé');
  }
}

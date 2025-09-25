import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../models/alert_model.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import 'geolocation_service.dart';
import 'audio_recording_service.dart';
import 'sync_service.dart';
import 'realtime_service.dart';
import 'emergency_contact_service.dart';
import 'dart:async';

/// Service de gestion des alertes d'urgence
class AlertService {
  static AlertService? _instance;
  static AlertService get instance => _instance ??= AlertService._();
  
  AlertService._();

  final _uuid = const Uuid();
  Timer? _locationSyncTimer;
  final RealtimeService _realtimeService = RealtimeService();

  /// Crée une nouvelle alerte d'urgence
  Future<String> createEmergencyAlert({
    required double latitude,
    required double longitude,
    String type = 'urgence',
    int dangerLevel = 5,
    String? description,
  }) async {
    try {
      // Essayer d'obtenir l'ID utilisateur, mais ne pas échouer si pas connecté
      String? userId = AuthService.instance.userId;
      
      // Si pas d'utilisateur connecté, utiliser un ID temporaire pour le mode hors ligne
      if (userId == null) {
        userId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
        if (AppConstants.enableLogging) {
          print('⚠️ Mode hors ligne - Utilisation d\'un ID temporaire: $userId');
        }
      }

      if (AppConstants.enableLogging) {
        print('🚨 Création d\'alerte pour utilisateur: $userId');
      }

      // Créer un identifiant local immédiatement
      String alertId = _uuid.v4();

      // Toujours créer/sauvegarder localement IMMÉDIATEMENT pour éviter tout blocage réseau
      final alertData = {
        'id': alertId,
        'utilisateur_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'type_alerte': type,
        'niveau_danger': dangerLevel,
        'statut': 'active',
        'description': description,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      // Stockage local et file de sync non bloquants pour l'UI
      await _saveAlertLocally(alertData);
      await SyncService.instance.addToSyncQueue('alerte', alertData);
      try { await StorageService.instance.saveString(AppConstants.keyCurrentAlertId, alertId); } catch (_) {}

      // Lancer en arrière-plan les opérations réseau (non bloquantes)
      if (!userId.startsWith('offline_')) {
        Future(() async {
          try {
            final result = await SupabaseService.instance.rpc(
              'creer_alerte_avec_notifications',
              params: {
                'p_utilisateur_id': userId,
                'p_latitude': latitude,
                'p_longitude': longitude,
                'p_type_alerte': type,
                'p_niveau_danger': dangerLevel,
                'p_description': description,
              },
            ).timeout(AppConstants.timeoutShort);
            if (result != null) {
              if (AppConstants.enableLogging) {
                print('✅ Alerte créée via RPC: ${result.toString()}');
              }
            }
          } catch (e) {
            if (AppConstants.enableLogging) {
              print('⚠️ RPC en arrière-plan échouée: $e');
            }
          }
        });
      }

      // Notifications en arrière-plan
      Future(() async {
        try { await _notifyEmergencyContacts(alertId, latitude, longitude); } catch (e) {
          if (AppConstants.enableLogging) { print('⚠️ Erreur notification contacts: $e'); }
        }
        try { await _notifyNearbyHelpers(alertId, latitude, longitude); } catch (e) {
          if (AppConstants.enableLogging) { print('⚠️ Erreur notification aidants: $e'); }
        }
      });

      // Démarrer le tracking GPS en arrière-plan pour cette alerte
      try {
        GeolocationService.instance.startBackgroundTracking(alertId);
      } catch (_) {}

      // Démarrer l'enregistrement audio en arrière-plan pour cette alerte
      try {
        AudioRecordingService.instance.startBackgroundRecording(alertId);
      } catch (_) {}

      // Démarrer la synchronisation périodique des positions locales
      _locationSyncTimer?.cancel();
      _locationSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        syncLocalLocations();
      });

      if (AppConstants.enableLogging) {
        print('✅ Alerte créée: $alertId');
      }

      return alertId;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur création alerte: $e');
      }
      rethrow;
    }
  }

  /// Met à jour le statut d'une alerte
  Future<void> updateAlertStatus(String alertId, String newStatus) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await SupabaseService.instance.update(
        'alertes',
        {
          'statut': newStatus,
          'date_resolution': newStatus == 'resolue' 
              ? DateTime.now().toUtc().toIso8601String() 
              : null,
        },
        idColumn: 'id',
        idValue: alertId,
      );

      if (AppConstants.enableLogging) {
        print('✅ Statut alerte mis à jour: $alertId -> $newStatus');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur mise à jour alerte: $e');
      }
      rethrow;
    }
  }

  /// Récupère les alertes actives de l'utilisateur
  Future<List<AlertModel>> getActiveAlerts() async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) return [];

      final response = await SupabaseService.instance.select(
        'alertes',
        filters: {
          'utilisateur_id': userId,
          'statut': 'active',
        },
        orderBy: 'timestamp',
        ascending: false,
      );

      if (response == null) return [];

      return (response as List)
          .map((data) => AlertModel.fromJson(data))
          .toList();
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur récupération alertes actives: $e');
      }
      return [];
    }
  }

  /// Récupère l'historique des alertes de l'utilisateur
  Future<List<AlertModel>> getAlertsHistory({int limit = 50}) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) return [];

      final response = await SupabaseService.instance.select(
        'alertes',
        filters: {'utilisateur_id': userId},
        orderBy: 'timestamp',
        ascending: false,
        limit: limit,
      );

      if (response == null) return [];

      return (response as List)
          .map((data) => AlertModel.fromJson(data))
          .toList();
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur récupération historique alertes: $e');
      }
      return [];
    }
  }

  /// Annule une alerte active
  Future<void> cancelAlert(String alertId) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Utiliser la fonction RPC existante pour résoudre l'alerte
      try {
        await SupabaseService.instance.rpc(
          'resoudre_alerte',
          params: {
            'p_alerte_id': alertId,
            'p_utilisateur_id': userId,
          },
        );
      } catch (e) {
        // Fallback: utiliser la méthode classique
        if (AppConstants.enableLogging) {
          print('⚠️ Fonction RPC resoudre_alerte échouée, fallback: $e');
        }
        await updateAlertStatus(alertId, 'cancelled');
      }
      
      // Notifier l'annulation
      await NotificationService.instance.sendCancelNotification(alertId);

      // Arrêter la synchro et faire une dernière tentative de flush
      try {
        _locationSyncTimer?.cancel();
        _locationSyncTimer = null;
        await syncLocalLocations();
      } catch (_) {}
      
      // Arrêter l'enregistrement audio
      try {
        AudioRecordingService.instance.stopBackgroundRecording();
      } catch (_) {}

      if (AppConstants.enableLogging) {
        print('✅ Alerte annulée: $alertId');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur annulation alerte: $e');
      }
      rethrow;
    }
  }

  /// Synchronise les positions locales avec le serveur Supabase
  Future<void> syncLocalLocations() async {
    try {
      final local = await StorageService.instance.getLocalLocations();
      if (local.isEmpty) return;
      
      for (final loc in local) {
        // Ne pas tenter d'insérer sans utilisateur (RLS refusera). Attendre la prochaine sync.
        final userId = AuthService.instance.userId;
        if (userId == null) {
          if (AppConstants.enableLogging) {
            print('⏸️ Sync positions: utilisateur non connecté, reportée');
          }
          continue;
        }

        // Normaliser le timestamp
        final rawTs = loc['timestamp'];
        final ts = rawTs is DateTime
            ? rawTs.toUtc().toIso8601String()
            : (rawTs?.toString());

        try {
          await SupabaseService.instance.upsert('positions_alertes', {
            'id': loc['id'],
            'alerte_id': loc['alert_id'],
            'position_lat': loc['latitude'],
            'position_lng': loc['longitude'],
            'precision_m': loc['accuracy'],
            'timestamp': ts,
            'utilisateur_id': userId,
          }, onConflict: 'id', ignoreDuplicates: true);
          await StorageService.instance.markLocationSynced(loc['id'] as String);
        } catch (e) {
          // Ajouter à la file de synchronisation en cas d'échec
          if (AppConstants.enableLogging) {
            print('❌ Sync position ${loc['id']} échouée, ajout à la file: $e');
          }
          await SyncService.instance.addToSyncQueue('position', {
            'id': loc['id'],
            'alerte_id': loc['alert_id'],
            'position_lat': loc['latitude'],
            'position_lng': loc['longitude'],
            'precision_m': loc['accuracy'],
            'timestamp': ts,
            'utilisateur_id': userId,
          });
        }
      }
      
      if (AppConstants.enableLogging) {
        print('✅ Synchronisation des positions locales terminée');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur sync positions locales: $e');
      }
    }
  }

  /// Notifie les contacts d'urgence
  Future<void> _notifyEmergencyContacts(
    String alertId,
    double latitude,
    double longitude,
  ) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) return;

      // Récupérer les contacts d'urgence depuis le stockage local en priorité
      List<Map<String, dynamic>> contacts = [];
      
      try {
        // Essayer d'abord le stockage local
        final localContacts = await StorageService.instance.getCachedContacts(userId);
        if (localContacts.isNotEmpty) {
          contacts = localContacts;
          if (AppConstants.enableLogging) {
            print('📱 Contacts chargés depuis le stockage local: ${contacts.length}');
          }
        }
      } catch (e) {
        if (AppConstants.enableLogging) {
          print('⚠️ Erreur chargement contacts locaux: $e');
        }
      }
      
      // Si pas de contacts locaux, essayer Supabase
      if (contacts.isEmpty) {
        try {
          final response = await SupabaseService.instance.select(
            'contacts_urgence',
            filters: {
              'utilisateur_id': userId,
              'actif': true,
            },
            orderBy: 'priorite',
          );

          if (response != null) {
            contacts = (response as List).cast<Map<String, dynamic>>();
            if (AppConstants.enableLogging) {
              print('🌐 Contacts chargés depuis Supabase: ${contacts.length}');
            }
          }
        } catch (e) {
          if (AppConstants.enableLogging) {
            print('⚠️ Erreur chargement contacts Supabase: $e');
          }
        }
      }

      if (contacts.isEmpty) return;

      // Utiliser le service dédié qui gère le message personnalisé + position
      // et l'envoi séquentiel vers tous les contacts (évite les doublons).
      final customMessage = StorageService.instance.getString('custom_sos_message') ??
          StorageService.instance.getString('emergency_message_template');

      if (AppConstants.enableLogging) {
        print('📨 Envoi SMS via EmergencyContactService (template personnalisé)');
      }

      await EmergencyContactService.instance.callAllContactsWithFallback(
        customMessage: customMessage,
      );

      if (AppConstants.enableLogging) {
        print('✅ Contacts d\'urgence notifiés');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur notification contacts: $e');
      }
    }
  }

  /// Notifie les aidants à proximité
  Future<void> _notifyNearbyHelpers(
    String alertId,
    double latitude,
    double longitude,
  ) async {
    try {
      // Utiliser la fonction PostgreSQL pour trouver les aidants à proximité
      final response = await SupabaseService.instance.rpc(
        'trouver_aidants_proximite',
        params: {
          'alerte_lat': latitude,
          'alerte_lon': longitude,
          'rayon_metres': 5000, // 5km de rayon
        },
      );

      // Le client peut retourner directement une List ou un objet Map avec clé 'data'
      List<dynamic> helpers = const [];
      if (response is List) {
        helpers = response;
      } else if (response is Map && response['data'] is List) {
        helpers = response['data'] as List;
      }

      for (final helper in helpers.take(10)) {
        await NotificationService.instance.sendHelperNotification(
          helperId: helper['aidant_id'],
          alertId: alertId,
          distance: helper['distance_metres'],
        );
      }

      if (AppConstants.enableLogging) {
        print('✅ Aidants à proximité notifiés');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur notification aidants: $e');
      }
    }
  }

  /// Sauvegarde une alerte localement pour l'accès hors ligne
  Future<void> _saveAlertLocally(Map<String, dynamic> alertData) async {
    try {
      await StorageService.instance.saveAlert(alertData);
      
      if (AppConstants.enableLogging) {
        print('✅ Alerte sauvegardée localement');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur sauvegarde locale: $e');
      }
    }
  }

  /// Synchronise les alertes locales avec le serveur
  Future<void> syncLocalAlerts() async {
    try {
      final localAlerts = await StorageService.instance.getLocalAlerts();
      
      for (final alert in localAlerts) {
        try {
          await SupabaseService.instance.insert('alertes', alert);
          await StorageService.instance.removeLocalAlert(alert['id']);
        } catch (e) {
          // Continuer avec les autres alertes si une échoue
          if (AppConstants.enableLogging) {
            print('❌ Erreur sync alerte ${alert['id']}: $e');
          }
        }
      }

      if (AppConstants.enableLogging) {
        print('✅ Synchronisation alertes locales terminée');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur synchronisation alertes: $e');
      }
    }
  }

  /// Annule une alerte d'urgence
  Future<void> cancelEmergencyAlert(String alertId) async {
    try {
      if (AppConstants.enableLogging) {
        print('🔄 Annulation de l\'alerte: $alertId');
      }

      // Marquer l'alerte comme annulée dans la base de données
      try {
        await SupabaseService.instance.update(
          'alertes',
          {'statut': 'annulee'},
          idColumn: 'id',
          idValue: alertId,
        );
      } catch (e) {
        // Ajouter à la file de synchronisation si le réseau/Supabase échoue
        if (AppConstants.enableLogging) {
          print('⚠️ UPDATE Supabase échoué, ajout à la file de sync: $e');
        }
        await SyncService.instance.addToSyncQueue('alerte_annulation', {
          'id': alertId,
          'statut': 'annulee',
          'timestamp_annulation': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // Arrêter le tracking GPS pour cette alerte
      try {
        GeolocationService.instance.stopBackgroundTracking();
      } catch (_) {}

      // Arrêter l'enregistrement audio pour cette alerte
      try {
        AudioRecordingService.instance.stopBackgroundRecording();
      } catch (_) {}

      // Supprimer l'ID d'alerte courant du stockage local
      try {
        await StorageService.instance.remove(AppConstants.keyCurrentAlertId);
      } catch (_) {}

      // Marquer l'alerte comme annulée localement
      try {
        await StorageService.instance.removeLocalAlert(alertId);
      } catch (_) {}

      if (AppConstants.enableLogging) {
        print('✅ Alerte annulée: $alertId');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur lors de l\'annulation de l\'alerte: $e');
      }
      rethrow;
    }
  }

  /// Récupère l'historique des alertes
  Future<List<Map<String, dynamic>>> getAlertHistory() async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await SupabaseService.instance.select(
        'alertes',
        filters: {'utilisateur_id': userId},
        // Certaines bases utilisent 'timestamp' pour l'horodatage
        orderBy: 'timestamp',
        ascending: false,
      );

      // Normaliser les clés attendues par l'UI
      final List<Map<String, dynamic>> items = [];
      for (final row in response) {
        final map = Map<String, dynamic>.from(row);
        items.add({
          'id': map['id'],
          // UI accepte 'status' ou 'statut' → on fournit 'status'
          'status': map['statut'] ?? map['status'] ?? 'active',
          // UI regarde 'timestamp' ou 'time' → on fournit 'timestamp' depuis 'date_creation'
          'timestamp': map['date_creation'] ?? map['timestamp'] ?? map['time'],
          'latitude': map['latitude'],
          'longitude': map['longitude'],
          'type_alerte': map['type_alerte'],
          'niveau_danger': map['niveau_danger'],
          'description': map['description'],
        });
      }

      return items;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  /// Récupère l'alerte actuelle
  Future<Map<String, dynamic>?> getCurrentAlert() async {
    try {
      final alertId = StorageService.instance.getString(AppConstants.keyCurrentAlertId);
      if (alertId == null) return null;

      // Try server first
      try {
        final response = await SupabaseService.instance.select(
          'alertes',
          filters: {'id': alertId},
          limit: 1,
        );
        if (response.isNotEmpty) {
          return Map<String, dynamic>.from(response.first);
        }
      } catch (_) {}

      // Fallback to local cache (offline or not yet synced)
      try {
        final localAlerts = await StorageService.instance.getLocalAlerts();
        for (final a in localAlerts) {
          if (a['id'] == alertId) {
            return a;
          }
        }
      } catch (_) {}

      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'alerte actuelle: $e');
      return null;
    }
  }

  /// Vide l'historique des alertes
  Future<void> clearAlertHistory() async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await SupabaseService.instance.delete(
        'alertes',
        idColumn: 'utilisateur_id',
        idValue: userId,
      );
    } catch (e) {
      print('❌ Erreur lors du vidage de l\'historique: $e');
      rethrow;
    }
  }

  /// Génère un rapport d'alerte
  Future<Map<String, dynamic>> generateAlertReport(String alertId) async {
    try {
      final response = await SupabaseService.instance.select(
        'alertes',
        filters: {'id': alertId},
        limit: 1,
      );

      if (response.isEmpty) {
        throw Exception('Alerte non trouvée');
      }

      final alert = response.first;
      return {
        'id': alert['id'],
        'date': alert['date_creation'],
        'statut': alert['statut'],
        'position': '${alert['latitude']}, ${alert['longitude']}',
        'type': alert['type_alerte'],
        'niveau_danger': alert['niveau_danger'],
        'description': alert['description'],
      };
    } catch (e) {
      print('❌ Erreur lors de la génération du rapport: $e');
      rethrow;
    }
  }

  /// Écoute les changements d'alertes en temps réel
  Stream<Map<String, dynamic>> listenToAlerts() {
    final userId = AuthService.instance.userId;
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    _realtimeService.listenToAlerts(userId);
    return _realtimeService.alertStream;
  }

  /// Écoute les changements de positions en temps réel
  Stream<Map<String, dynamic>> listenToPositions() {
    final userId = AuthService.instance.userId;
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    _realtimeService.listenToPositions(userId);
    return _realtimeService.positionStream;
  }

  /// Écoute les notifications en temps réel
  Stream<Map<String, dynamic>> listenToNotifications() {
    final userId = AuthService.instance.userId;
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    _realtimeService.listenToNotifications(userId);
    return _realtimeService.notificationStream;
  }

  /// Envoie une notification temps réel
  Future<void> sendRealtimeNotification({
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    final userId = AuthService.instance.userId;
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    await _realtimeService.sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      data: data,
    );
  }

  /// Enregistre une position GPS en temps réel
  Future<void> recordPosition({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) async {
    final userId = AuthService.instance.userId;
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    await _realtimeService.recordPosition(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      speed: speed,
      heading: heading,
    );
  }

  /// Arrête l'écoute temps réel
  Future<void> stopRealtimeListening() async {
    await _realtimeService.stopListening();
  }

  /// Nettoie les ressources
  void dispose() {
    if (AppConstants.enableLogging) {
      print('✅ AlertService nettoyé');
    }
  }
}

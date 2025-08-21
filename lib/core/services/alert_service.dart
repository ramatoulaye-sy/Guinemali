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
import 'dart:async';

/// Service de gestion des alertes d'urgence
class AlertService {
  static AlertService? _instance;
  static AlertService get instance => _instance ??= AlertService._();
  
  AlertService._();

  final _uuid = const Uuid();
  Timer? _locationSyncTimer;

  /// Crée une nouvelle alerte d'urgence
  Future<String> createEmergencyAlert({
    required double latitude,
    required double longitude,
    String type = 'urgence',
    int dangerLevel = 5,
    String? description,
  }) async {
    try {
      final userId = AuthService.instance.userId;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (AppConstants.enableLogging) {
        print('🚨 Création d\'alerte pour utilisateur: $userId');
      }

      final alertId = _uuid.v4();
      
      // Créer l'alerte dans la base de données
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

      try {
        await SupabaseService.instance.insert('alertes', alertData);
      } catch (e) {
        // Ajouter à la file de synchronisation si le réseau/Supabase échoue
        if (AppConstants.enableLogging) {
          print('⚠️ INSERT Supabase échoué, ajout à la file de sync: $e');
        }
        await SyncService.instance.addToSyncQueue('alerte', alertData);
      }

      // Stocker l'ID d'alerte courant pour accès rapide par l'UI
      try {
        await StorageService.instance.saveString(AppConstants.keyCurrentAlertId, alertId);
      } catch (_) {}

      // Notifier les contacts d'urgence et les aidants
      // Ces appels ne doivent pas bloquer la création de l'alerte
      try {
        await _notifyEmergencyContacts(alertId, latitude, longitude);
      } catch (_) {}
      try {
        await _notifyNearbyHelpers(alertId, latitude, longitude);
      } catch (_) {}

      // Toujours marquer localement pour lecture immédiate côté app
      await _saveAlertLocally(alertData);

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
      // Utiliser un statut valide selon la contrainte (active, resolue, fausse_alerte, en_cours)
      await updateAlertStatus(alertId, 'fausse_alerte');
      
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
        try {
          await SupabaseService.instance.insert('positions_alertes', {
            'id': loc['id'],
            'alerte_id': loc['alert_id'],
            'latitude': loc['latitude'],
            'longitude': loc['longitude'],
            'accuracy': loc['accuracy'],
            'timestamp': loc['timestamp'],
          });
          await StorageService.instance.markLocationSynced(loc['id'] as String);
        } catch (e) {
          // Ajouter à la file de synchronisation en cas d'échec
          if (AppConstants.enableLogging) {
            print('❌ Sync position ${loc['id']} échouée, ajout à la file: $e');
          }
          await SyncService.instance.addToSyncQueue('position', {
            'id': loc['id'],
            'alerte_id': loc['alert_id'],
            'latitude': loc['latitude'],
            'longitude': loc['longitude'],
            'accuracy': loc['accuracy'],
            'timestamp': loc['timestamp'],
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

      // Récupérer les contacts d'urgence
      final response = await SupabaseService.instance.select(
        'contacts_urgence',
        filters: {
          'utilisateur_id': userId,
          'actif': true,
        },
        orderBy: 'priorite',
      );

      if (response == null) return;

      final contacts = response as List;
      
      for (final contact in contacts) {
        await NotificationService.instance.sendEmergencySMS(
          phoneNumber: contact['numero_telephone'],
          alertId: alertId,
          latitude: latitude,
          longitude: longitude,
        );
      }

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

      if (response.data != null) {
        final helpers = response.data as List;
        
        for (final helper in helpers.take(10)) { // Limiter à 10 aidants
          await NotificationService.instance.sendHelperNotification(
            helperId: helper['aidant_id'],
            alertId: alertId,
            distance: helper['distance_metres'],
          );
        }
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

  /// Nettoie les ressources
  void dispose() {
    if (AppConstants.enableLogging) {
      print('✅ AlertService nettoyé');
    }
  }
}

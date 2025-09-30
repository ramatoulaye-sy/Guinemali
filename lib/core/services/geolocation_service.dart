import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'sync_service.dart';
import 'supabase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// Service de géolocalisation pour obtenir la position de l'utilisateur
class GeolocationService {
  static GeolocationService? _instance;
  static GeolocationService get instance => _instance ??= GeolocationService._();
  
  GeolocationService._();
  final _uuid = const Uuid();
  // StreamSubscription<Position>? _trackingSubscription;
  // Notifier: indique si un suivi (stream) est actif
  final ValueNotifier<bool> isTracking = ValueNotifier(false);

  /// Vérifie et demande les permissions de localisation
  Future<bool> checkPermissions() async {
    try {
      // Vérifier le statut du service de localisation
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (AppConstants.enableLogging) {
          print('❌ Service de localisation désactivé');
        }
        // Ne pas jeter d'exception: on laissera l'appelant gérer le fallback
        return false;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (AppConstants.enableLogging) {
            print('❌ Permission de localisation refusée');
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Guider l'utilisateur vers les réglages (non supporté sur Web)
        if (!kIsWeb) {
          await Geolocator.openAppSettings();
          await Geolocator.openLocationSettings();
        }
        return false;
      }

      // Sur Web, on s'arrête ici (pas de demande via permission_handler)
      if (kIsWeb) {
        if (AppConstants.enableLogging) {
          print('ℹ️ Web: permissions de localisation en avant-plan OK');
        }
        return true;
      }

      // Demander la permission de localisation en arrière-plan (non supporté sur web)
      if (!kIsWeb) {
        try {
          final backgroundPermission = await Permission.locationAlways.request();
          if (backgroundPermission != PermissionStatus.granted) {
            if (AppConstants.enableLogging) {
              print('⚠️ Permission de localisation en arrière-plan non accordée');
            }
          }
        } catch (e) {
          if (AppConstants.enableLogging) {
            print('⚠️ LocationAlways non disponible sur cette plateforme: $e');
          }
        }
      } else {
        if (AppConstants.enableLogging) {
          print('ℹ️ LocationAlways ignorée sur Web');
        }
      }

      if (AppConstants.enableLogging) {
        print('✅ Permissions de localisation accordées');
      }

      return true;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur permissions de localisation: $e');
      }
      return false;
    }
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<Position> getCurrentPosition() async {
    try {
      // Vérifier les permissions d'abord
      final ok = await checkPermissions();
      if (!ok) {
        // Essayer une position connue si possible
        final last = await getLastKnownPosition();
        if (last != null) return last;
        throw Exception('Service de localisation désactivé');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (AppConstants.enableLogging) {
        print('✅ Position obtenue: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur obtention position: $e');
      }
      rethrow;
    }
  }

  /// Obtient la dernière position connue (plus rapide mais potentiellement obsolète)
  Future<Position?> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      
      if (position != null && AppConstants.enableLogging) {
        print('✅ Dernière position connue: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur dernière position: $e');
      }
      return null;
    }
  }

  /// Surveille les changements de position en temps réel
  Stream<Position> watchPosition({LocationAccuracy accuracy = LocationAccuracy.high, int distanceFilter = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter, // Mise à jour selon filtre
      ),
    );
  }

  /// Démarre l'enregistrement de positions locales associées à une alerte
  Stream<Position> startBackgroundTracking(String alertId) {
    final stream = watchPosition(accuracy: LocationAccuracy.high, distanceFilter: 15);
    
    // Écouter le stream pour sauvegarder les positions
    stream.listen((pos) async {
      try {
        final locationId = _uuid.v4();
        await StorageService.instance.saveLocation(
          id: locationId,
          alertId: alertId,
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          timestamp: pos.timestamp,
        );
        
        // Tenter de synchroniser immédiatement
        try {
          await SupabaseService.instance.upsert('positions_alertes', {
            'id': locationId,
            'alerte_id': alertId,
            'position_lat': pos.latitude,
            'position_lng': pos.longitude,
            'precision_m': pos.accuracy,
            'timestamp': pos.timestamp.toUtc().toIso8601String(),
          }, onConflict: 'id', ignoreDuplicates: true);
          await StorageService.instance.markLocationSynced(locationId);
          if (AppConstants.enableLogging) {
            print('📍 Position synchronisée: ${pos.latitude}, ${pos.longitude}');
          }
        } catch (e) {
          // En cas d'échec, ajouter à la file de synchronisation
          if (AppConstants.enableLogging) {
            print('⚠️ Sync position échouée, ajout à la file: $e');
          }
          await SyncService.instance.addToSyncQueue('position', {
            'id': locationId,
            'alerte_id': alertId,
            'position_lat': pos.latitude,
            'position_lng': pos.longitude,
            'precision_m': pos.accuracy,
            'timestamp': pos.timestamp.toUtc().toIso8601String(),
          });
        }
        
        if (AppConstants.enableLogging) {
          print('📍 Position sauvegardée localement: ${pos.latitude}, ${pos.longitude}');
        }
      } catch (e) {
        if (AppConstants.enableLogging) {
          print('❌ Erreur sauvegarde position: $e');
        }
      }
    });
    
    isTracking.value = true;
    return stream;
  }

  /// Arrête le tracking en arrière-plan
  Future<void> stopBackgroundTracking() async {
    // await _trackingSubscription?.cancel();
    // _trackingSubscription = null;
    isTracking.value = false;
    if (AppConstants.enableLogging) {
      print('🛑 Tracking GPS arrêté');
    }
  }

  /// Calcule la distance entre deux points géographiques
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Vérifie si l'utilisateur est dans un rayon donné d'un point
  bool isWithinRadius(
    double userLat,
    double userLon,
    double centerLat,
    double centerLon,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(userLat, userLon, centerLat, centerLon);
    return distance <= radiusInMeters;
  }

  /// Formate une position en chaîne de caractères
  String formatPosition(Position position, {int precision = 6}) {
    return '${position.latitude.toStringAsFixed(precision)}, ${position.longitude.toStringAsFixed(precision)}';
  }

  /// Obtient l'adresse approximative à partir des coordonnées (nécessite un service de géocodage)
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    // TODO: Implémenter avec un service de géocodage gratuit
    // Pour l'instant, retourner les coordonnées
    return 'Lat: ${latitude.toStringAsFixed(4)}, Lon: ${longitude.toStringAsFixed(4)}';
  }

  /// Ouvre la position dans l'application de cartes par défaut
  Future<void> openInMaps(double latitude, double longitude) async {
    // TODO: Implémenter l'ouverture dans Google Maps ou OpenStreetMap
    if (AppConstants.enableLogging) {
      print('📍 Ouverture des cartes pour: $latitude, $longitude');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    if (AppConstants.enableLogging) {
      print('✅ GeolocationService nettoyé');
    }
  }
}

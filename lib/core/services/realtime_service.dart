import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'log_service.dart';

/// Service pour gérer les notifications temps réel via Supabase Realtime
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final SupabaseService _supabase = SupabaseService.instance;
  final LogService _log = LogService.instance;

  // Streams pour les différents types d'événements
  final StreamController<Map<String, dynamic>> _alertController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _positionController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController = StreamController.broadcast();

  // Channels actifs
  RealtimeChannel? _alertChannel;
  RealtimeChannel? _positionChannel;
  RealtimeChannel? _notificationChannel;

  // État de connexion
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Streams publics
  Stream<Map<String, dynamic>> get alertStream => _alertController.stream;
  Stream<Map<String, dynamic>> get positionStream => _positionController.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  /// Initialise le service Realtime
  Future<void> initialize() async {
    try {
      _log.info('🔄 Initialisation du service Realtime...');
      
      // Vérifier la connexion Supabase
      if (!_supabase.isConnected) {
        throw Exception('Supabase non connecté');
      }

      _isConnected = true;
      _log.success('✅ Service Realtime initialisé');
    } catch (e) {
      _log.error('❌ Erreur initialisation Realtime: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Écoute les alertes en temps réel
  Future<void> listenToAlerts(String userId) async {
    try {
      _log.info('🔔 Écoute des alertes pour utilisateur: $userId');

      // Fermer le channel existant s'il existe
      await _alertChannel?.unsubscribe();

      // Créer un nouveau channel pour les alertes
      _alertChannel = _supabase.client
          .channel('alerts_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'alertes',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'utilisateur_id',
              value: userId,
            ),
            callback: _handleAlertChange,
          );

      await _alertChannel?.subscribe();
      _log.success('✅ Écoute des alertes activée');
    } catch (e) {
      _log.error('❌ Erreur écoute alertes: $e');
      rethrow;
    }
  }

  /// Écoute les positions GPS en temps réel
  Future<void> listenToPositions(String userId) async {
    try {
      _log.info('📍 Écoute des positions pour utilisateur: $userId');

      // Fermer le channel existant s'il existe
      await _positionChannel?.unsubscribe();

      // Créer un nouveau channel pour les positions
      _positionChannel = _supabase.client
          .channel('positions_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'positions_gps',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'utilisateur_id',
              value: userId,
            ),
            callback: _handlePositionChange,
          );

      await _positionChannel?.subscribe();
      _log.success('✅ Écoute des positions activée');
    } catch (e) {
      _log.error('❌ Erreur écoute positions: $e');
      rethrow;
    }
  }

  /// Écoute les notifications générales
  Future<void> listenToNotifications(String userId) async {
    try {
      _log.info('🔔 Écoute des notifications pour utilisateur: $userId');

      // Fermer le channel existant s'il existe
      await _notificationChannel?.unsubscribe();

      // Créer un nouveau channel pour les notifications
      _notificationChannel = _supabase.client
          .channel('notifications_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'utilisateur_id',
              value: userId,
            ),
            callback: _handleNotificationChange,
          );

      await _notificationChannel?.subscribe();
      _log.success('✅ Écoute des notifications activée');
    } catch (e) {
      _log.error('❌ Erreur écoute notifications: $e');
      rethrow;
    }
  }

  /// Gère les changements d'alertes
  void _handleAlertChange(PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      final eventData = {
        'type': 'alert',
        'event': eventType.toString(),
        'data': newRecord ?? oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _log.info('🚨 Changement alerte: $eventType');
      _alertController.add(eventData);
    } catch (e) {
      _log.error('❌ Erreur traitement alerte: $e');
    }
  }

  /// Gère les changements de positions
  void _handlePositionChange(PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      final eventData = {
        'type': 'position',
        'event': eventType.toString(),
        'data': newRecord ?? oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _log.info('📍 Changement position: $eventType');
      _positionController.add(eventData);
    } catch (e) {
      _log.error('❌ Erreur traitement position: $e');
    }
  }

  /// Gère les changements de notifications
  void _handleNotificationChange(PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      final eventData = {
        'type': 'notification',
        'event': eventType.toString(),
        'data': newRecord ?? oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _log.info('🔔 Changement notification: $eventType');
      _notificationController.add(eventData);
    } catch (e) {
      _log.error('❌ Erreur traitement notification: $e');
    }
  }

  /// Envoie une notification en temps réel
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      _log.info('📤 Envoi notification: $title');

      final notificationData = {
        'utilisateur_id': userId,
        'titre': title,
        'message': message,
        'type': type ?? 'info',
        'data': data ?? {},
        'lu': false,
        'date_creation': DateTime.now().toIso8601String(),
      };

      await _supabase.insert('notifications', notificationData);
      _log.success('✅ Notification envoyée');
    } catch (e) {
      _log.error('❌ Erreur envoi notification: $e');
      rethrow;
    }
  }

  /// Enregistre une position GPS
  Future<void> recordPosition({
    required String userId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) async {
    try {
      _log.info('📍 Enregistrement position: $latitude, $longitude');

      final positionData = {
        'utilisateur_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'precision': accuracy,
        'altitude': altitude,
        'vitesse': speed,
        'direction': heading,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _supabase.insert('positions_gps', positionData);
      _log.success('✅ Position enregistrée');
    } catch (e) {
      _log.error('❌ Erreur enregistrement position: $e');
      rethrow;
    }
  }

  /// Arrête l'écoute de tous les channels
  Future<void> stopListening() async {
    try {
      _log.info('🛑 Arrêt de l\'écoute Realtime...');

      await _alertChannel?.unsubscribe();
      await _positionChannel?.unsubscribe();
      await _notificationChannel?.unsubscribe();

      _alertChannel = null;
      _positionChannel = null;
      _notificationChannel = null;

      _isConnected = false;
      _log.success('✅ Écoute Realtime arrêtée');
    } catch (e) {
      _log.error('❌ Erreur arrêt écoute: $e');
    }
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    try {
      await stopListening();
      await _alertController.close();
      await _positionController.close();
      await _notificationController.close();
      _log.info('🧹 Service Realtime nettoyé');
    } catch (e) {
      _log.error('❌ Erreur nettoyage Realtime: $e');
    }
  }
}
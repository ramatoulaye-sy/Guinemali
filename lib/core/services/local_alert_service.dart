import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/log_service.dart';

/// Service d'alerte local qui ne dépend pas de Supabase
/// Gère les alertes d'urgence avec stockage local et fonctionnalités de base
class LocalAlertService {
  static final LocalAlertService _instance = LocalAlertService._internal();
  factory LocalAlertService() => _instance;
  LocalAlertService._internal();

  static LocalAlertService get instance => _instance;

  final StorageService _storage = StorageService.instance;
  final Uuid _uuid = const Uuid();

  /// Crée une alerte d'urgence locale
  Future<String> createEmergencyAlert({
    required double latitude,
    required double longitude,
    required String type,
    required int dangerLevel,
    required String description,
  }) async {
    try {
      final alertId = _uuid.v4();
      final timestamp = DateTime.now().toIso8601String();
      
      final alert = {
        'id': alertId,
        'type': type,
        'dangerLevel': dangerLevel,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        'status': 'active',
        'isLocal': true,
      };

      // Sauvegarder l'alerte localement
      await _storage.saveString('current_alert', jsonEncode(alert));
      await _storage.saveString('alert_$alertId', jsonEncode(alert));
      
      // Ajouter à l'historique
      await _addToHistory(alert);
      
      LogService.success('Alerte d\'urgence créée localement: $alertId', tag: 'alert');
      return alertId;
    } catch (e) {
      LogService.error('Erreur lors de la création de l\'alerte: $e', tag: 'alert');
      rethrow;
    }
  }

  /// Récupère l'alerte active actuelle
  Future<Map<String, dynamic>?> getCurrentAlert() async {
    try {
      final alertData = _storage.getString('current_alert');
      if (alertData != null && alertData.isNotEmpty) {
        return jsonDecode(alertData) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      LogService.error('Erreur lors de la récupération de l\'alerte: $e', tag: 'alert');
      return null;
    }
  }

  /// Annule l'alerte active
  Future<void> cancelAlert(String alertId) async {
    try {
      final alertData = _storage.getString('current_alert');
      if (alertData != null) {
        final alert = jsonDecode(alertData) as Map<String, dynamic>;
        alert['status'] = 'cancelled';
        alert['cancelledAt'] = DateTime.now().toIso8601String();
        
        await _storage.saveString('current_alert', jsonEncode(alert));
        await _storage.saveString('alert_$alertId', jsonEncode(alert));
        
        LogService.success('Alerte annulée: $alertId', tag: 'alert');
      }
    } catch (e) {
      LogService.error('Erreur lors de l\'annulation de l\'alerte: $e', tag: 'alert');
    }
  }

  /// Récupère l'historique des alertes
  Future<List<Map<String, dynamic>>> getAlertHistory() async {
    try {
      final historyData = _storage.getString('alert_history');
      if (historyData != null && historyData.isNotEmpty) {
        final List<dynamic> history = jsonDecode(historyData);
        return history.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      LogService.error('Erreur lors de la récupération de l\'historique: $e', tag: 'alert');
      return [];
    }
  }

  /// Ajoute une alerte à l'historique
  Future<void> _addToHistory(Map<String, dynamic> alert) async {
    try {
      final history = await getAlertHistory();
      history.insert(0, alert); // Ajouter au début
      
      // Limiter à 50 alertes maximum
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }
      
      await _storage.saveString('alert_history', jsonEncode(history));
    } catch (e) {
      LogService.error('Erreur lors de l\'ajout à l\'historique: $e', tag: 'alert');
    }
  }

  /// Vérifie si une alerte est active
  Future<bool> hasActiveAlert() async {
    final alert = await getCurrentAlert();
    return alert != null && alert['status'] == 'active';
  }

  /// Met à jour le statut d'une alerte
  Future<void> updateAlertStatus(String alertId, String status) async {
    try {
      final alertData = _storage.getString('alert_$alertId');
      if (alertData != null) {
        final alert = jsonDecode(alertData) as Map<String, dynamic>;
        alert['status'] = status;
        alert['updatedAt'] = DateTime.now().toIso8601String();
        
        await _storage.saveString('alert_$alertId', jsonEncode(alert));
        
        // Mettre à jour l'alerte courante si c'est la même
        final currentAlert = await getCurrentAlert();
        if (currentAlert != null && currentAlert['id'] == alertId) {
          await _storage.saveString('current_alert', jsonEncode(alert));
        }
        
        LogService.success('Statut de l\'alerte mis à jour: $alertId -> $status', tag: 'alert');
      }
    } catch (e) {
      LogService.error('Erreur lors de la mise à jour du statut: $e', tag: 'alert');
    }
  }

  /// Supprime l'historique des alertes
  Future<void> clearAlertHistory() async {
    try {
      await _storage.remove('alert_history');
      LogService.success('Historique des alertes supprimé', tag: 'alert');
    } catch (e) {
      LogService.error('Erreur lors de la suppression de l\'historique: $e', tag: 'alert');
    }
  }

  /// Génère un rapport d'alerte pour partage
  Future<Map<String, dynamic>> generateAlertReport(String alertId) async {
    try {
      final alertData = _storage.getString('alert_$alertId');
      if (alertData != null) {
        final alert = jsonDecode(alertData) as Map<String, dynamic>;
        
        return {
          'id': alert['id'],
          'type': alert['type'],
          'dangerLevel': alert['dangerLevel'],
          'description': alert['description'],
          'location': '${alert['latitude']}, ${alert['longitude']}',
          'timestamp': alert['timestamp'],
          'status': alert['status'],
          'googleMapsUrl': 'https://www.google.com/maps?q=${alert['latitude']},${alert['longitude']}',
        };
      }
      return {};
    } catch (e) {
      LogService.error('Erreur lors de la génération du rapport: $e', tag: 'alert');
      return {};
    }
  }
}

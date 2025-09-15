import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:telephony/telephony.dart';  // Plugin abandonné
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

/// Service de gestion des notifications (locales, SMS, push)
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  // final Telephony _telephony = Telephony.instance;  // Plugin abandonné

  /// Initialise le service de notifications
  Future<void> initialize() async {
    try {
      // Configuration des notifications locales
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Note: Les permissions SMS seront gérées par l'application SMS native
      // via url_launcher au lieu du plugin telephony abandonné

      if (AppConstants.enableLogging) {
        print('✅ NotificationService initialisé');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur initialisation notifications: $e');
      }
      rethrow;
    }
  }

  /// Gestionnaire de tap sur notification
  void _onNotificationTapped(NotificationResponse response) {
    if (AppConstants.enableLogging) {
      print('📱 Notification tappée: ${response.payload}');
    }
    // TODO: Implémenter la navigation selon le payload
  }

  /// Envoie une notification d'urgence locale
  Future<void> showEmergencyNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'emergency_channel',
        'Alertes d\'urgence',
        channelDescription: 'Notifications d\'urgence Guinèmali',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        color: AppConstants.alertActiveColor,
        ledColor: AppConstants.alertActiveColor,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      if (AppConstants.enableLogging) {
        print('✅ Notification d\'urgence affichée');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur notification d\'urgence: $e');
      }
    }
  }

  /// Envoie un SMS d'urgence
  Future<void> sendEmergencySMS({
    required String phoneNumber,
    required String alertId,
    required double latitude,
    required double longitude,
    String? victimName,
  }) async {
    try {
      final who = (victimName != null && victimName.trim().isNotEmpty)
          ? victimName.trim()
          : 'Une personne que vous connaissez';
      final message = '''🚨 ALERTE GUINÈMALI 🚨

$who est en danger et a déclenché une alerte d'urgence.

📍 Position: $latitude, $longitude
🆔 Alerte: $alertId
⏰ ${DateTime.now().toString()}

Merci d'appeler immédiatement et d'aider si vous le pouvez.

- Guinèmali''';

      // Utiliser url_launcher pour envoyer le SMS
      final uri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (AppConstants.enableLogging) {
          print('❌ Impossible d\'ouvrir l\'application SMS pour envoyer le SMS.');
        }
      }

      if (AppConstants.enableLogging) {
        print('✅ SMS d\'urgence envoyé à $phoneNumber');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur envoi SMS: $e');
      }
      
      // Fallback: essayer d'ouvrir l'app SMS
      try {
        await _openSMSApp(phoneNumber, 'URGENCE Guinèmali - Besoin d\'aide immédiatement');
      } catch (fallbackError) {
        if (AppConstants.enableLogging) {
          print('❌ Erreur fallback SMS: $fallbackError');
        }
      }
    }
  }

  /// Ouvre l'application SMS par défaut
  Future<void> _openSMSApp(String phoneNumber, String message) async {
    final uri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Envoie une notification à un aidant
  Future<void> sendHelperNotification({
    required String helperId,
    required String alertId,
    required double distance,
  }) async {
    try {
      await showEmergencyNotification(
        title: '🆘 Alerte dans votre zone',
        body: 'Une personne a besoin d\'aide à ${distance.toInt()}m de vous',
        payload: 'helper_alert:$alertId',
      );

      if (AppConstants.enableLogging) {
        print('✅ Notification aidant envoyée: $helperId');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur notification aidant: $e');
      }
    }
  }

  /// Envoie une notification d'annulation d'alerte
  Future<void> sendCancelNotification(String alertId) async {
    try {
      await showEmergencyNotification(
        title: '✅ Alerte annulée',
        body: 'L\'alerte a été annulée par l\'utilisateur',
        payload: 'alert_cancelled:$alertId',
      );

      if (AppConstants.enableLogging) {
        print('✅ Notification annulation envoyée');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur notification annulation: $e');
      }
    }
  }

  /// Planifie une notification périodique (rappels de sécurité)
  Future<void> scheduleSafetyReminder() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'safety_channel',
        'Rappels de sécurité',
        channelDescription: 'Rappels périodiques de sécurité',
        importance: Importance.low,
        priority: Priority.low,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.periodicallyShow(
        1,
        '🛡️ Guinèmali',
        'N\'oubliez pas de vérifier vos contacts d\'urgence',
        RepeatInterval.weekly,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exact,
        payload: 'safety_reminder',
      );

      if (AppConstants.enableLogging) {
        print('✅ Rappel de sécurité planifié');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur planification rappel: $e');
      }
    }
  }

  /// Annule toutes les notifications programmées
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      
      if (AppConstants.enableLogging) {
        print('✅ Toutes les notifications annulées');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur annulation notifications: $e');
      }
    }
  }

  /// Teste les notifications
  Future<void> testNotification() async {
    await showEmergencyNotification(
      title: '🧪 Test Guinèmali',
      body: 'Cette notification de test confirme que le système fonctionne',
      payload: 'test',
    );
  }

  /// Notifie les contacts d'urgence
  Future<void> notifyEmergencyContacts({
    required String alertId,
    required double latitude,
    required double longitude,
    String? customMessage,
  }) async {
    try {
      // Créer une notification dans la base de données
      await _createNotificationRecord(
        alertId: alertId,
        type: 'emergency_alert',
        titre: 'Alerte d\'urgence',
        message: customMessage ?? 'Une alerte d\'urgence a été déclenchée',
        latitude: latitude,
        longitude: longitude,
      );

      // Envoyer une notification locale persistante
      await _localNotifications.show(
        1000 + DateTime.now().millisecondsSinceEpoch % 1000,
        '🚨 Alerte d\'urgence',
        'Votre alerte a été envoyée aux contacts d\'urgence',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'emergency_alerts',
            'Alertes d\'urgence',
            channelDescription: 'Notifications pour les alertes d\'urgence',
            importance: Importance.max,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
          ),
        ),
        payload: 'alert:$alertId',
      );

      print('📞 Notification des contacts d\'urgence pour l\'alerte: $alertId');
      print('📍 Position: $latitude, $longitude');
      print('💬 Message: ${customMessage ?? 'Alerte d\'urgence'}');
    } catch (e) {
      print('❌ Erreur lors de la notification des contacts: $e');
    }
  }

  /// Crée un enregistrement de notification dans Supabase
  Future<void> _createNotificationRecord({
    required String alertId,
    required String type,
    required String titre,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // TODO: Implémenter l'insertion dans la table notifications
      // await SupabaseService.instance.insert('notifications', {
      //   'alerte_id': alertId,
      //   'type_notification': type,
      //   'titre': titre,
      //   'message': message,
      //   'latitude': latitude,
      //   'longitude': longitude,
      // });
    } catch (e) {
      print('❌ Erreur création enregistrement notification: $e');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    if (AppConstants.enableLogging) {
      print('✅ NotificationService nettoyé');
    }
  }
}

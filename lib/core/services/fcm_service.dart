import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:guinemali/core/constants/app_constants.dart';
import 'package:guinemali/core/services/supabase_service.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/firebase_options.dart';
import 'dart:convert';

/// Service de gestion des notifications push Firebase Cloud Messaging
class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._();
  
  FCMService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialise le service FCM
  Future<void> initialize() async {
    try {
      if (AppConstants.enableLogging) {
        print('🔔 Initialisation du service FCM...');
      }

      // Initialiser Firebase si pas déjà fait
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        if (AppConstants.enableLogging) {
          print('✅ Firebase initialisé par FCMService');
        }
      } else {
        if (AppConstants.enableLogging) {
          print('ℹ️ Firebase déjà initialisé');
        }
      }

      // Configurer le handler de messages en arrière-plan
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Demander la permission pour les notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true, // Pour les alertes d'urgence
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (AppConstants.enableLogging) {
          print('✅ Permission notifications accordée');
        }
      } else {
        if (AppConstants.enableLogging) {
          print('⚠️ Permission notifications refusée');
        }
        return;
      }

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Récupérer le token FCM
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        if (AppConstants.enableLogging) {
          print('✅ Token FCM: ${_fcmToken!.substring(0, 20)}...');
        }
        await _saveTokenToSupabase(_fcmToken!);
      }

      // Écouter les changements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToSupabase(newToken);
      });

      // Configurer les handlers de messages
      _setupMessageHandlers();

      if (AppConstants.enableLogging) {
        print('✅ Service FCM initialisé avec succès');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur initialisation FCM: $e');
      }
    }
  }

  /// Initialise les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer un canal de notification pour les alertes d'urgence
    const androidChannel = AndroidNotificationChannel(
      'emergency_alerts',
      'Alertes d\'urgence',
      description: 'Notifications pour les alertes SOS à proximité',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('emergency_alert'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Configure les handlers pour les différents états de l'app
  void _setupMessageHandlers() {
    // Message reçu quand l'app est en premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message reçu quand l'app est en arrière-plan mais pas fermée
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Vérifier si l'app a été ouverte via une notification
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });
  }

  /// Gère les messages reçus en premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (AppConstants.enableLogging) {
      print('🔔 Notification reçue en premier plan: ${message.notification?.title}');
    }

    // Afficher une notification locale
    await _showLocalNotification(message);
  }

  /// Gère le clic sur une notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    if (AppConstants.enableLogging) {
      print('🔔 Notification cliquée: ${message.notification?.title}');
    }

    // Extraire les données de l'alerte
    final data = message.data;
    if (data.containsKey('alert_id')) {
      final alertId = data['alert_id'];
      final latitude = double.tryParse(data['latitude'] ?? '0') ?? 0.0;
      final longitude = double.tryParse(data['longitude'] ?? '0') ?? 0.0;

      // Sauvegarder les infos pour navigation
      await StorageService.instance.saveString('pending_alert_navigation', jsonEncode({
        'alert_id': alertId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      if (AppConstants.enableLogging) {
        print('📍 Navigation vers alerte: $alertId ($latitude, $longitude)');
      }
    }
  }

  /// Callback quand une notification locale est cliquée
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleMessageOpenedApp(RemoteMessage(
        data: data,
        notification: RemoteNotification(
          title: data['title'],
          body: data['body'],
        ),
      ));
    }
  }

  /// Affiche une notification locale
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'emergency_alerts',
      'Alertes d\'urgence',
      channelDescription: 'Notifications pour les alertes SOS à proximité',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: AppConstants.errorColor,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'emergency_alert.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Sauvegarde le token FCM dans Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = StorageService.instance.getString(AppConstants.keyUserId);
      if (userId == null) {
        if (AppConstants.enableLogging) {
          print('⚠️ Impossible de sauvegarder le token: utilisateur non connecté');
        }
        return;
      }

      await SupabaseService.instance.upsert(
        'utilisateurs',
        {
          'id': userId,
          'fcm_token': token,
          'fcm_token_updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );

      if (AppConstants.enableLogging) {
        print('✅ Token FCM sauvegardé dans Supabase');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur sauvegarde token FCM: $e');
      }
    }
  }

  /// Supprime le token FCM (lors de la déconnexion)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;

      final userId = StorageService.instance.getString(AppConstants.keyUserId);
      if (userId != null) {
        await SupabaseService.instance.update(
          'utilisateurs',
          {'fcm_token': null},
          idColumn: 'id',
          idValue: userId,
        );
      }

      if (AppConstants.enableLogging) {
        print('✅ Token FCM supprimé');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur suppression token FCM: $e');
      }
    }
  }

  /// S'abonner à un topic (pour les notifications par zone géographique)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (AppConstants.enableLogging) {
        print('✅ Abonné au topic: $topic');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur abonnement topic: $e');
      }
    }
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (AppConstants.enableLogging) {
        print('✅ Désabonné du topic: $topic');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('❌ Erreur désabonnement topic: $e');
      }
    }
  }
}

/// Handler pour les messages en arrière-plan (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (AppConstants.enableLogging) {
    print('🔔 Notification en arrière-plan: ${message.notification?.title}');
  }
}

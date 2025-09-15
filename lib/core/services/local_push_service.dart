import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service simple pour notifications locales persistantes (Android/iOS/Web no-op)
class LocalPushService {
  LocalPushService._();
  static final LocalPushService instance = LocalPushService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> showPersistent({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    const android = AndroidNotificationDetails(
      'gm_persistent',
      'Guinemali Persistent',
      channelDescription: 'Notifications persistantes Guinemali',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(id, title, body, details);
  }

  Future<void> update(int id, {required String title, required String body}) async {
    await showPersistent(id: id, title: title, body: body);
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}



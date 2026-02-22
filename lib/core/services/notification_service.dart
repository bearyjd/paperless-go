import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _nextId = 0;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  static Future<void> showUploadComplete({
    required String title,
    String? body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'upload_complete',
      'Upload Complete',
      channelDescription: 'Notifications when document uploads complete',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.show(
      _nextId++,
      title,
      body ?? 'Your document has been processed successfully.',
      const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> showUploadFailed({
    required String title,
    String? error,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'upload_status',
      'Upload Status',
      channelDescription: 'Notifications about document upload status',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.show(
      _nextId++,
      title,
      error ?? 'Document processing failed.',
      const NotificationDetails(android: androidDetails),
    );
  }
}

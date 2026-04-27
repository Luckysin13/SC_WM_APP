import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // No-op: stop monitoring is handled natively via StopServiceReceiver
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap — nothing needed for now
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      
      // Create a high-priority channel for alarms
      const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
        'ossc_alarms',
        'Alarms',
        description: 'Notifications for when your meat is done.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin?.createNotificationChannel(alarmChannel);

      // Create a low-priority silent channel for the persistent background service
      const AndroidNotificationChannel bgChannel = AndroidNotificationChannel(
        'ossc_bg',
        'Background Service',
        description: 'Persistent notification for background monitoring.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );
      await androidPlugin?.createNotificationChannel(bgChannel);
    }

    _isInitialized = true;
  }

  Future<void> showMeatDoneNotification({
    required double currentTemp,
    required double targetTemp,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'meat_alarm_channel',
      'Meat Alarms',
      channelDescription: 'Notifications for when your meat is done.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      categoryIdentifier: 'meat_alarm',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1,
      '🥩 MEAT IS DONE!',
      'Target of ${targetTemp.toStringAsFixed(1)}°F reached (Current: ${currentTemp.toStringAsFixed(1)}°F)',
      platformDetails,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../constants/device_commands.dart';
import '../models/live_state.dart';

/// MethodChannel to talk to native Android code for the notification action.
const _nativeChannel = MethodChannel('ossc/bg_notification');

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Keep CPU awake while background service is running
  try {
    WakelockPlus.enable();
  } catch (_) {}

  // Background isolate WebSocket logic
  WebSocketChannel? channel;
  Timer? pingTimer;
  Timer? statusTimer;
  bool isConnecting = false;
  bool meatAlarmSent = false;
  double? lastSetpoint;
  bool isStopping = false;

  statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    service.invoke('status', {'running': true});
  });

  // Cleanup function
  void cleanup() {
    if (isStopping) return;
    isStopping = true;
    statusTimer?.cancel();
    pingTimer?.cancel();
    try { channel?.sink.close(); } catch (_) {}
    service.invoke('status', {'running': false});
    try { WakelockPlus.disable(); } catch (_) {}
    flutterLocalNotificationsPlugin.cancel(888);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('bg_monitoring_active', false);
    });
    if (service is AndroidServiceInstance) {
      service.stopSelf();
    }
  }

  // Listen for stop from the UI (the toggle switch)
  service.on('stopService').listen((event) {
    cleanup();
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Build the notification with a native PendingIntent "Stop Monitoring" button.
  // We call into native Android to show this notification because
  // flutter_local_notifications action buttons run in a separate Dart isolate
  // that cannot communicate with this service isolate.
  try {
    await _nativeChannel.invokeMethod('showServiceNotification');
  } catch (_) {
    // If native channel isn't available, show a basic notification without button
    flutterLocalNotificationsPlugin.show(
      888,
      'OSSC Monitoring',
      'Monitoring your smoker in the background...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ossc_bg',
          'Background Service',
          icon: '@mipmap/launcher_icon',
          ongoing: true,
          silent: true,
        ),
      ),
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final wsUrl = prefs.getString('bg_ws_url');
  await prefs.setBool('bg_monitoring_active', true);

  void connect() async {
    if (wsUrl == null || isConnecting || isStopping) return;
    isConnecting = true;

    try {
      channel?.sink.close();
      pingTimer?.cancel();

      channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      isConnecting = false;

      pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (isStopping) { timer.cancel(); return; }
        try {
          channel?.sink.add(DeviceCommands.getValues);
        } catch (_) {
          timer.cancel();
          if (!isStopping) connect();
        }
      });

      LiveState currentState = LiveState.initial();

      channel!.stream.listen(
        (data) {
          if (isStopping) return;
          try {
            final json = jsonDecode(data as String);
            if (json is Map<String, dynamic>) {
              currentState = currentState.copyWithJson(json);

              final currentTemp = double.tryParse(currentState.meatTemp);
              final targetTemp = currentState.meatDoneSetpoint.toDouble();

              if (lastSetpoint != targetTemp) {
                meatAlarmSent = false;
                lastSetpoint = targetTemp;
              }

              if (currentState.doneAlarmEnabled &&
                  currentTemp != null &&
                  currentTemp >= targetTemp &&
                  targetTemp > 0) {
                if (!meatAlarmSent) {
                  flutterLocalNotificationsPlugin.show(
                    999,
                    'Meat is Done!',
                    'Target temperature ($targetTemp°F) reached.',
                    const NotificationDetails(
                      android: AndroidNotificationDetails(
                        'ossc_alarms',
                        'Alarms',
                        importance: Importance.max,
                        priority: Priority.high,
                      ),
                    ),
                  );
                  meatAlarmSent = true;
                }
              } else if (currentTemp != null && currentTemp < targetTemp - 1) {
                meatAlarmSent = false;
              }
            }
          } catch (_) {}
        },
        onDone: () {
          if (!isConnecting && !isStopping) {
            Future.delayed(const Duration(seconds: 5), connect);
          }
        },
        onError: (e) {
          if (!isConnecting && !isStopping) {
            Future.delayed(const Duration(seconds: 5), connect);
          }
        },
      );
    } catch (e) {
      isConnecting = false;
      if (!isStopping) Future.delayed(const Duration(seconds: 5), connect);
    }
  }

  connect();
}

class BackgroundMonitor {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'ossc_bg',
        'Background Service',
        description: 'This channel is used for important notifications.',
        importance: Importance.low,
      );

      const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
        'ossc_alarms',
        'Alarms',
        description: 'Smoker alarm notifications.',
        importance: Importance.max,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(alarmChannel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'ossc_bg',
        initialNotificationTitle: 'OSSC Monitoring',
        initialNotificationContent: 'Monitoring smoker...',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: false,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  static Future<void> start(String wsUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bg_ws_url', wsUrl);
    await prefs.setBool('bg_monitoring_active', true);

    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bg_monitoring_active', false);
  }

  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

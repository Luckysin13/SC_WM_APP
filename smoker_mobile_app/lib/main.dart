import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/router.dart';
import 'app/theme/app_theme.dart';
import 'package:ossc/core/providers/core_providers.dart';
import 'shared/services/notification_service.dart';
import 'core/notifiers/alarm_notifier.dart';
import 'core/services/background_service.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().init();
  await BackgroundMonitor.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SmokerApp(),
    ),
  );
}

class SmokerApp extends ConsumerStatefulWidget {
  const SmokerApp({super.key});

  @override
  ConsumerState<SmokerApp> createState() => _SmokerAppState();
}

class _SmokerAppState extends ConsumerState<SmokerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // We intentionally DO NOT stop the background monitor on detached,
    // because the 'Stay Awake' feature is meant to keep monitoring the smoker
    // even when the user completely closes (swipes away) the app.
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    
    // Activate alarm monitoring
    ref.watch(alarmProvider);

    return MaterialApp.router(
      title: 'OSSC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark mode as per web UI
      routerConfig: router,
      scrollBehavior: AppScrollBehavior(),
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: child,
        );
      },
    );
  }
}

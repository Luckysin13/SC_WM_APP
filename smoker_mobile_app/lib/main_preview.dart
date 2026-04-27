import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app/router.dart';
import 'app/theme/app_theme.dart';
import 'package:ossc/core/providers/core_providers.dart';
import 'core/networking/device_session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Override DeviceSessionManager to enable mock mode by default
        deviceSessionManagerProvider.overrideWith((ref) {
          final dio = ref.watch(dioProvider);
          return DeviceSessionManager(
            dio: dio,
            enableMockMode: true,
            checkConnectivity: () async => [ConnectivityResult.wifi],
            onLiveStateUpdated: (state) {
              ref.read(deviceStateProvider.notifier).state = state;
            },
            onStatusChanged: (status) {
              ref.read(connectionStatusProvider.notifier).state = status;
            },
          );
        }),
      ],
      child: const SmokerPreviewApp(),
    ),
  );
}

class SmokerPreviewApp extends ConsumerWidget {
  const SmokerPreviewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'OSSC Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

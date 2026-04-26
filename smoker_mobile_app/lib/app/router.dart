import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/discovery/presentation/splash_screen.dart';
import '../features/discovery/presentation/discovery_screen.dart';
import '../features/discovery/presentation/manual_ip_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/alarms/presentation/options_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/configuration/presentation/configuration_screen.dart';
import '../features/wifi_setup/presentation/wifi_setup_screen.dart';
import '../features/ota/presentation/ota_screen.dart';
import '../features/discovery/presentation/troubleshooting_screen.dart';
import 'shell_layout.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/ota', builder: (context, state) => const OtaScreen()),
      GoRoute(
        path: '/troubleshoot',
        builder: (context, state) => const TroubleshootingScreen(),
      ),
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoveryScreen(),
        routes: [
          GoRoute(
            path: 'manual',
            builder: (context, state) => const ManualIpScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => ShellLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/options',
            builder: (context, state) => const OptionsScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/configuration',
            builder: (context, state) => const ConfigurationScreen(),
          ),
          GoRoute(
            path: '/wifi_setup',
            builder: (context, state) => const WifiSetupScreen(),
          ),
        ],
      ),
    ],
  );
});

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/networking/device_session_manager.dart';
import '../../../app/theme/colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _initApp() async {
    final cacheService = ref.read(localCacheServiceProvider);
    final lastDevice = cacheService.getLastDevice();

    if (lastDevice == null) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go('/discover');
      return;
    }

    final sessionManager = ref.read(deviceSessionManagerProvider);

    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (ref.read(connectionStatusProvider) != ConnectionStatus.connected &&
          mounted) {
        context.go('/discover');
      }
    });

    sessionManager.connect(lastDevice);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ConnectionStatus>(connectionStatusProvider, (previous, current) {
      if (current == ConnectionStatus.connected && mounted) {
        _timeoutTimer?.cancel();
        context.go('/dashboard');
      }
    });

    final cacheService = ref.read(localCacheServiceProvider);
    final lastDevice = cacheService.getLastDevice();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.2),
            radius: 1.2,
            colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon/icon.png',
                height: 120,
                width: 120,
              ),
              const SizedBox(height: 32),
              const Text(
                'OSSC',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'OPEN SOURCE\nSMOKER CONTROLLER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    SmokerColors.accentOrange.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                lastDevice != null
                    ? 'CONNECTING TO ${lastDevice.displayName.toUpperCase()}...'
                    : 'INITIALIZING SYSTEM...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

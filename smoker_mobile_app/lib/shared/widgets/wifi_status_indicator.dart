import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/networking/device_session_manager.dart';

class WifiStatusIndicator extends ConsumerWidget {
  const WifiStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveState = ref.watch(deviceStateProvider);
    final connectionState = ref.watch(connectionStatusProvider);
    final isConnected = connectionState == ConnectionStatus.connected;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/discover'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liveState.isApMode ? Icons.wifi_tethering : Icons.wifi,
                size: 18,
                color: isConnected
                    ? (liveState.isApMode ? Colors.orange : Colors.green)
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                liveState.isApMode ? "AP" : "STA",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

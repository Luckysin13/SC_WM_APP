import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/providers.dart';

class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);
    final isWifiOff =
        connectivityState.value?.isEmpty ?? true ||
        connectivityState.value!.contains(ConnectivityResult.none);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x1AEF4444), // rgba(239, 68, 68, 0.1)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x66EF4444),
        ), // rgba(239, 68, 68, 0.4)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isWifiOff)
            const Icon(Icons.wifi_off_rounded, color: Color(0xFFF87171), size: 18)
          else
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF87171)),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            isWifiOff ? 'No network connection' : 'Reconnecting to device...',
            style: const TextStyle(
              color: Color(0xFFF87171),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

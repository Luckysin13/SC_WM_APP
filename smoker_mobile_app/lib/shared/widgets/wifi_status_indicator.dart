import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ossc/core/providers/core_providers.dart';
import '../../core/networking/device_session_manager.dart';

import '../../core/utils/ui_utils.dart';

class WifiStatusIndicator extends ConsumerWidget {
  const WifiStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveState = ref.watch(deviceStateProvider);
    final connectionState = ref.watch(connectionStatusProvider);
    final isConnected = connectionState == ConnectionStatus.connected;
    final config = ResponsiveToolbarConfig.of(context);

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
          padding: EdgeInsets.symmetric(
            horizontal: config.spacing * 0.75,
            vertical: config.spacing * 0.4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liveState.isApMode ? Icons.wifi_tethering : Icons.wifi,
                size: config.actionIconSize * 0.75,
                color: isConnected
                    ? (liveState.isApMode ? Colors.orange : Colors.green)
                    : Colors.red,
              ),
              SizedBox(width: config.spacing * 0.5),
              Text(
                liveState.isApMode ? "AP" : "STA",
                style: TextStyle(
                  fontSize: config.actionIconSize * 0.75,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:ossc/core/providers/core_providers.dart';
import '../../../core/networking/device_session_manager.dart';
import '../../../shared/widgets/temp_card.dart';
import '../../../shared/widgets/setpoint_editor.dart';
import '../../../shared/widgets/fan_card.dart';
import '../../../shared/widgets/connection_banner.dart';
import '../../../shared/widgets/probe_notice_banner.dart';
import '../../../app/theme/colors.dart';
import '../../../shared/widgets/wifi_status_indicator.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceSessionManagerProvider).changeView('dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(deviceStateProvider);
    final connectionState = ref.watch(connectionStatusProvider);
    final isConnected = connectionState == ConnectionStatus.connected;

    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= 600;

    final screenWidth = MediaQuery.of(context).size.width;
    double labelFontSize = 22;
    if (!isTablet) {
      final double availableWidth = (screenWidth - 48) / 2 - 32;
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'MEAT TEMP',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      if (textPainter.width > availableWidth) {
        labelFontSize = 22 * (availableWidth / textPainter.width);
      }
    }

    final labelStyle = TextStyle(
      fontSize: labelFontSize,
      color: SmokerColors.textSecondary,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w800,
    );

    final config = ResponsiveToolbarConfig.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              toolbarHeight: config.toolbarHeight,
              centerTitle: false,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/icon/icon.png', height: config.mainIconSize),
                  ),
                  SizedBox(width: config.spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'O.S.S.C',
                          style: TextStyle(
                            fontSize: config.titleFontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Open Source Smoker Controller'.toUpperCase(),
                            style: TextStyle(
                              fontSize: config.subtitleFontSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: SmokerColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: SmokerColors.primaryGradient,
                  ),
                ),
              ),
              actions: [const WifiStatusIndicator(), const SizedBox(width: 8)],
            ),
          ];
        },
        body: Column(
          children: [
            if (!isConnected) const ConnectionBanner(),
            if (isConnected)
              ProbeNoticeBanner(
                meatTemp: liveState.meatTemp,
                pitTemp: liveState.pitTemp,
              ),
            Expanded(
              child: Opacity(
                opacity: isConnected ? 1.0 : 0.6,
                child: IgnorePointer(
                  ignoring: !isConnected,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TempCard(
                              title: 'Meat Temp',
                              tempDisplay: liveState.meatTemp,
                              isDone:
                                  liveState.doneAlarmEnabled &&
                                  liveState.meatDoneFanDisabled,
                              labelStyle: labelStyle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TempCard(
                              title: 'Pit Temp',
                              tempDisplay: liveState.pitTemp,
                              labelStyle: labelStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SetpointEditor(
                        currentSetpoint: liveState.pitSetpoint,
                        enabled: isConnected,
                        onSet: (val) {
                          ref
                              .read(deviceSessionManagerProvider)
                              .setSetpointCommand(val);
                        },
                        labelStyle: labelStyle,
                      ),
                      const SizedBox(height: 20),
                      FanCard(
                        fanPercentDisplay: liveState.fanSpeedPercent,
                        isAuto: liveState.fanAuto,
                        enabled: isConnected,
                        fanDisabledACK: liveState.meatDoneFanDisabled,
                        onToggleMode: (auto) {
                          ref
                              .read(deviceSessionManagerProvider)
                              .toggleFanMode(auto);
                        },
                        onAck: () {
                          ref
                              .read(deviceSessionManagerProvider)
                              .sendCommand('AckMeatDoneFanDisable');
                        },
                        labelStyle: labelStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/networking/device_session_manager.dart';
import '../../../core/models/ota_state.dart';
import '../../../shared/widgets/connection_banner.dart';
import '../../../shared/widgets/smoker_card.dart';
import '../../../app/theme/colors.dart';

class OtaScreen extends ConsumerStatefulWidget {
  const OtaScreen({super.key});

  @override
  ConsumerState<OtaScreen> createState() => _OtaScreenState();
}

class _OtaScreenState extends ConsumerState<OtaScreen> {
  Timer? _pollingTimer;
  Timer? _rebootTimer;
  int _rebootSecondsRemaining = 0;
  bool _rebootTimedOut = false;
  bool _showCelebration = false;
  String _finalVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceSessionManagerProvider).changeView('legacy');
      _requestOtaInfo();
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) _requestOtaInfo();
      });
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _rebootTimer?.cancel();
    super.dispose();
  }

  void _requestOtaInfo() {
    if (ref.read(connectionStatusProvider) == ConnectionStatus.connected) {
      ref.read(deviceSessionManagerProvider).sendCommand('getOTAInfo');
    }
  }

  void _checkUpdates() {
    ref.read(deviceSessionManagerProvider).sendCommand('checkOTAUpdates');
  }

  void _startUpdate() {
    final otaState = ref.read(otaProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SmokerColors.cardBg,
        title: const Text(
          'START UPDATE?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are about to update the firmware. The device will be unavailable for 1-2 minutes.',
              style: TextStyle(color: SmokerColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('FROM', otaState.currentVersion),
            const SizedBox(height: 8),
            _buildInfoRow('TO', otaState.latestVersion, isAccent: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final manager = ref.read(deviceSessionManagerProvider);
              manager.sendCommand('startOTAUpdate');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SmokerColors.accentOrange,
            ),
            child: const Text(
              'UPDATE NOW',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _startRebootCountdown() {
    _rebootSecondsRemaining = 20;
    _rebootTimedOut = false;
    _rebootTimer?.cancel();
    _rebootTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_rebootSecondsRemaining > 0) {
            _rebootSecondsRemaining--;
          } else {
            timer.cancel();
            _rebootTimer = null;
            _rebootTimedOut = true;
          }
        });
      }
    });
  }

  String _statusLabel(String statusText, String phase, int code) {
    final displayPhase = phase.isNotEmpty ? phase.toUpperCase() : 'FIRMWARE';
    switch (statusText.toLowerCase()) {
      case 'idle':
        return 'IDLE';
      case 'checking':
        return 'CHECKING FOR UPDATES...';
      case 'downloading':
        return 'DOWNLOADING $displayPhase...';
      case 'flashing':
        return 'FLASHING $displayPhase...';
      case 'success':
        return 'SUCCESS';
      case 'failed':
        return 'FAILED';
      default:
        return code == 0 ? 'IDLE' : statusText.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final otaState = ref.watch(otaProvider);
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    final isActive = otaState.isActive;
    final isError = otaState.isError;
    final isSuccess = otaState.isSuccess;

    // Trigger reboot countdown on success
    if (isSuccess &&
        _rebootTimer == null &&
        _rebootSecondsRemaining == 0 &&
        !_rebootTimedOut) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _startRebootCountdown(),
      );
    }

    // Verify update success when reconnected
    if (isConnected &&
        _rebootSecondsRemaining == 0 &&
        _rebootTimer != null &&
        otaState.currentVersion.isNotEmpty &&
        otaState.currentVersion == otaState.latestVersion &&
        !_showCelebration) {
      _rebootTimer?.cancel();
      _rebootTimer = null;
      _finalVersion = otaState.currentVersion;
      _showCelebration = true;
      setState(() {});
    }

    // Reset everything if we leave the screen or restart a check
    if (otaState.statusCode == 1) {
      _showCelebration = false;
      _rebootTimedOut = false;
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              centerTitle: false,
              title: const Text(
                'FIRMWARE UPDATE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
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
            ),
          ];
        },
        body: Column(
          children: [
            if (isActive || (isSuccess && !_showCelebration) || isError)
              _buildOtaStatusBanner(otaState, isConnected)
            else if (!isConnected)
              const ConnectionBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  SmokerCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildStepper(otaState),
                        const SizedBox(height: 24),
                        _buildStatusDisplay(otaState),
                        const SizedBox(height: 24),
                        _buildVersionInfo(otaState),
                        const SizedBox(height: 24),
                        if (isActive) _buildProgressArea(otaState),
                        if (isError)
                          _buildMessageArea(
                            otaState.errorMessage.isNotEmpty
                                ? otaState.errorMessage
                                : 'An error occurred.',
                            Colors.redAccent,
                          ),
                        if (isSuccess && !_showCelebration) ...[
                          _buildMessageArea(
                            'Update applied successfully! The device is now rebooting to finish the process. This usually takes about 20 seconds.',
                            Colors.greenAccent,
                          ),
                          if (_rebootTimedOut)
                            _buildMessageArea(
                              'Still not connected?'
                              '\nLED Flashing: Connect to SMOKER CONTROLLER'
                              '\nLED Solid: Connect to your WiFi',
                              SmokerColors.accentOrange,
                            ),
                          _buildRebootProgress(),
                        ],
                        if (_showCelebration) _buildCelebrationArea(),
                        const SizedBox(height: 12),
                        if (!_showCelebration)
                          _buildActions(isConnected, isActive, otaState),
                      ],
                    ),
                  ),
                  if (!isActive && !isSuccess && !isError && !_showCelebration)
                    _buildInstructions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.black,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'UPDATE COMPLETE!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your smoker is now running version $_finalVersion',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SmokerColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showCelebration = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(OtaState state) {
    final steps = [
      'Idle',
      'Checking',
      'Downloading',
      'Flashing',
      'Rebooting',
      'Verified',
    ];

    int currentStep = 0;
    bool allDone = false;

    if (_showCelebration) {
      currentStep = 5;
      allDone = true;
    } else if (state.isSuccess) {
      currentStep = 4;
    } else if (state.statusCode == 3) {
      currentStep = 3;
    } else if (state.statusCode == 2) {
      currentStep = 2;
    } else if (state.statusCode == 1) {
      currentStep = 1;
    }

    Widget buildStepLabel(int index, bool isVisible) {
      if (!isVisible) return const SizedBox(width: 32, height: 20);

      final isCompleted = index < currentStep || allDone;
      final isCurrent = index == currentStep && !allDone;
      final labelColor = (isCurrent || isCompleted)
          ? Colors.white
          : Colors.white38;

      return SizedBox(
        width: 32, // Match circle width
        height: 20,
        child: OverflowBox(
          minWidth: 0,
          maxWidth: 120, // Allow text to spread wider than circle
          child: Text(
            steps[index].toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: labelColor,
              fontSize: 8.5,
              fontWeight: (isCurrent || isCompleted)
                  ? FontWeight.w900
                  : FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Top Labels
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              buildStepLabel(i, i % 2 == 0),
              if (i < steps.length - 1) const Expanded(child: SizedBox()),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Circles and Lines
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              // Circle
              Builder(
                builder: (context) {
                  final isCompleted = i < currentStep || allDone;
                  final isCurrent = i == currentStep && !allDone;

                  Color circleColor;
                  Color contentColor;
                  bool isSolid = false;

                  if (isCompleted) {
                    circleColor = Colors.greenAccent;
                    contentColor = Colors.black;
                    isSolid = true;
                  } else if (isCurrent) {
                    circleColor = SmokerColors.accentBlue;
                    contentColor = Colors.white;
                    isSolid = false;
                  } else {
                    circleColor = Colors.white24;
                    contentColor = Colors.white38;
                    isSolid = false;
                  }

                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSolid ? circleColor : Colors.transparent,
                      border: Border.all(
                        color: circleColor,
                        width: isCurrent ? 3 : 2,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: circleColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: contentColor,
                              weight: 900,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: contentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  );
                },
              ),
              // Line
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: (i < currentStep || allDone)
                          ? Colors.greenAccent
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Bottom Labels
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              buildStepLabel(i, i % 2 != 0),
              if (i < steps.length - 1) const Expanded(child: SizedBox()),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRebootProgress() {
    final progress = (20 - _rebootSecondsRemaining) / 20.0;
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
        ),
        const SizedBox(height: 8),
        Text(
          'Reconnecting in $_rebootSecondsRemaining seconds...',
          style: const TextStyle(
            color: SmokerColors.textSecondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BEFORE YOU START',
            style: TextStyle(
              color: SmokerColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildInstructionItem(
            Icons.wifi_rounded,
            'Keep your phone near the smoker and ensure a stable WiFi connection.',
          ),
          const SizedBox(height: 12),
          _buildInstructionItem(
            Icons.power_rounded,
            'Do not power off the smoker or close the app during the update.',
          ),
          const SizedBox(height: 12),
          _buildInstructionItem(
            Icons.timer_rounded,
            'The process typically takes 1-2 minutes to complete.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SmokerColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: SmokerColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtaStatusBanner(OtaState otaState, bool isConnected) {
    final status = _statusLabel(
      otaState.statusText,
      otaState.phase,
      otaState.statusCode,
    );
    final isSuccess = otaState.isSuccess;
    final isError = otaState.isError;
    final isFlashing = otaState.statusCode == 3;

    Color color = isFlashing ? Colors.redAccent : SmokerColors.accentOrange;
    IconData icon = isFlashing ? Icons.bolt_rounded : Icons.sync_rounded;
    String message = isFlashing ? 'FLASHING DEVICE' : 'UPDATE IN PROGRESS';

    if (isSuccess) {
      color = Colors.greenAccent;
      icon = Icons.check_circle_outline_rounded;
      message = 'UPDATE SUCCESSFUL';
    } else if (isError) {
      color = Colors.redAccent;
      icon = Icons.error_outline_rounded;
      message = 'UPDATE FAILED';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: isFlashing ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          if (isFlashing)
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 20,
            )
          else
            Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isFlashing
                        ? 'CRITICAL: FLASHING DEVICE'
                        : '$message: ${status.toUpperCase()}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  isFlashing
                      ? 'DO NOT POWER OFF OR DISCONNECT. WRITING TO FLASH...'
                      : (isSuccess
                            ? 'Rebooting device... This may take a moment.'
                            : (isError
                                  ? 'Something went wrong. Please try again.'
                                  : (isConnected
                                        ? 'Keep this screen open and your phone near the device.'
                                        : 'Device disconnected. Reconnecting...'))),
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: isFlashing
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (otaState.isActive && otaState.progressPercent > 0)
            Text(
              '${otaState.progressPercent}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SmokerColors.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.system_update_rounded,
            color: SmokerColors.accentBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OVER-THE-AIR',
              style: TextStyle(
                color: SmokerColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'FIRMWARE UPDATE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusDisplay(OtaState otaState) {
    final status = _statusLabel(
      otaState.statusText,
      otaState.phase,
      otaState.statusCode,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const Text(
            'CURRENT STATE',
            style: TextStyle(
              color: SmokerColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(OtaState otaState) {
    return Column(
      children: [
        _buildInfoRow(
          'CURRENT VERSION',
          otaState.currentVersion.isEmpty ? 'UNKNOWN' : otaState.currentVersion,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          'LATEST AVAILABLE',
          otaState.latestVersion.isEmpty
              ? 'UP TO DATE'
              : (otaState.latestVersion == otaState.currentVersion
                    ? 'UP TO DATE'
                    : otaState.latestVersion),
          isAccent: otaState.updateAvailable,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAccent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SmokerColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isAccent ? SmokerColors.accentOrange : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressArea(OtaState otaState) {
    final status = otaState.statusText.toLowerCase();
    final isFlashing = otaState.statusCode == 3 || status == 'flashing';
    final isIdle = status == 'idle';

    // Default phase to "FIRMWARE" if not specified while active
    final displayPhase = otaState.phase.isNotEmpty
        ? otaState.phase.toUpperCase()
        : 'FIRMWARE';

    String actionText = 'DOWNLOADING';
    if (isFlashing) {
      actionText = 'FLASHING';
    } else if (isIdle) {
      actionText = 'PREPARING';
    }
    final accentColor = isFlashing ? Colors.redAccent : SmokerColors.accentBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$actionText $displayPhase...',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$actionText PROGRESS',
              style: const TextStyle(
                color: SmokerColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${otaState.progressPercent}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: otaState.progressPercent > 0
                ? otaState.progressPercent / 100.0
                : null,
            minHeight: 12,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMessageArea(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActions(bool isConnected, bool isActive, OtaState otaState) {
    return Column(
      children: [
        _buildButton(
          label: 'CHECK FOR UPDATES',
          icon: Icons.refresh_rounded,
          onPressed: (isConnected && !isActive) ? _checkUpdates : null,
          color: SmokerColors.accentBlue,
        ),
        if (otaState.updateAvailable) ...[
          const SizedBox(height: 12),
          _buildButton(
            label: 'START DEVICE UPDATE',
            icon: Icons.cloud_download_rounded,
            onPressed: (isConnected && !isActive) ? _startUpdate : null,
            color: SmokerColors.accentOrange,
          ),
        ],
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: onPressed != null
            ? (color ?? SmokerColors.accentBlue)
            : Colors.white10,
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null
            ? [
                const BoxShadow(
                  color: Colors.black38,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledForegroundColor: Colors.white24,
        ),
        icon: Icon(
          icon,
          size: 20,
          color: onPressed != null ? Colors.white : Colors.white24,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: onPressed != null ? Colors.white : Colors.white24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

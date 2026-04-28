import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:ossc/core/providers/core_providers.dart';
import '../../../core/networking/device_session_manager.dart';
import '../../../shared/widgets/connection_banner.dart';
import '../../../shared/widgets/smoker_card.dart';
import '../../../app/theme/colors.dart';
import '../../../core/services/background_service.dart';

final stayAwakeProvider = StateProvider<bool>((ref) => false);

class OptionsScreen extends ConsumerStatefulWidget {
  const OptionsScreen({super.key});

  @override
  ConsumerState<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends ConsumerState<OptionsScreen> {
  final _meatController = TextEditingController();
  final _warmController = TextEditingController();

  final _meatFocus = FocusNode();
  final _warmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _meatFocus.addListener(() {
      if (!_meatFocus.hasFocus && mounted) setState(() {});
    });
    _warmFocus.addListener(() {
      if (!_warmFocus.hasFocus && mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(deviceSessionManagerProvider).changeView('options');
      final isRunning = await BackgroundMonitor.isRunning();
      ref.read(stayAwakeProvider.notifier).state = isRunning;

      // Listen for background service status updates
      FlutterBackgroundService().on('status').listen((event) {
        if (mounted) {
          final isRunning = event?['running'] ?? false;
          if (ref.read(stayAwakeProvider) != isRunning) {
             ref.read(stayAwakeProvider.notifier).state = isRunning;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _meatController.dispose();
    _warmController.dispose();
    _meatFocus.dispose();
    _warmFocus.dispose();
    super.dispose();
  }

  void _sendDoneAlarmToggle(bool value) {
    ref.read(deviceSessionManagerProvider).sendCommand('DoneAlarm$value');
  }

  void _sendKeepWarmToggle(bool value) {
    ref.read(deviceSessionManagerProvider).sendCommand('KeepWarm$value');
  }

  void _sendMeatSetpoint(String val) {
    final parsed = int.tryParse(val);
    if (parsed != null && parsed >= 160 && parsed <= 225) {
      ref.read(deviceSessionManagerProvider).sendCommand('8b$parsed');
    }
    FocusScope.of(context).unfocus();
  }

  void _sendWarmSetpoint(String val, int currentMeatSetpoint) {
    final parsed = int.tryParse(val);
    if (parsed != null) {
      if (parsed >= currentMeatSetpoint) {
        _sendKeepWarmToggle(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Keep Warm disabled: temperature must be lower than meat target.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (parsed >= 159 && parsed <= 450) {
        ref.read(deviceSessionManagerProvider).sendCommand('9b$parsed');
      }
    }
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(deviceStateProvider);
    final connectionState = ref.watch(connectionStatusProvider);
    final isConnected = connectionState == ConnectionStatus.connected;

    if (!_meatFocus.hasFocus &&
        _meatController.text != liveState.meatDoneSetpoint.toString()) {
      _meatController.text = liveState.meatDoneSetpoint.toString();
    }
    if (!_warmFocus.hasFocus &&
        _warmController.text != liveState.keepWarmSetpoint.toString()) {
      _warmController.text = liveState.keepWarmSetpoint.toString();
    }

    final meatDirty =
        _meatController.text != liveState.meatDoneSetpoint.toString();
    final warmDirty =
        _warmController.text != liveState.keepWarmSetpoint.toString();

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
                  Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: config.mainIconSize,
                  ),
                  SizedBox(width: config.spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'OPTIONS',
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
                            'Alarms and keep warm settings'.toUpperCase(),
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
            ),
          ];
        },
        body: Column(
          children: [
            if (!isConnected) const ConnectionBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildPremiumAlarmCard(
                    title: 'MEAT DONE',
                    subtitle:
                        'Automatically disable the fan when the meat reaches target.',
                    icon: Icons.restaurant,
                    isEnabled: liveState.doneAlarmEnabled,
                    isOnline: isConnected,
                    onToggle: (v) {
                      if (!v && liveState.keepWarmEnabled) {
                        _sendKeepWarmToggle(false);
                      }
                      _sendDoneAlarmToggle(v);
                    },
                    expandedContent: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildPremiumInput(
                          controller: _meatController,
                          focusNode: _meatFocus,
                          label: 'Meat Target Temp (°F)',
                          helper: 'Range: 160–225 °F',
                          isEnabled: isConnected,
                          isDirty: meatDirty,
                          validator: (v) {
                            final p = int.tryParse(v ?? '');
                            if (p == null || p < 160 || p > 225) {
                              return '160-225 only';
                            }
                            return null;
                          },
                          onSubmitted: isConnected ? (v) => _sendMeatSetpoint(v) : null,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.vibration, color: SmokerColors.accentBlue, size: 24),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'BACKGROUND ALARM (STAY AWAKE)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: ref.watch(stayAwakeProvider),
                                    onChanged: (val) async {
                                      ref.read(stayAwakeProvider.notifier).state = val;
                                      if (val) {
                                        final session = ref.read(deviceSessionManagerProvider);
                                        if (session.transport != null) {
                                          await BackgroundMonitor.start(session.transport!.wsBaseUrl);
                                        }
                                      } else {
                                        await BackgroundMonitor.stop();
                                      }
                                    },
                                    activeThumbColor: SmokerColors.accentBlue,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Note: Meat Done notifications will NOT be active when the app is minimized unless this Stay Awake function is enabled.',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSaveButton(
                          onPressed: isConnected
                              ? () => _sendMeatSetpoint(_meatController.text)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPremiumAlarmCard(
                    title: 'KEEP WARM',
                    subtitle:
                        'Lowers pit temp to holding level after meat is done.',
                    icon: Icons.fireplace,
                    isEnabled: liveState.keepWarmEnabled,
                    isOnline: isConnected,
                    onToggle: (v) {
                      if (v && !liveState.doneAlarmEnabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enable Meat Done Alert first.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      _sendKeepWarmToggle(v);
                    },
                    expandedContent: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildPremiumInput(
                          controller: _warmController,
                          focusNode: _warmFocus,
                          label: 'Keep Warm Pit Temp (°F)',
                          helper: 'Must be lower than Meat Done target',
                          isEnabled: isConnected,
                          isDirty: warmDirty,
                          validator: (v) {
                            final p = int.tryParse(v ?? '');
                            if (p == null || p < 159 || p > 450) {
                              return '159-450 only';
                            }
                            if (p >= liveState.meatDoneSetpoint) {
                              return 'Must be less than Meat Done target';
                            }
                            return null;
                          },
                          onSubmitted: isConnected ? (v) => _sendWarmSetpoint(v, liveState.meatDoneSetpoint) : null,
                        ),
                        const SizedBox(height: 16),
                        _buildSaveButton(
                          onPressed: isConnected
                              ? () => _sendWarmSetpoint(
                                  _warmController.text,
                                  liveState.meatDoneSetpoint,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumAlarmCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEnabled,
    required bool isOnline,
    required ValueChanged<bool> onToggle,
    required Widget expandedContent,
  }) {
    return SmokerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Colors.tealAccent.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? Colors.tealAccent : Colors.white38,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SmokerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: isOnline ? onToggle : null,
                activeTrackColor: SmokerColors.accentBlue.withValues(
                  alpha: 0.5,
                ),
                activeThumbColor: SmokerColors.accentBlue,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isEnabled ? expandedContent : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String helper,
    required bool isEnabled,
    bool isDirty = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (_) => setState(() {}),
      onFieldSubmitted: onSubmitted,
      onTap: () {
        controller.clear();
        setState(() {});
      },
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.number,
      enabled: isEnabled,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDirty ? SmokerColors.accentOrange : SmokerColors.textSecondary,
          fontSize: 14,
          fontWeight: isDirty ? FontWeight.bold : FontWeight.normal,
        ),
        helperText: helper,
        helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDirty ? SmokerColors.accentOrange : Colors.white.withValues(alpha: 0.1),
            width: isDirty ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDirty ? SmokerColors.accentOrange : Colors.white.withValues(alpha: 0.1),
            width: isDirty ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDirty ? SmokerColors.accentOrange : SmokerColors.accentBlue,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSaveButton({VoidCallback? onPressed}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: onPressed != null ? SmokerColors.accentBlue : Colors.white10,
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
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'SAVE SETTINGS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

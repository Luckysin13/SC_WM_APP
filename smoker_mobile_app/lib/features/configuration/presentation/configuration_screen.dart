import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ossc/core/providers/core_providers.dart';
import '../../../core/models/live_state.dart';
import '../../../core/networking/device_session_manager.dart';
import '../../../shared/widgets/connection_banner.dart';
import '../../../shared/widgets/smoker_card.dart';
import '../../../app/theme/colors.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../shared/widgets/version_display.dart';

class ConfigurationScreen extends ConsumerStatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  ConsumerState<ConfigurationScreen> createState() =>
      _ConfigurationScreenState();
}

class _ConfigurationScreenState extends ConsumerState<ConfigurationScreen> {
  final _pitOffsetController = TextEditingController();
  final _meatOffsetController = TextEditingController();

  final _kpController = TextEditingController();
  final _kiController = TextEditingController();
  final _kdController = TextEditingController();

  // Timezone: store POSIX string separately; controller shows human label
  final _tzController = TextEditingController();
  String _selectedTzPosix = '';
  bool _showDebug = false;

  final _pitFocus = FocusNode();
  final _meatFocus = FocusNode();
  final _kpFocus = FocusNode();
  final _kiFocus = FocusNode();
  final _kdFocus = FocusNode();

  static const List<(String label, String posix)> _timezones = [
    ('Eastern US (New York)', 'EST5EDT,M3.2.0,M11.1.0'),
    ('Central US (Chicago)', 'CST6CDT,M3.2.0,M11.1.0'),
    ('Mountain US (Denver)', 'MST7MDT,M3.2.0,M11.1.0'),
    ('Mountain US (Phoenix, no DST)', 'MST7'),
    ('Pacific US (Los Angeles)', 'PST8PDT,M3.2.0,M11.1.0'),
    ('Alaska (Anchorage)', 'AKST9AKDT,M3.2.0,M11.1.0'),
    ('Hawaii', 'HST10'),
  ];

  @override
  void initState() {
    super.initState();
    _pitFocus.addListener(() {
      if (!_pitFocus.hasFocus && mounted) setState(() {});
    });
    _meatFocus.addListener(() {
      if (!_meatFocus.hasFocus && mounted) setState(() {});
    });
    _kpFocus.addListener(() {
      if (!_kpFocus.hasFocus && mounted) setState(() {});
    });
    _kiFocus.addListener(() {
      if (!_kiFocus.hasFocus && mounted) setState(() {});
    });
    _kdFocus.addListener(() {
      if (!_kdFocus.hasFocus && mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceSessionManagerProvider).changeView('configuration');
    });
  }

  @override
  void dispose() {
    _pitOffsetController.dispose();
    _meatOffsetController.dispose();
    _kpController.dispose();
    _kiController.dispose();
    _kdController.dispose();
    _tzController.dispose();

    _pitFocus.dispose();
    _meatFocus.dispose();
    _kpFocus.dispose();
    _kiFocus.dispose();
    _kdFocus.dispose();

    super.dispose();
  }

  void _sendCalibration() {
    final curPit = ref.read(deviceStateProvider).pitOffset;
    final curMeat = ref.read(deviceStateProvider).meatOffset;

    final pOff = int.tryParse(_pitOffsetController.text) ?? curPit;
    final mOff = int.tryParse(_meatOffsetController.text) ?? curMeat;

    final manager = ref.read(deviceSessionManagerProvider);
    if (pOff != curPit) manager.sendCommand('CalibratePit:$pOff');
    if (mOff != curMeat) manager.sendCommand('CalibrateMeat:$mOff');

    FocusScope.of(context).unfocus();
  }

  void _sendPID() {
    final curKp = ref.read(deviceStateProvider).kp;
    final curKi = ref.read(deviceStateProvider).ki;
    final curKd = ref.read(deviceStateProvider).kd;

    final p = double.tryParse(_kpController.text) ?? curKp;
    final i = double.tryParse(_kiController.text) ?? curKi;
    final d = double.tryParse(_kdController.text) ?? curKd;

    ref.read(deviceSessionManagerProvider).sendCommand('UpdatePID:$p:$i:$d');
    FocusScope.of(context).unfocus();
  }

  void _sendTimezone() {
    final tz = _selectedTzPosix.isNotEmpty
        ? _selectedTzPosix
        : _tzController.text;
    if (tz.isNotEmpty) {
      ref.read(deviceSessionManagerProvider).sendCommand('UpdateTimezone:$tz');
    }
    FocusScope.of(context).unfocus();
  }

  void _confirmAndStartAutotune(bool currentlyActive) {
    if (currentlyActive) {
      ref.read(deviceSessionManagerProvider).sendCommand('StartAutotune:false');
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SmokerColors.secondaryBg,
        title: Row(
          children: [
            Icon(Icons.science, color: SmokerColors.accentOrange),
            const SizedBox(width: 8),
            const Text('Autotune Mode', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Autotune will identify optimal PID values by cycling the fan.\n\n'
          'This takes 15–30 minutes. Run only with stable pit temp and no food.',
          style: TextStyle(color: SmokerColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SmokerColors.accentBlue,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        ref
            .read(deviceSessionManagerProvider)
            .sendCommand('StartAutotune:true');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(deviceStateProvider);
    final connectionState = ref.watch(connectionStatusProvider);
    final isConnected = connectionState == ConnectionStatus.connected;

    if (liveState.timezone.isNotEmpty &&
        _selectedTzPosix != liveState.timezone) {
      _selectedTzPosix = liveState.timezone;
      final match = _timezones
          .where((t) => t.$2 == liveState.timezone)
          .firstOrNull;
      _tzController.text = match?.$1 ?? liveState.timezone;
    }

    // Individual field updates based on specific focus
    if (!_pitFocus.hasFocus &&
        _pitOffsetController.text != liveState.pitOffset.toString()) {
      _pitOffsetController.text = liveState.pitOffset.toString();
    }
    if (!_meatFocus.hasFocus &&
        _meatOffsetController.text != liveState.meatOffset.toString()) {
      _meatOffsetController.text = liveState.meatOffset.toString();
    }
    if (!_kpFocus.hasFocus && _kpController.text != liveState.kp.toString()) {
      _kpController.text = liveState.kp.toString();
    }
    if (!_kiFocus.hasFocus && _kiController.text != liveState.ki.toString()) {
      _kiController.text = liveState.ki.toString();
    }
    if (!_kdFocus.hasFocus && _kdController.text != liveState.kd.toString()) {
      _kdController.text = liveState.kd.toString();
    }

    final pitDirty = _pitOffsetController.text != liveState.pitOffset.toString();
    final meatDirty =
        _meatOffsetController.text != liveState.meatOffset.toString();
    final kpDirty = _kpController.text != liveState.kp.toString();
    final kiDirty = _kiController.text != liveState.ki.toString();
    final kdDirty = _kdController.text != liveState.kd.toString();
    final tzDirty = _tzController.text !=
        (_timezones.where((t) => t.$2 == liveState.timezone).firstOrNull?.$1 ??
            liveState.timezone);

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
                    Icons.settings,
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
                          'CONFIGURATION',
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
                            'Calibrate probes and tune controllers'.toUpperCase(),
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh Values',
                  onPressed: isConnected
                      ? () => ref
                            .read(deviceSessionManagerProvider)
                            .sendCommand('getValues')
                      : null,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            if (!isConnected) const ConnectionBanner(),
            if (isConnected && liveState.isApMode) _buildApModeNotice(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildCalibrationCard(isConnected, liveState, pitDirty: pitDirty, meatDirty: meatDirty),
                  const SizedBox(height: 16),
                  _buildPidCard(isConnected, liveState, kpDirty: kpDirty, kiDirty: kiDirty, kdDirty: kdDirty),
                  const SizedBox(height: 16),
                  _buildTimezoneCard(isConnected, liveState.isApMode, tzDirty: tzDirty),
                  const SizedBox(height: 16),
                  _buildOtaCard(isConnected, liveState.isApMode),
                  const SizedBox(height: 32),
                  _buildVersionInfo(),
                  const SizedBox(height: 16),
                  _buildDebugSection(liveState),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: VersionDisplay(),
      ),
    );
  }

  Widget _buildDebugSection(LiveState liveState) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _showDebug = !_showDebug),
          icon: Icon(
            _showDebug ? Icons.bug_report : Icons.bug_report_outlined,
            size: 16,
            color: Colors.white38,
          ),
          label: Text(
            _showDebug ? 'HIDE DEBUG INFO' : 'SHOW DEBUG INFO',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (_showDebug) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDebugRow('Meat Temp', liveState.meatTemp),
                _buildDebugRow('Pit Temp', liveState.pitTemp),
                _buildDebugRow(
                  'Pit Setpoint',
                  liveState.pitSetpoint.toString(),
                ),
                _buildDebugRow('Fan Speed', liveState.fanSpeedPercent),
                _buildDebugRow('Fan Auto', liveState.fanAuto.toString()),
                const Divider(color: Colors.white10, height: 16),
                _buildDebugRow(
                  'Keep Warm',
                  liveState.keepWarmEnabled.toString(),
                ),
                _buildDebugRow(
                  'Keep Warm SP',
                  liveState.keepWarmSetpoint.toString(),
                ),
                _buildDebugRow(
                  'Done Alarm',
                  liveState.doneAlarmEnabled.toString(),
                ),
                _buildDebugRow(
                  'Meat Done SP',
                  liveState.meatDoneSetpoint.toString(),
                ),
                _buildDebugRow(
                  'Meat Done Fan',
                  liveState.meatDoneFanDisabled.toString(),
                ),
                const Divider(color: Colors.white10, height: 16),
                _buildDebugRow('Pit Offset', liveState.pitOffset.toString()),
                _buildDebugRow('Meat Offset', liveState.meatOffset.toString()),
                _buildDebugRow('Kp', liveState.kp.toString()),
                _buildDebugRow('Ki', liveState.ki.toString()),
                _buildDebugRow('Kd', liveState.kd.toString()),
                const Divider(color: Colors.white10, height: 16),
                _buildDebugRow('AP Mode', liveState.isApMode.toString()),
                _buildDebugRow(
                  'Autotune Act',
                  liveState.autotuneActive.toString(),
                ),
                _buildDebugRow(
                  'Autotune St',
                  liveState.autotuneState.toString(),
                ),
                _buildDebugRow('Timezone', liveState.timezone),
                const Divider(color: Colors.white10, height: 16),
                _buildDebugRow('SSID', liveState.ssid),
                _buildDebugRow('RSSI', liveState.rssi.toString()),
                _buildDebugRow('IP', liveState.ip),
                _buildDebugRow(
                  'Dev Time',
                  liveState.deviceTimestamp.toString(),
                ),
                _buildDebugRow(
                  'UTC Offset',
                  liveState.utcOffsetSeconds.toString(),
                ),
                _buildDebugRow('Connected', liveState.connected.toString()),
                _buildDebugRow(
                  'Last Rx',
                  liveState.lastReceivedAt.toIso8601String(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApModeNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SmokerColors.accentOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SmokerColors.accentOrange.withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: SmokerColors.accentOrange,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'AP Mode Active: Timezone and OTA are unavailable.',
              style: TextStyle(
                color: SmokerColors.accentOrange,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationCard(bool isConnected, LiveState liveState, {required bool pitDirty, required bool meatDirty}) {
    return SmokerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.thermostat, 'PROBE OFFSET', Colors.tealAccent),
          const SizedBox(height: 16),
          Text(
            'Current Reading: Meat ${liveState.meatTemp}°F | Pit ${liveState.pitTemp}°F',
            style: const TextStyle(
              fontSize: 12,
              color: SmokerColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPremiumInput(
                  controller: _meatOffsetController,
                  focusNode: _meatFocus,
                  label: 'Meat Offset',
                  isEnabled: isConnected,
                  isSigned: true,
                  isDirty: meatDirty,
                  onSubmitted: isConnected ? (_) => _sendCalibration() : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumInput(
                  controller: _pitOffsetController,
                  focusNode: _pitFocus,
                  label: 'Pit Offset',
                  isEnabled: isConnected,
                  isSigned: true,
                  isDirty: pitDirty,
                  onSubmitted: isConnected ? (_) => _sendCalibration() : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSaveButton(
            label: 'SAVE CALIBRATION',
            onPressed: isConnected ? _sendCalibration : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPidCard(bool isConnected, LiveState liveState, {required bool kpDirty, required bool kiDirty, required bool kdDirty}) {
    return SmokerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.tune, 'PID VALUES', Colors.tealAccent),
          const SizedBox(height: 8),
          const Text(
            'Advanced tuning for the fan controller.',
            style: TextStyle(fontSize: 12, color: SmokerColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPremiumInput(
                  controller: _kpController,
                  focusNode: _kpFocus,
                  label: 'Kp',
                  isEnabled: isConnected,
                  isDecimal: true,
                  isDirty: kpDirty,
                  onSubmitted: isConnected ? (_) => _sendPID() : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPremiumInput(
                  controller: _kiController,
                  focusNode: _kiFocus,
                  label: 'Ki',
                  isEnabled: isConnected,
                  isDecimal: true,
                  isDirty: kiDirty,
                  onSubmitted: isConnected ? (_) => _sendPID() : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPremiumInput(
                  controller: _kdController,
                  focusNode: _kdFocus,
                  label: 'Kd',
                  isEnabled: isConnected,
                  isDecimal: true,
                  isDirty: kdDirty,
                  onSubmitted: isConnected ? (_) => _sendPID() : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSaveButton(
            label: 'UPDATE PID',
            onPressed: isConnected ? _sendPID : null,
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text(
                'Advance Settings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8, bottom: 16),
              iconColor: Colors.white70,
              collapsedIconColor: Colors.white38,
              children: [
                _buildAutotuneSection(
                  isConnected,
                  liveState.autotuneActive,
                  liveState.autotuneState,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutotuneSection(
    bool isConnected,
    bool autotuneActive,
    int autotuneState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(
          Icons.auto_awesome,
          'AUTOTUNE (EXPERIMENTAL)',
          Colors.purpleAccent,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STATUS: ${autotuneActive ? "ACTIVE" : "IDLE"}',
              style: TextStyle(
                color: autotuneActive
                    ? SmokerColors.accentGreen
                    : SmokerColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            Text(
              'PHASE: $autotuneState / 4',
              style: const TextStyle(
                color: SmokerColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (autotuneActive)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: autotuneState / 4,
              backgroundColor: Colors.white10,
              color: Colors.purpleAccent,
              minHeight: 6,
            ),
          ),
        const SizedBox(height: 20),
        _buildSaveButton(
          label: autotuneActive ? 'STOP AUTOTUNE' : 'START AUTOTUNE',
          color: autotuneActive ? Colors.redAccent : SmokerColors.accentGreen,
          onPressed: isConnected
              ? () => _confirmAndStartAutotune(autotuneActive)
              : null,
        ),
      ],
    );
  }

  Widget _buildTimezoneCard(bool isConnected, bool isApMode, {required bool tzDirty}) {
    return SmokerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.schedule, 'TIMEZONE', Colors.tealAccent),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            width: double.maxFinite,
            controller: _tzController,
            enabled: isConnected && !isApMode,
            label: const Text(
              'Select Timezone',
              style: TextStyle(color: SmokerColors.textSecondary),
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 14),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              labelStyle: TextStyle(
                color: tzDirty ? SmokerColors.accentOrange : SmokerColors.textSecondary,
                fontWeight: tzDirty ? FontWeight.bold : FontWeight.normal,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: tzDirty ? SmokerColors.accentOrange : Colors.white.withValues(alpha: 0.1),
                  width: tzDirty ? 2 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: tzDirty ? SmokerColors.accentOrange : Colors.white.withValues(alpha: 0.1),
                  width: tzDirty ? 2 : 1,
                ),
              ),
            ),
            dropdownMenuEntries: _timezones.map(((String, String) tz) {
              return DropdownMenuEntry<String>(
                value: tz.$2,
                label: tz.$1,
                style: MenuItemButton.styleFrom(foregroundColor: Colors.white),
              );
            }).toList(),
            onSelected: (posix) {
              if (posix != null) {
                _selectedTzPosix = posix;
                final match = _timezones
                    .where((t) => t.$2 == posix)
                    .firstOrNull;
                _tzController.text = match?.$1 ?? posix;
              }
            },
          ),
          const SizedBox(height: 20),
          _buildSaveButton(
            label: 'UPDATE CLOCK',
            onPressed: (isConnected && !isApMode) ? _sendTimezone : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOtaCard(bool isConnected, bool isApMode) {
    return SmokerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            Icons.system_update_alt,
            'FIRMWARE',
            Colors.tealAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            'Keep your smoker device up to date with new features and fixes.',
            style: TextStyle(fontSize: 12, color: SmokerColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _buildSaveButton(
            label: 'CHECK FOR UPDATES',
            onPressed: (isConnected && !isApMode)
                ? () => context.push('/ota')
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool isEnabled,
    bool isSigned = false,
    bool isDecimal = false,
    bool isDirty = false,
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
      keyboardType: TextInputType.numberWithOptions(
        signed: isSigned,
        decimal: isDecimal,
      ),
      enabled: isEnabled,
      style: const TextStyle(
        fontSize: 18,
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
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildSaveButton({
    required String label,
    VoidCallback? onPressed,
    Color? color,
  }) {
    final effectiveColor = color ?? SmokerColors.accentBlue;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: onPressed != null ? effectiveColor : Colors.white10,
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

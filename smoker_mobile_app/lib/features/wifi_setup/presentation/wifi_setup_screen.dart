import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ossc/core/providers/core_providers.dart';
import 'package:ossc/features/wifi_setup/data/wifi_scan_provider.dart';
import '../../../shared/widgets/smoker_card.dart';
import '../../../shared/widgets/connection_banner.dart';
import '../../../app/theme/colors.dart';
import '../../../core/networking/device_session_manager.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../shared/widgets/wifi_status_indicator.dart';

class WifiSetupScreen extends ConsumerStatefulWidget {
  const WifiSetupScreen({super.key});

  @override
  ConsumerState<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends ConsumerState<WifiSetupScreen> {
  final _ssidController = TextEditingController();
  final _passController = TextEditingController();
  final _manualSsidController = TextEditingController();
  final _ipController = TextEditingController();
  final _gatewayController = TextEditingController();

  bool _useDhcp = true;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isApMode = ref.read(deviceStateProvider).isApMode;
      final scanState = ref.read(wifiScanProvider);
      // Scan on first load if we don't have results yet and we are in AP mode
      if (scanState.networks.isEmpty && isApMode) {
        _scanNetworks();
      }
    });
  }

  Future<void> _scanNetworks() async {
    final connectivityState = ref.read(connectivityProvider);
    final isWifiOff =
        (connectivityState.value?.isEmpty ?? true) ||
        connectivityState.value!.contains(ConnectivityResult.none);

    if (isWifiOff) {
      ref.read(wifiScanProvider.notifier).setNetworks([]);
      return;
    }

    ref.read(wifiScanProvider.notifier).setLoading(true);
    final manager = ref.read(deviceSessionManagerProvider);
    final transport = manager.transport;

    if (transport == null) {
      ref.read(wifiScanProvider.notifier).setLoading(false);
      return;
    }

    try {
      final nets = await manager.api.getNetworks(transport.httpBaseUrl);
      if (!mounted) return;
      ref.read(wifiScanProvider.notifier).setNetworks(nets);
    } catch (e) {
      if (mounted) {
        ref.read(wifiScanProvider.notifier).setLoading(false);
      }
    }
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    _manualSsidController.dispose();
    _ipController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool erase) async {
    setState(() => _isSubmitting = true);
    final manager = ref.read(deviceSessionManagerProvider);
    final transport = manager.transport;
    final networks = ref.read(wifiScanProvider).networks;

    if (transport == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final formData = <String, dynamic>{};

    if (erase) {
      formData['erase'] = 'true';
    } else {
      final ssid = networks.isNotEmpty && _ssidController.text.isNotEmpty
          ? _ssidController.text
          : _manualSsidController.text.trim();

      if (ssid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(
                'Please enter or select an SSID.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      formData['ssid'] = ssid;
      formData['pass'] = _passController.text;

      if (_useDhcp) {
        formData['usedhcp'] = 'true';
      } else {
        formData['usedhcp'] = 'false';
        formData['ip'] = _ipController.text.trim();
        formData['gateway'] = _gatewayController.text.trim();
      }
    }

    final success = await manager.api.setWifi(transport.httpBaseUrl, formData);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        manager.disconnect();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
            backgroundColor: SmokerColors.secondaryBg,
            title: const Text(
              'WiFi Updated',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Credentials sent. The device is now rebooting.\n\n'
              'Once it reconnects to your network, use Discovery to find it again.',
              style: TextStyle(color: SmokerColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  context.go('/discover');
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: SmokerColors.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send WiFi settings.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ResponsiveToolbarConfig.of(context);
    final connectivityState = ref.watch(connectivityProvider);
    final isWifiOff =
        (connectivityState.value?.isEmpty ?? true) ||
        connectivityState.value!.contains(ConnectivityResult.none);

    final liveState = ref.watch(deviceStateProvider);
    final ssidDirty = _ssidController.text != liveState.ssid;
    final manualSsidDirty = _manualSsidController.text.isNotEmpty;
    final passDirty = _passController.text.isNotEmpty;
    final ipDirty =
        _ipController.text.isNotEmpty && _ipController.text != liveState.ip;
    final gatewayDirty = _gatewayController.text.isNotEmpty;

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
                  Icon(Icons.wifi, color: Colors.white, size: config.mainIconSize),
                  SizedBox(width: config.spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'WI-FI SETUP',
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
                            'Network and connectivity settings'.toUpperCase(),
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
            if (ref.watch(connectionStatusProvider) !=
                    ConnectionStatus.connected ||
                !(ref
                        .watch(connectivityProvider)
                        .value
                        ?.contains(ConnectivityResult.wifi) ??
                    false))
              const ConnectionBanner(),
            Expanded(
              child: _isSubmitting
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: SmokerColors.accentBlue,
                          ),
                          SizedBox(height: 24),
                          Text(
                            'SUBMITTING SETTINGS...',
                            style: TextStyle(
                              color: SmokerColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildNetworkCard(
                          isWifiOff,
                          ssidDirty: ssidDirty,
                          manualSsidDirty: manualSsidDirty,
                          passDirty: passDirty,
                        ),
                        const SizedBox(height: 16),
                        _buildIpModeCard(
                          isWifiOff,
                          ipDirty: ipDirty,
                          gatewayDirty: gatewayDirty,
                        ),
                        const SizedBox(height: 32),
                        _buildSaveButton(
                          label: 'SAVE & APPLY SETTINGS',
                          onPressed: isWifiOff ? null : () => _submit(false),
                        ),
                        const SizedBox(height: 12),
                        _buildSaveButton(
                          label: 'ERASE WIFI CREDENTIALS',
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          textColor: Colors.redAccent,
                          onPressed: isWifiOff
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      backgroundColor: SmokerColors.secondaryBg,
                                      title: const Text(
                                        'Erase WiFi?',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        'This will clear saved credentials and reboot. You will need to reconnect in AP mode to configure it again.',
                                        style: TextStyle(
                                          color: SmokerColors.textSecondary,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text(
                                            'CANCEL',
                                            style: TextStyle(
                                              color: SmokerColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text(
                                            'ERASE',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    _submit(true);
                                  }
                                },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard(
    bool isWifiOff, {
    required bool ssidDirty,
    required bool manualSsidDirty,
    required bool passDirty,
  }) {
    final scanState = ref.watch(wifiScanProvider);
    final isApMode = ref.watch(deviceStateProvider).isApMode;

    return Opacity(
      opacity: isWifiOff ? 0.5 : 1.0,
      child: AbsorbPointer(
        absorbing: isWifiOff,
        child: SmokerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader(
                    Icons.wifi,
                    'SELECT NETWORK',
                    Colors.tealAccent,
                  ),
                  if (!scanState.isLoading && isApMode)
                    IconButton(
                      onPressed: _scanNetworks,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: SmokerColors.accentBlue,
                        size: 20,
                      ),
                      tooltip: 'Rescan Networks',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (scanState.isLoading)
                _buildScanningState()
              else ...[
                if (scanState.networks.isEmpty)
                  _buildManualSsidInput(
                    isWifiOff: isWifiOff,
                    manualSsidDirty: manualSsidDirty,
                  )
                else
                  _buildNetworkSelector(
                    context,
                    scanState.networks,
                    ssidDirty: ssidDirty,
                  ),
                const SizedBox(height: 20),
                _buildPremiumInput(
                  controller: _passController,
                  label: 'PASSWORD',
                  hint: '••••••••',
                  icon: Icons.key_rounded,
                  obscure: _obscurePassword,
                  isPassword: true,
                  isDirty: passDirty,
                  onSubmitted: isWifiOff ? null : (_) => _submit(false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanningState() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            height: 10,
            width: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: SmokerColors.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'SCANNING NEARBY NETWORKS...',
            style: TextStyle(
              color: SmokerColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'This may take up to 20 seconds.',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSsidInput({
    required bool isWifiOff,
    required bool manualSsidDirty,
  }) {
    final isApMode = ref.watch(deviceStateProvider).isApMode;

    return Column(
      children: [
        if (isApMode) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Could not find any nearby networks.',
                  style: TextStyle(
                    color: SmokerColors.accentOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _scanNetworks,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'RETRY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: SmokerColors.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _buildPremiumInput(
          controller: _manualSsidController,
          label: 'NETWORK NAME (SSID)',
          hint: 'Enter SSID manually',
          icon: Icons.wifi_find_rounded,
          isDirty: manualSsidDirty,
          onSubmitted: isWifiOff ? null : (_) => _submit(false),
        ),
      ],
    );
  }

  Widget _buildNetworkSelector(
    BuildContext context,
    List<Map<String, dynamic>> networks, {
    required bool ssidDirty,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showNetworkPicker(context, networks),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ssidDirty
                    ? SmokerColors.accentOrange
                    : Colors.white.withValues(alpha: 0.1),
                width: ssidDirty ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_lock_rounded,
                  color: ssidDirty
                      ? SmokerColors.accentOrange
                      : SmokerColors.accentBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT A NETWORK',
                        style: TextStyle(
                          color: ssidDirty
                              ? SmokerColors.accentOrange
                              : SmokerColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _ssidController.text.isEmpty
                            ? 'Tap to choose...'
                            : _ssidController.text,
                        style: TextStyle(
                          color: _ssidController.text.isEmpty
                              ? Colors.white24
                              : (ssidDirty
                                    ? SmokerColors.accentOrange
                                    : Colors.white),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: ssidDirty
                      ? SmokerColors.accentOrange
                      : SmokerColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showNetworkPicker(
    BuildContext context,
    List<Map<String, dynamic>> networks,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SmokerColors.primaryBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'CHOOSE A NETWORK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: networks.length + 1,
                  separatorBuilder: (c, i) =>
                      Divider(color: Colors.white.withValues(alpha: 0.05)),
                  itemBuilder: (c, i) {
                    if (i == networks.length) {
                      return ListTile(
                        leading: const Icon(
                          Icons.edit_note_rounded,
                          color: SmokerColors.accentOrange,
                        ),
                        title: const Text(
                          'Enter SSID Manually',
                          style: TextStyle(
                            color: SmokerColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(c);
                          _showManualSsidDialog();
                        },
                      );
                    }

                    final n = networks[i];
                    final ssid = n['ssid']?.toString() ?? '';
                    final rssi =
                        int.tryParse(n['rssi']?.toString() ?? '0') ?? 0;
                    final secure = n['secure'] == true;

                    return ListTile(
                      leading: _buildSignalIcon(rssi),
                      title: Text(
                        ssid,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: secure
                          ? const Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: Colors.white24,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _ssidController.text = ssid;
                        });
                        Navigator.pop(c);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignalIcon(int rssi) {
    IconData icon;
    Color color;

    if (rssi >= -55) {
      icon = Icons.wifi_rounded;
      color = SmokerColors.accentGreen;
    } else if (rssi >= -70) {
      icon = Icons.wifi_2_bar_rounded;
      color = SmokerColors.accentBlue;
    } else if (rssi >= -85) {
      icon = Icons.wifi_1_bar_rounded;
      color = SmokerColors.accentOrange;
    } else {
      icon = Icons.wifi_1_bar_rounded;
      color = SmokerColors.accentRed;
    }

    return Icon(icon, color: color, size: 20);
  }

  void _showManualSsidDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: SmokerColors.secondaryBg,
        title: const Text(
          'MANUAL SSID',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _manualSsidController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            setState(() {
              _ssidController.text = _manualSsidController.text.trim();
            });
            Navigator.pop(c);
          },
          decoration: InputDecoration(
            hintText: 'Enter Network Name',
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: SmokerColors.accentBlue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: SmokerColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _ssidController.text = _manualSsidController.text.trim();
              });
              Navigator.pop(c);
            },
            child: const Text(
              'USE THIS',
              style: TextStyle(
                color: SmokerColors.accentBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpModeCard(
    bool isWifiOff, {
    required bool ipDirty,
    required bool gatewayDirty,
  }) {
    return Opacity(
      opacity: isWifiOff ? 0.5 : 1.0,
      child: AbsorbPointer(
        absorbing: isWifiOff,
        child: SmokerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                Icons.lan_outlined,
                'IP CONFIGURATION',
                Colors.tealAccent,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Use DHCP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  _useDhcp
                      ? 'Router will assign IP automatically.'
                      : 'Fixed IP and Gateway required.',
                  style: const TextStyle(
                    color: SmokerColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                value: _useDhcp,
                activeThumbColor: SmokerColors.accentBlue,
                onChanged: (v) => setState(() => _useDhcp = v),
              ),
              if (!_useDhcp) ...[
                const SizedBox(height: 16),
                _buildPremiumInput(
                  controller: _ipController,
                  label: 'STATIC IP ADDRESS',
                  hint: '192.168.1.100',
                  icon: Icons.adjust_rounded,
                  isDirty: ipDirty,
                  onSubmitted: isWifiOff ? null : (_) => _submit(false),
                ),
                const SizedBox(height: 12),
                _buildPremiumInput(
                  controller: _gatewayController,
                  label: 'GATEWAY',
                  hint: '192.168.1.1',
                  icon: Icons.router_rounded,
                  isDirty: gatewayDirty,
                  onSubmitted: isWifiOff ? null : (_) => _submit(false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
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
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool isPassword = false,
    bool isDirty = false,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      onFieldSubmitted: onSubmitted,
      textInputAction: TextInputAction.done,
      obscureText: obscure,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDirty
              ? SmokerColors.accentOrange
              : SmokerColors.textSecondary,
          fontSize: 14,
          fontWeight: isDirty ? FontWeight.bold : FontWeight.normal,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.05)),
        prefixIcon: Icon(
          icon,
          color: isDirty
              ? SmokerColors.accentOrange
              : SmokerColors.textSecondary.withValues(alpha: 0.5),
          size: 18,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: isDirty
                      ? SmokerColors.accentOrange
                      : SmokerColors.textSecondary.withValues(alpha: 0.5),
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDirty
                ? SmokerColors.accentOrange
                : Colors.white.withValues(alpha: 0.1),
            width: isDirty ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDirty
                ? SmokerColors.accentOrange
                : Colors.white.withValues(alpha: 0.1),
            width: isDirty ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDirty
                ? SmokerColors.accentOrange
                : SmokerColors.accentBlue,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSaveButton({
    required String label,
    VoidCallback? onPressed,
    Color? color,
    Color? textColor,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

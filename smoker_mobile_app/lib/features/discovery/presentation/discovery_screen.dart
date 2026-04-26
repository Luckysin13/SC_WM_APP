import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../domain/discovery_service.dart';
import '../../../core/models/device_identity.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/smoker_card.dart';
import '../../../app/theme/colors.dart';

final discoveryProvider = FutureProvider.autoDispose<List<DeviceIdentity>>((
  ref,
) async {
  final connectivity =
      ref.watch(connectivityProvider).value ?? [ConnectivityResult.none];
  if (connectivity.contains(ConnectivityResult.none)) {
    return [];
  }
  final service = DiscoveryService();
  return await service.scanNetwork();
});

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    final service = DiscoveryService();
    final granted = await service.requestPermissions();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local network permission is required for scanning.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final connectivityState = ref.watch(connectivityProvider);
    final isWifiOff =
        !(connectivityState.value?.contains(ConnectivityResult.wifi) ?? false);

    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = shortestSide >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              centerTitle: false,
              title: Text(
                'DISCOVER',
                style: TextStyle(
                  fontSize: isLandscape && !isTablet ? 20 : 28,
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
              actions: [
                if (discoveryState.isRefreshing || discoveryState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          SmokerColors.accentOrange,
                        ),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: SmokerColors.textSecondary,
                    ),
                    onPressed: isWifiOff
                        ? null
                        : () => ref.invalidate(discoveryProvider),
                    tooltip: 'Scan for devices',
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    color: SmokerColors.textSecondary,
                  ),
                  onPressed: () => context.push('/troubleshoot'),
                ),
              ],
            ),
          ];
        },
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.2),
              radius: 1.2,
              colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
              stops: [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (isWifiOff)
                  Container(
                    width: double.infinity,
                    color: Colors.redAccent.withValues(alpha: 0.9),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'TURN ON WIFI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: discoveryState.when(
                    data: (devices) {
                      if (isWifiOff) {
                        return _buildWifiOffState();
                      }
                      if (devices.isEmpty) {
                        return _buildEmptyState(context, discoveryState);
                      }
                      return _buildDeviceList(context, devices);
                    },
                    loading: () => _buildLoadingState(),
                    error: (error, stack) =>
                        _buildEmptyState(context, discoveryState),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWifiOffState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: SmokerColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'WIFI IS DISABLED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Please enable WiFi in your device settings\nto scan for smoker controllers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SmokerColors.textSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                SmokerColors.accentOrange.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'SCANNING NETWORK...',
            style: TextStyle(
              color: SmokerColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AsyncValue<List<DeviceIdentity>> discoveryState,
  ) {
    final recent = ref.read(localCacheServiceProvider).getRecentDevices();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            size: 64,
                            color: SmokerColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'NO DEVICES FOUND',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      'Ensure the smoker controller is on the same WiFi network.\n\n',
                                ),
                                TextSpan(
                                  text: 'Wifi LED Status',
                                  style: TextStyle(
                                    color: Colors.transparent,
                                    shadows: [
                                      Shadow(
                                        color: SmokerColors.textSecondary,
                                        offset: Offset(0, -2),
                                      ),
                                    ],
                                    decoration: TextDecoration.underline,
                                    decorationColor: SmokerColors.textSecondary,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '\n  Blinking: Smoker Controller (AP Mode)'
                                      '\n  Solid: Your Network Setup (STA Mode)',
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: SmokerColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildActionButton(
                          label: 'RETRY SCAN',
                          isLoading:
                              discoveryState.isRefreshing || discoveryState.isLoading,
                          onPressed: () => ref.invalidate(discoveryProvider),
                          color: SmokerColors.accentBlue,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/discover/manual'),
                          child: const Text(
                            'ENTER IP MANUALLY',
                            style: TextStyle(
                              color: SmokerColors.accentBlue,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildRecentSection(context, recent),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList(BuildContext context, List<DeviceIdentity> devices) {
    final recent = ref.read(localCacheServiceProvider).getRecentDevices();
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Icon(
                Icons.wifi_tethering_rounded,
                size: 16,
                color: SmokerColors.accentGreen,
              ),
              const SizedBox(width: 8),
              const Text(
                'DISCOVERED DEVICES',
                style: TextStyle(
                  color: SmokerColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        ...devices.map(
          (device) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SmokerCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SmokerColors.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fireplace_rounded,
                    color: SmokerColors.accentOrange,
                  ),
                ),
                title: Text(
                  device.displayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                subtitle: Text(
                  device.host,
                  style: const TextStyle(
                    color: SmokerColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: SmokerColors.textSecondary,
                ),
                onTap: () => _connectToDevice(context, device),
              ),
            ),
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildRecentSection(context, recent),
        ],
        const SizedBox(height: 32),
        Center(
          child: TextButton(
            onPressed: () => context.go('/discover/manual'),
            child: const Text(
              'CAN\'T FIND YOUR DEVICE? ENTER IP MANUALLY',
              style: TextStyle(
                color: SmokerColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSection(
    BuildContext context,
    List<DeviceIdentity> recent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 16,
                color: SmokerColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'RECENT DEVICES',
                style: TextStyle(
                  color: SmokerColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        ...recent.map(
          (cached) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SmokerCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: const Icon(
                  Icons.history_rounded,
                  color: SmokerColors.textSecondary,
                  size: 20,
                ),
                title: Text(
                  cached.displayName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  cached.host,
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white24,
                    size: 18,
                  ),
                  onPressed: () async {
                    await ref
                        .read(localCacheServiceProvider)
                        .removeRecentDevice(cached.host);
                    setState(() {});
                  },
                ),
                onTap: () => _connectToDevice(context, cached),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    Color? color,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color ?? SmokerColors.accentBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Future<void> _connectToDevice(
    BuildContext context,
    DeviceIdentity device,
  ) async {
    final manager = ref.read(deviceSessionManagerProvider);
    final cache = ref.read(localCacheServiceProvider);

    await cache.saveLastDevice(device);
    manager.connect(device);
    if (!context.mounted) return;
    context.go('/dashboard');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/device_identity.dart';
import 'package:ossc/core/providers/core_providers.dart';
import '../../../shared/widgets/smoker_card.dart';
import '../../../app/theme/colors.dart';

class ManualIpScreen extends ConsumerStatefulWidget {
  const ManualIpScreen({super.key});

  @override
  ConsumerState<ManualIpScreen> createState() => _ManualIpScreenState();
}

class _ManualIpScreenState extends ConsumerState<ManualIpScreen> {
  final _ipController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _connect() async {
    if (_formKey.currentState!.validate()) {
      final ip = _ipController.text.trim();
      final device = DeviceIdentity(
        displayName: 'Manual Device',
        host: ip,
        port: 80,
        discoveredVia: 'Manual',
        lastSeenAt: DateTime.now(),
      );

      final manager = ref.read(deviceSessionManagerProvider);
      final cache = ref.read(localCacheServiceProvider);

      await cache.saveLastDevice(device);
      manager.connect(device);

      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'MANUAL CONNECT',
                style: TextStyle(
                  fontSize: 18,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ENTER DEVICE ADDRESS',
                      style: TextStyle(
                        color: SmokerColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SmokerCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _ipController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                labelText: 'IP ADDRESS OR HOSTNAME',
                                labelStyle: const TextStyle(
                                  color: SmokerColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                hintText: '192.168.4.1',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                prefixIcon: const Icon(
                                  Icons.lan_rounded,
                                  color: SmokerColors.accentBlue,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.03),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'IP cannot be empty';
                                }
                                // Relaxed validator to allow hostnames
                                return null;
                              },
                              onFieldSubmitted: (_) => _connect(),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Typical addresses: smoker.local or 192.168.4.1 (AP Mode)',
                              style: TextStyle(
                                color: Colors.white24,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: SmokerColors.accentBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _connect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CONNECT TO DEVICE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

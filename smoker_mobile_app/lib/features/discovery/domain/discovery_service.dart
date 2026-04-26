import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/models/device_identity.dart';

class DiscoveryService {
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // On Android 13+, NEARBY_WIFI_DEVICES is required for mDNS
      final nearby = await Permission.nearbyWifiDevices.request();
      if (nearby.isGranted) return true;

      // Fallback/Legacy: Location is often required for network scanning on older devices
      final location = await Permission.location.request();
      return location.isGranted;
    }
    return true; // iOS handles this via Info.plist and OS prompts
  }

  Future<List<DeviceIdentity>> scanNetwork({Duration timeout = const Duration(seconds: 10)}) async {
    final MDnsClient client = MDnsClient();
    final List<DeviceIdentity> discovered = [];

    // Probe AP mode default IP in parallel (mDNS is often blocked on AP networks without internet)
    final apModeFuture = _probeApMode();

    try {
      await client.start(interfacesFactory: (InternetAddressType type) async {
        return await NetworkInterface.list(
          includeLoopback: false,
          includeLinkLocal: true,
          type: type,
        );
      });
      
      await Future(() async {
        await for (final PtrResourceRecord ptr in client
            .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer('_http._tcp.local'))) {
          
          await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName))) {
            
            if (srv.target.toLowerCase().contains('smoker')) {
              await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target))) {
                
                if (!discovered.any((d) => d.host == ip.address.address)) {
                  discovered.add(DeviceIdentity(
                    displayName: 'Smoker Controller',
                    host: ip.address.address,
                    port: srv.port,
                    discoveredVia: 'mDNS',
                    lastSeenAt: DateTime.now(),
                  ));
                }
                break;
              }
            }
          }
        }
      }).timeout(timeout);
    } catch (e) {
      // Ignore mdns startup or timeout issues
    } finally {
      client.stop();
    }
    
    // Add AP mode device if it was found and isn't already discovered
    final apDevice = await apModeFuture;
    if (apDevice != null && !discovered.any((d) => d.host == apDevice.host)) {
      discovered.add(apDevice);
    }
    
    return discovered;
  }

  Future<DeviceIdentity?> _probeApMode() async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));
      final response = await dio.get('http://192.168.4.1/api/status');
      if (response.statusCode == 200) {
        return DeviceIdentity(
          displayName: 'Smoker Controller (AP Mode)',
          host: '192.168.4.1',
          port: 80,
          discoveredVia: 'AP Probe',
          lastSeenAt: DateTime.now(),
        );
      }
    } catch (_) {
      // Expected to fail when not in AP mode
    }
    return null;
  }
}

import 'package:dio/dio.dart';
import '../models/transport_profile.dart';

class TransportResolver {
  final Dio _dio;

  TransportResolver(this._dio);

  Future<TransportProfile> resolve(String host, int port) async {
    print('Probing transport for $host:$port...');
    // 1. Probe HTTPS Status Profile
    if (await _testConnection('https', host, port)) {
      print('Resolved transport: HTTPS');
      return TransportProfile(
        httpScheme: 'https',
        wsScheme: 'wss',
        host: host,
        port: port,
        websocketPath: '/ws',
        supportsTls: true,
        lastValidatedAt: DateTime.now(),
      );
    }
    
    // 2. Probe HTTP Status Profile
    if (await _testConnection('http', host, port)) {
      print('Resolved transport: HTTP');
      return TransportProfile(
        httpScheme: 'http',
        wsScheme: 'ws',
        host: host,
        port: port,
        websocketPath: '/ws',
        supportsTls: false,
        lastValidatedAt: DateTime.now(),
      );
    }

    print('Failed to resolve transport for $host:$port');
    throw Exception('Could not resolve transport over HTTP or HTTPS for $host:$port');
  }

  Future<bool> _testConnection(String scheme, String host, int port) async {
    try {
      final response = await _dio.get(
        '$scheme://$host:$port/api/status',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 404; // Consider 404 meaning the web server is there but missing route
    } catch (e) {
      return false;
    }
  }
}

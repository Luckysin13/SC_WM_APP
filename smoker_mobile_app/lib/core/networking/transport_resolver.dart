import 'package:dio/dio.dart';
import '../models/transport_profile.dart';
import '../constants/network_constants.dart';
import '../logging/app_logger.dart';

class TransportResolver {
  final Dio _dio;

  TransportResolver(this._dio);

  Future<TransportProfile> resolve(String host, int port) async {
    AppLogger.info('Probing transport for $host:$port...');
    // 1. Probe HTTPS Status Profile
    if (await _testConnection('https', host, port)) {
      AppLogger.info('Resolved transport: HTTPS');
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
      AppLogger.info('Resolved transport: HTTP');
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

    AppLogger.warning('Failed to resolve transport for $host:$port');
    throw Exception('Could not resolve transport over HTTP or HTTPS for $host:$port');
  }

  Future<bool> _testConnection(String scheme, String host, int port) async {
    try {
      final response = await _dio.get(
        '$scheme://$host:$port/api/status',
        options: Options(
          receiveTimeout: NetworkConstants.apiReceiveTimeout,
          sendTimeout: NetworkConstants.apiConnectTimeout,
        ),
      ).timeout(NetworkConstants.apiConnectTimeout);
      return response.statusCode == 200 || response.statusCode == 404; // Consider 404 meaning the web server is there but missing route
    } catch (e) {
      return false;
    }
  }
}

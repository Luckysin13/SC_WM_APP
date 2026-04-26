import 'package:dio/dio.dart';

class SmokerApiClient {
  final Dio _dio;

  SmokerApiClient(this._dio);

  /// Returns the list of nearby networks.
  /// Firmware response format: { "networks": [ { "ssid":"...", "rssi":-70, "secure":true }, ... ] }
  /// The scan runs synchronously on the device so we allow up to 20 seconds.
  Future<List<Map<String, dynamic>>> getNetworks(String baseUrl) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/networks',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 20), // scan takes ~4-8s on device
        ),
      );

      final data = response.data;

      // Firmware wraps the list: { "networks": [...] }
      if (data is Map<String, dynamic> && data['networks'] is List) {
        return List<Map<String, dynamic>>.from(data['networks'] as List);
      }

      // Fallback: bare array (some firmware versions may differ)
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> setWifi(String baseUrl, Map<String, dynamic> formData) async {
    try {
      final response = await _dio.post(
        '$baseUrl/',
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return true; // Device commonly drops connection on reboot after POST
    }
  }
}

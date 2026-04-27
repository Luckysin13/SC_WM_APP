abstract class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException([this.message = 'An unexpected error occurred', this.prefix]);

  @override
  String toString() {
    return prefix != null ? '$prefix: $message' : message;
  }
}

class NetworkException extends AppException {
  NetworkException([String message = 'A network error occurred.'])
      : super(message, 'Network Error');
}

class TimeoutException extends AppException {
  TimeoutException([String message = 'The connection timed out.'])
      : super(message, 'Timeout');
}

class DeviceConnectionException extends AppException {
  DeviceConnectionException([String message = 'Failed to connect to device.'])
      : super(message, 'Connection Error');
}

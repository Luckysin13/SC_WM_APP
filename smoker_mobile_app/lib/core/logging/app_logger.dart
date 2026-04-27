import 'dart:developer' as developer;

class AppLogger {
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'APP_INFO',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'APP_WARN',
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'APP_ERROR',
      level: 1000, // Severe level
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'APP_DEBUG',
      level: 500, // Debug level
      error: error,
      stackTrace: stackTrace,
    );
  }
}

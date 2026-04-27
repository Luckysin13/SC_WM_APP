class NetworkConstants {
  static const Duration apiConnectTimeout = Duration(seconds: 5);
  static const Duration apiReceiveTimeout = Duration(seconds: 5);
  static const Duration wifiScanReceiveTimeout = Duration(seconds: 20);

  static const Duration watchdogTimeout = Duration(seconds: 10);
  static const Duration pingInterval = Duration(seconds: 5);
  static const Duration otaRebootDelay = Duration(seconds: 20);
  
  static const int maxReconnectBackoffSeconds = 4;
}

class OtaState {
  // statusCode: 0=idle, 1=checking, 2=downloading, 3=flashing, 4=success, -1=failed
  final int statusCode;
  final String statusText; // e.g. "idle", "downloading"
  final String phase;      // e.g. "firmware", "littlefs"
  final String errorMessage;
  final int progressPercent;
  final String currentVersion;  // firmware key: otaCurrentVersion
  final String latestVersion;   // firmware key: otaAvailableVersion

  const OtaState({
    required this.statusCode,
    required this.statusText,
    required this.phase,
    required this.errorMessage,
    required this.progressPercent,
    required this.currentVersion,
    required this.latestVersion,
  });

  factory OtaState.initial() {
    return const OtaState(
      statusCode: 0,
      statusText: 'idle',
      phase: '',
      errorMessage: '',
      progressPercent: 0,
      currentVersion: '',
      latestVersion: '',
    );
  }

  bool get updateAvailable =>
      latestVersion.isNotEmpty && latestVersion != currentVersion;
  bool get isActive =>
      (statusCode > 0 && statusCode < 4) ||
      (phase.isNotEmpty && statusCode == 0);
  bool get isError => statusCode == -1 || statusText == 'failed';
  bool get isSuccess => statusCode == 4 || statusText == 'success';

  // Map firmware string status to int code
  static int _statusToCode(String s) {
    switch (s.toLowerCase()) {
      case 'idle':
        return 0;
      case 'checking':
        return 1;
      case 'update_available':
      case 'available':
        return 0; // Still idle but with update info
      case 'downloading':
        return 2;
      case 'installing':
      case 'flashing':
        return 3;
      case 'success':
        return 4;
      case 'failed':
        return -1;
      default:
        return 0;
    }
  }

  OtaState copyWithJson(Map<String, dynamic> json) {
    // Firmware sends otaStatus as a string: "idle", "downloading", etc.
    final rawStatus = json['otaStatus']?.toString();
    final newStatusText = rawStatus ?? statusText;
    final newStatusCode =
        rawStatus != null ? _statusToCode(rawStatus) : statusCode;

    // Only reset if we transition from a finished state (Success/Error/Idle at 0%)
    // to a new start, OR if specifically provided.
    final bool isStartingNew =
        (statusCode <= 0 || statusCode == 4) && newStatusCode == 1;

    final newProgress = (json['otaProgress'] as num?)?.toInt() ??
        (isStartingNew ? 0 : progressPercent);

    final newPhase = json['otaPhase']?.toString() ??
        ((isStartingNew || newStatusCode == 0) ? '' : phase);

    return OtaState(
      statusCode: newStatusCode,
      statusText: newStatusText,
      phase: newPhase,
      errorMessage: json['otaError']?.toString() ?? errorMessage,
      progressPercent: newProgress,
      // Firmware keys: otaCurrentVersion, otaAvailableVersion
      currentVersion: json['otaCurrentVersion']?.toString() ?? currentVersion,
      latestVersion: json['otaAvailableVersion']?.toString() ?? latestVersion,
    );
  }
}

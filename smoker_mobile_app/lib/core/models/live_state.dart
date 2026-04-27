class LiveState {
  final String meatTemp;             // boxValue0
  final String pitTemp;              // boxValue1
  final int pitSetpoint;             // boxValue2
  final String fanSpeedPercent;      // boxValue3
  final bool keepWarmEnabled;        // boxValue4
  final bool doneAlarmEnabled;       // boxValue6
  final int meatDoneSetpoint;        // boxValue8
  final int keepWarmSetpoint;        // boxValue9
  final bool meatDoneFanDisabled;    // meatDoneFanDisabled
  final int pitOffset;
  final int meatOffset;
  final double kp;
  final double ki;
  final double kd;
  final String timezone;
  final bool isApMode;               // isAP
  final bool autotuneActive;         // atActive
  final int autotuneState;           // atState
  final bool fanAuto;
  final String ssid;
  final int rssi;
  final String ip;
  final bool connected;
  final int deviceTimestamp;         // t
  final int utcOffsetSeconds;        // o
  final DateTime lastReceivedAt;

  const LiveState({
    required this.meatTemp,
    required this.pitTemp,
    required this.pitSetpoint,
    required this.fanSpeedPercent,
    required this.keepWarmEnabled,
    required this.doneAlarmEnabled,
    required this.meatDoneSetpoint,
    required this.keepWarmSetpoint,
    required this.meatDoneFanDisabled,
    required this.pitOffset,
    required this.meatOffset,
    required this.kp,
    required this.ki,
    required this.kd,
    required this.timezone,
    required this.isApMode,
    required this.autotuneActive,
    required this.autotuneState,
    required this.fanAuto,
    required this.ssid,
    required this.rssi,
    required this.ip,
    required this.connected,
    required this.deviceTimestamp,
    required this.utcOffsetSeconds,
    required this.lastReceivedAt,
  });

  factory LiveState.initial() {
    return LiveState(
      meatTemp: '---',
      pitTemp: '---',
      pitSetpoint: 225,
      fanSpeedPercent: '---',
      keepWarmEnabled: false,
      doneAlarmEnabled: false,
      meatDoneSetpoint: 195,
      keepWarmSetpoint: 160,
      meatDoneFanDisabled: false,
      pitOffset: 0,
      meatOffset: 0,
      kp: 10.0,
      ki: 0.05,
      kd: 2.0,
      timezone: 'CST6CDT,M3.2.0,M11.1.0',
      isApMode: false,
      autotuneActive: false,
      autotuneState: 0,
      fanAuto: true,
      ssid: '',
      rssi: 0,
      ip: '',
      connected: false,
      deviceTimestamp: 0,
      utcOffsetSeconds: 0,
      lastReceivedAt: DateTime.now(),
    );
  }

  LiveState copyWithJson(Map<String, dynamic> json) {
    final parsedFanSpeed = json['boxFan']?.toString() ?? json['boxValue3']?.toString() ?? fanSpeedPercent;
    final inferredFanDisabled = parsedFanSpeed.contains('Disabled') || parsedFanSpeed.contains('Meat Done');

    return LiveState(
      meatTemp: json['boxMeat']?.toString() ?? json['boxValue0']?.toString() ?? meatTemp,
      pitTemp: json['boxPit']?.toString() ?? json['boxValue1']?.toString() ?? pitTemp,
      pitSetpoint: _parseInt(json['boxValue2'], pitSetpoint),
      fanSpeedPercent: parsedFanSpeed,
      keepWarmEnabled: _parseBool(json['boxValue4'], keepWarmEnabled),
      doneAlarmEnabled: _parseBool(json['boxValue6'], doneAlarmEnabled),
      meatDoneSetpoint: _parseInt(json['boxValue8'], meatDoneSetpoint),
      keepWarmSetpoint: _parseInt(json['boxValue9'], keepWarmSetpoint),
      meatDoneFanDisabled: json.containsKey('meatDoneFanDisabled') 
          ? _parseBool(json['meatDoneFanDisabled'], false) 
          : inferredFanDisabled,
      pitOffset: _parseInt(json['pitOffset'], pitOffset),
      meatOffset: _parseInt(json['meatOffset'], meatOffset),
      kp: _parseDouble(json['kp'], kp),
      ki: _parseDouble(json['ki'], ki),
      kd: _parseDouble(json['kd'], kd),
      timezone: json['timezone']?.toString() ?? timezone,
      isApMode: _parseBool(json['isAP'], isApMode),
      autotuneActive: _parseBool(json['atActive'], autotuneActive),
      autotuneState: _parseInt(json['atState'], autotuneState),
      fanAuto: _parseBool(json['fanAuto'], fanAuto),
      ssid: json['ssid']?.toString() ?? ssid,
      rssi: _parseInt(json['rssi'], rssi),
      ip: json['ip']?.toString() ?? ip,
      connected: _parseBool(json['connected'], connected),
      deviceTimestamp: _parseInt(json['t'], deviceTimestamp),
      utcOffsetSeconds: _parseInt(json['o'], utcOffsetSeconds),
      lastReceivedAt: DateTime.now(),
    );
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _parseBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return fallback;
  }
}

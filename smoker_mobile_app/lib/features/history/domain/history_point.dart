class HistoryPoint {
  final int timestamp;
  final int pitTemp;
  final int meatTemp;
  final int setpoint;
  final int fanPercent;

  const HistoryPoint({
    required this.timestamp,
    required this.pitTemp,
    required this.meatTemp,
    required this.setpoint,
    required this.fanPercent,
  });

  factory HistoryPoint.fromJson(dynamic json) {
    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    if (json is List) {
      // Handle array format [t, p, m, s, f]
      return HistoryPoint(
        timestamp: json.isNotEmpty ? toInt(json[0]) : 0,
        pitTemp: json.length > 1 ? toInt(json[1]) : 0,
        meatTemp: json.length > 2 ? toInt(json[2]) : 0,
        setpoint: json.length > 3 ? toInt(json[3]) : 0,
        fanPercent: json.length > 4 ? toInt(json[4]) : 0,
      );
    }

    if (json is Map<String, dynamic>) {
      // Support multiple field name variations for robustness
      return HistoryPoint(
        timestamp: toInt(
          json['ts'] ?? json['t'] ?? json['timestamp'] ?? json['time'],
        ),
        pitTemp: toInt(json['p'] ?? json['pit'] ?? json['pitTemp']),
        meatTemp: toInt(json['m'] ?? json['meat'] ?? json['meatTemp']),
        setpoint: toInt(json['s'] ?? json['setpoint'] ?? json['sp']),
        fanPercent: toInt(json['f'] ?? json['fan'] ?? json['fanPercent']),
      );
    }

    return const HistoryPoint(
      timestamp: 0,
      pitTemp: 0,
      meatTemp: 0,
      setpoint: 0,
      fanPercent: 0,
    );
  }
}

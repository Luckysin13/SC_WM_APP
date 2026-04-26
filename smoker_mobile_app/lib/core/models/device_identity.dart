class DeviceIdentity {
  final String displayName;
  final String host;
  final int port;
  final String discoveredVia;
  final DateTime lastSeenAt;

  const DeviceIdentity({
    required this.displayName,
    required this.host,
    required this.port,
    required this.discoveredVia,
    required this.lastSeenAt,
  });

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'host': host,
    'port': port,
    'discoveredVia': discoveredVia,
    'lastSeenAt': lastSeenAt.toIso8601String(),
  };

  factory DeviceIdentity.fromJson(Map<String, dynamic> json) => DeviceIdentity(
    displayName: json['displayName'] as String,
    host: json['host'] as String,
    port: json['port'] as int,
    discoveredVia: json['discoveredVia'] as String,
    lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
  );
}

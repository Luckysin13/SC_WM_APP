class TransportProfile {
  final String httpScheme;
  final String wsScheme;
  final String host;
  final int port;
  final String websocketPath;
  final bool supportsTls;
  final DateTime lastValidatedAt;

  const TransportProfile({
    required this.httpScheme,
    required this.wsScheme,
    required this.host,
    required this.port,
    required this.websocketPath,
    required this.supportsTls,
    required this.lastValidatedAt,
  });

  Map<String, dynamic> toJson() => {
    'httpScheme': httpScheme,
    'wsScheme': wsScheme,
    'host': host,
    'port': port,
    'websocketPath': websocketPath,
    'supportsTls': supportsTls,
    'lastValidatedAt': lastValidatedAt.toIso8601String(),
  };

  factory TransportProfile.fromJson(Map<String, dynamic> json) => TransportProfile(
    httpScheme: json['httpScheme'] as String,
    wsScheme: json['wsScheme'] as String,
    host: json['host'] as String,
    port: json['port'] as int,
    websocketPath: json['websocketPath'] as String,
    supportsTls: json['supportsTls'] as bool,
    lastValidatedAt: DateTime.parse(json['lastValidatedAt'] as String),
  );

  String get httpBaseUrl => '$httpScheme://$host:$port';
  String get wsBaseUrl => '$wsScheme://$host:$port$websocketPath';
}

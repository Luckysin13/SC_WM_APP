import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class SmokerSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final void Function(Map<String, dynamic> json) onLiveStateReceived;
  final void Function(Map<String, dynamic> json) onHistoryPayloadReceived;
  final void Function(Map<String, dynamic> json) onOtaPayloadReceived;
  final void Function() onDisconnected;

  SmokerSocketClient({
    required this.onLiveStateReceived,
    required this.onHistoryPayloadReceived,
    required this.onOtaPayloadReceived,
    required this.onDisconnected,
  });

  Future<void> connect(String wsBaseUrl, String view) async {
    disconnect();
    await _connectAsync(wsBaseUrl, view);
  }

  /// Performs the async connection so that OS-level errors (e.g. errno 113
  /// "No route to host" during device reboot after OTA) are caught and routed
  /// through [onDisconnected] instead of crashing as Unhandled Exceptions.
  Future<void> _connectAsync(String wsBaseUrl, String view) async {
    final url = '$wsBaseUrl?view=$view';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Await the handshake — this is where OS-level errors surface.
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        (message) {
          if (message is String) {
            _handleMessage(message);
          }
        },
        onDone: () {
          onDisconnected();
        },
        onError: (error) {
          onDisconnected();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _channel = null;
      onDisconnected();
    }
  }

  void _handleMessage(String message) {
    try {
      final json = jsonDecode(message);
      if (json is Map<String, dynamic>) {
        final type = json['type'] as String?;
        // History packets
        if (type == 'history_point' ||
            type == 'history_meta' ||
            type == 'history_chunk' ||
            type == 'seed_history_ack') {
          onHistoryPayloadReceived(json);
          // Dedicated OTA info packet
        } else if (type == 'ota_info') {
          onOtaPayloadReceived(json);
        } else {
          // Regular live-state update — may also contain OTA fields
          onLiveStateReceived(json);
          if (json.containsKey('otaStatus') ||
              json.containsKey('otaProgress')) {
            onOtaPayloadReceived(json);
          }
        }
      }
    } catch (_) {
      // Ignored
    }
  }

  void sendCommand(String command) {
    if (_channel != null) {
      _channel!.sink.add(command);
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close(status.normalClosure);
    _channel = null;
  }
}

import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'transport_resolver.dart';
import 'smoker_socket_client.dart';
import 'smoker_api_client.dart';
import '../models/transport_profile.dart';
import '../models/live_state.dart';
import '../models/device_identity.dart';

enum ConnectionStatus { disconnected, connecting, connected, reconnecting }

class DeviceSessionManager {
  final TransportResolver _resolver;
  final SmokerApiClient _apiClient;
  late final SmokerSocketClient _socketClient;

  DeviceIdentity? _currentDevice;
  TransportProfile? _currentTransport;
  String _currentView = 'legacy';

  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _failedAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;
  Timer? _pingTimer;
  bool _isIntentionalDisconnect = false;

  final void Function(LiveState) onLiveStateUpdated;
  final void Function(Map<String, dynamic>) onHistoryPayloadReceived;
  final void Function(Map<String, dynamic>) onOtaPayloadReceived;
  final void Function(ConnectionStatus) onStatusChanged;
  final Future<List<ConnectivityResult>> Function() checkConnectivity;
  
  LiveState _latestState = LiveState.initial();

  final bool enableMockMode;
  Timer? _mockTimer;

  DeviceSessionManager({
    required Dio dio,
    required this.onLiveStateUpdated,
    required this.onHistoryPayloadReceived,
    required this.onOtaPayloadReceived,
    required this.onStatusChanged,
    required this.checkConnectivity,
    this.enableMockMode = false,
  })  : _resolver = TransportResolver(dio),
        _apiClient = SmokerApiClient(dio) {
    _socketClient = SmokerSocketClient(
      onLiveStateReceived: _handleLiveState,
      onHistoryPayloadReceived: onHistoryPayloadReceived,
      onOtaPayloadReceived: _handleOtaPayload,
      onDisconnected: _handleDisconnect,
    );
  }

  void _handleOtaPayload(Map<String, dynamic> json) {
    onOtaPayloadReceived(json);

    // If we get a success status, the device is about to reboot.
    // Transition to reboot mode automatically.
    final status = json['otaStatus']?.toString().toLowerCase();
    if (status == 'success') {
      enterOtaRebootMode();
    }
  }

  ConnectionStatus get status => _status;
  LiveState get latestState => _latestState;

  Future<void> connect(DeviceIdentity device, {String view = 'dashboard'}) async {
    _isIntentionalDisconnect = false;
    _currentDevice = device;
    _currentView = view;
    _failedAttempts = 0;
    _reconnectTimer?.cancel();
    
    // Clear stale state and transport for the new connection attempt
    _currentTransport = null;
    _latestState = LiveState.initial();
    onLiveStateUpdated(_latestState);
    
    await _attemptConnection();
  }

  Future<void> changeView(String view) async {
    if (_currentView == view) return;
    _currentView = view;
    
    if (_status == ConnectionStatus.connected && _currentTransport != null) {
      try {
        await _socketClient.connect(_currentTransport!.wsBaseUrl, _currentView);
        // Only send getValues if we're still connected after the view swap
        if (_status == ConnectionStatus.connected) {
          _socketClient.sendCommand('getValues');
          if (view == 'history') {
            _socketClient.sendCommand('getHistory');
          }
        }
      } catch (_) {
        // Connection failed during view swap — disconnect handler will retry
      }
    }
  }

  Future<void> _attemptConnection() async {
    if (_currentDevice == null) return;
    
    print('Attempting connection to ${_currentDevice?.host}...');
    _updateStatus(ConnectionStatus.connecting);

    if (enableMockMode) {
      _updateStatus(ConnectionStatus.connected);
      _mockTimer?.cancel();
      _mockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _handleLiveState({
          'boxValue0': (180 + (timer.tick % 20)).toString(),
          'boxValue1': (230 + (timer.tick % 5)).toString(),
          'connected': true,
        });
      });
      return;
    }

    final connectivity = await checkConnectivity();
    print('Current connectivity: $connectivity');
    if (connectivity.contains(ConnectivityResult.none)) {
      print('Connectivity reported as none, skipping connection attempt.');
      _scheduleReconnect();
      return;
    }

    try {
      _currentTransport ??= await _resolver.resolve(_currentDevice!.host, _currentDevice!.port);

      // Await the connection so that socket errors are caught here, not as uncaught Future errors
      await _socketClient.connect(_currentTransport!.wsBaseUrl, _currentView);
      _failedAttempts = 0;
      
      // Request full state once the socket handshake is confirmed ready
      _socketClient.sendCommand('getValues');
      if (_currentView == 'history') {
        _socketClient.sendCommand('getHistory');
      }
      
    } catch (e) {
      print('Connection attempt failed: $e');
      _currentTransport = null; // Invalidate cached transport
      _scheduleReconnect();
    }
  }

  /// Call this immediately after triggering an OTA update.
  /// Disconnects cleanly and schedules the first reconnect attempt after a
  /// 20-second delay (enough time for the ESP32 to flash + reboot).
  void enterOtaRebootMode() {
    _isIntentionalDisconnect = false;
    _currentTransport = null; // Force transport re-probe after reboot
    _updateStatus(ConnectionStatus.disconnected);
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _watchdogTimer?.cancel();
    _socketClient.disconnect();

    // Wait 20 s before first reconnect attempt — device needs time to flash and boot
    _reconnectTimer = Timer(const Duration(seconds: 20), () {
      _failedAttempts = 0;
      if (!_isIntentionalDisconnect) _attemptConnection();
    });
  }

  void _handleLiveState(Map<String, dynamic> json) {
    if (_status != ConnectionStatus.connected) {
      _updateStatus(ConnectionStatus.connected);
      _failedAttempts = 0;
      _startPingTimer();
    }
    
    _resetWatchdog();
    _latestState = _latestState.copyWithJson(json);
    onLiveStateUpdated(_latestState);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_status == ConnectionStatus.connected) {
        sendCommand('getValues');
      } else {
        timer.cancel();
      }
    });
  }

  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    if (_status == ConnectionStatus.connected) {
      _watchdogTimer = Timer(const Duration(seconds: 10), () {
        if (!_isIntentionalDisconnect) {
          _handleDisconnect();
        }
      });
    }
  }

  void _handleDisconnect() {
    if (_isIntentionalDisconnect) return;
    
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _updateStatus(ConnectionStatus.reconnecting);
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _watchdogTimer?.cancel();

    _failedAttempts++;
    final seconds = min(pow(2, _failedAttempts - 1).toInt(), 4);
    
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (!_isIntentionalDisconnect) {
        _attemptConnection();
      }
    });
  }

  void setSetpointCommand(int setpoint) {
      sendCommand('2b$setpoint');
  }

  void toggleFanMode(bool auto) {
      sendCommand(auto ? 'FanMode:auto' : 'FanMode:off');
  }

  void sendCommand(String command) {
    _socketClient.sendCommand(command);
  }

  void disconnect() {
    _isIntentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _mockTimer?.cancel();
    _watchdogTimer?.cancel();
    _pingTimer?.cancel();
    _socketClient.disconnect();
    
    // Clear transport and reset state on intentional disconnect
    _currentTransport = null;
    _latestState = LiveState.initial();
    onLiveStateUpdated(_latestState);
    
    _updateStatus(ConnectionStatus.disconnected);
  }

  void _updateStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      onStatusChanged(_status);
    }
  }

  SmokerApiClient get api => _apiClient;
  TransportProfile? get transport => _currentTransport;
}

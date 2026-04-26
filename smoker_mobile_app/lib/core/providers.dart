import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'networking/device_session_manager.dart';
import 'storage/local_cache_service.dart';
import 'models/live_state.dart';

import '../features/history/domain/history_assembler.dart';
import 'models/history_point.dart';
import 'models/ota_state.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize provider in main.dart');
});

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalCacheService(prefs);
});

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
      return HistoryNotifier();
    });

class HistoryState {
  final List<HistoryPoint> points;
  final bool isLoading;
  final double progress;

  HistoryState({
    required this.points,
    this.isLoading = false,
    this.progress = 0.0,
  });

  HistoryState copyWith({
    List<HistoryPoint>? points,
    bool? isLoading,
    double? progress,
  }) {
    return HistoryState(
      points: points ?? this.points,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(HistoryState(points: []));

  late final HistoryAssembler assembler = HistoryAssembler(
    onProgress: (p) {
      state = state.copyWith(isLoading: true, progress: p);
    },
    onComplete: (points) {
      final map = {for (var p in state.points) p.timestamp: p};
      for (var p in points) {
        map[p.timestamp] = p;
      }
      final sorted = map.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      state = state.copyWith(points: sorted, isLoading: false, progress: 1.0);
    },
  );

  void handlePayload(Map<String, dynamic> json) {
    if (json['type'] == 'history_point') {
      final point = HistoryPoint.fromJson(json);
      state = state.copyWith(points: [...state.points, point]);
    } else {
      if (json['type'] == 'history_meta') {
        state = state.copyWith(isLoading: true, progress: 0.0);
      }
      assembler.handlePayload(json);
    }
  }

  void setLoaded() {
    state = state.copyWith(isLoading: false);
  }

  void clear() {
    state = HistoryState(points: []);
  }
}

final wifiScanProvider =
    StateNotifierProvider<WifiScanNotifier, WifiScanState>((ref) {
  return WifiScanNotifier();
});

class WifiScanState {
  final List<Map<String, dynamic>> networks;
  final bool isLoading;

  WifiScanState({this.networks = const [], this.isLoading = false});

  WifiScanState copyWith({List<Map<String, dynamic>>? networks, bool? isLoading}) {
    return WifiScanState(
      networks: networks ?? this.networks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WifiScanNotifier extends StateNotifier<WifiScanState> {
  WifiScanNotifier() : super(WifiScanState());

  void setNetworks(List<Map<String, dynamic>> nets) {
    state = state.copyWith(networks: nets, isLoading: false);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

final otaProvider = StateProvider<OtaState>((ref) => OtaState.initial());

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final deviceSessionManagerProvider = Provider<DeviceSessionManager>((ref) {
  final dio = ref.watch(dioProvider);

  final manager = DeviceSessionManager(
    dio: dio,
    enableMockMode: false,
    checkConnectivity: () async {
      return await Connectivity().checkConnectivity();
    },
    onLiveStateUpdated: (state) {
      ref.read(deviceStateProvider.notifier).state = state;
    },
    onHistoryPayloadReceived: (payload) {
      ref.read(historyProvider.notifier).handlePayload(payload);
    },
    onOtaPayloadReceived: (payload) {
      ref
          .read(otaProvider.notifier)
          .update((state) => state.copyWithJson(payload));
    },
    onStatusChanged: (status) {
      ref.read(connectionStatusProvider.notifier).state = status;
    },
  );

  return manager;
});

final connectionStatusProvider = StateProvider<ConnectionStatus>((ref) {
  return ConnectionStatus.disconnected;
});

final deviceStateProvider = StateProvider<LiveState>((ref) {
  return LiveState.initial();
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

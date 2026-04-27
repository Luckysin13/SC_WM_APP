import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../networking/device_session_manager.dart';
import '../storage/local_cache_service.dart';
import '../models/live_state.dart';

import '../../features/history/data/history_provider.dart';
import '../../features/ota/data/ota_provider.dart';
import '../logging/app_logger.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize provider in main.dart');
});

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalCacheService(prefs);
});


final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.debug('HTTP Request: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.debug('HTTP Response: ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        AppLogger.error('HTTP Error: ${e.message} on ${e.requestOptions.uri}');
        return handler.next(e);
      },
    ),
  );
  return dio;
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
    onStatusChanged: (status) {
      ref.read(connectionStatusProvider.notifier).state = status;
    },
  );

  manager.messageStream.listen((payload) {
    final type = payload['type'] as String?;
    
    if (type == 'history_point' ||
        type == 'history_meta' ||
        type == 'history_chunk' ||
        type == 'seed_history_ack') {
      ref.read(historyProvider.notifier).handlePayload(payload);
    }
    
    if (type == 'ota_info' || payload.containsKey('otaStatus') || payload.containsKey('otaProgress')) {
      ref.read(otaProvider.notifier).update((state) => state.copyWithJson(payload));
    }
  });

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

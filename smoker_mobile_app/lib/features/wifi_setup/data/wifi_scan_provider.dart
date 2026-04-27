import 'package:flutter_riverpod/flutter_riverpod.dart';

final wifiScanProvider = StateNotifierProvider<WifiScanNotifier, WifiScanState>((ref) {
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

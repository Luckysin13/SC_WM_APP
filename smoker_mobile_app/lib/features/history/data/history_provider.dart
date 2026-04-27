import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/history_assembler.dart';
import 'package:ossc/features/history/domain/history_point.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
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

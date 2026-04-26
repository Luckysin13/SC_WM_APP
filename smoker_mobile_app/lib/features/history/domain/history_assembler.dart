import '../../../core/models/history_point.dart';

class HistoryAssembler {
  int? _currentTransferId;
  int _totalChunks = 0;
  final Map<int, List<HistoryPoint>> _chunks = {};
  
  final void Function(double) onProgress;
  final void Function(List<HistoryPoint>) onComplete;

  HistoryAssembler({required this.onProgress, required this.onComplete});

  void handlePayload(Map<String, dynamic> json) {
    if (json['type'] == 'history_meta') {
      _currentTransferId = json['transferId'] as int?;
      _totalChunks = json['chunks'] as int? ?? 0;
      _chunks.clear();
      onProgress(0.0);
    } else if (json['type'] == 'history_chunk') {
      final transferId = json['transferId'] as int?;
      if (transferId != _currentTransferId) return;

      final index = json['index'] as int?;
      final isFinal = json['final'] == true || json['final'] == 1;
      final rawData = json['data'] as List<dynamic>? ?? [];

      if (index != null) {
        _chunks[index] = rawData
            .whereType<Map<String, dynamic>>()
            .map((e) => HistoryPoint.fromJson(e))
            .toList();
        
        if (_totalChunks > 0) {
          onProgress(_chunks.length / _totalChunks);
        }
      }

      if (isFinal || (_totalChunks > 0 && _chunks.length >= _totalChunks)) {
        _assembleAndEmit();
      }
    }
  }

  void _assembleAndEmit() {
    final sortedKeys = _chunks.keys.toList()..sort();
    final List<HistoryPoint> allPoints = [];
    for (var key in sortedKeys) {
      allPoints.addAll(_chunks[key]!);
    }
    
    // Sometimes there might be duplicates around boundaries if they send overlapping chunks, but we just trust the list
    onComplete(allPoints);
    _chunks.clear();
    _currentTransferId = null;
  }
}

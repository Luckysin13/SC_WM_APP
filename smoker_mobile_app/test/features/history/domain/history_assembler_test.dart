import 'package:flutter_test/flutter_test.dart';
import 'package:ossc/features/history/domain/history_assembler.dart';
import 'package:ossc/features/history/domain/history_point.dart';

void main() {
  group('HistoryAssembler', () {
    test('assembles multiple chunks correctly', () {
      bool onCompleteCalled = false;
      late List<HistoryPoint> assembledPoints;

      final assembler = HistoryAssembler(
        onProgress: (_) {},
        onComplete: (points) {
          onCompleteCalled = true;
          assembledPoints = points;
        },
      );

      // 1. Send meta
      assembler.handlePayload({
        'type': 'history_meta',
        'transferId': 123,
        'chunks': 2,
      });

      // 2. Send chunk 0
      assembler.handlePayload({
        'type': 'history_chunk',
        'transferId': 123,
        'index': 0,
        'data': [
          {'t': 1000, 'p': 200, 'm': 50, 's': 225, 'f': 100},
          {'t': 1005, 'p': 205, 'm': 55, 's': 225, 'f': 90},
        ],
        'final': false,
      });

      expect(onCompleteCalled, isFalse);

      // 3. Send chunk 1 (final)
      assembler.handlePayload({
        'type': 'history_chunk',
        'transferId': 123,
        'index': 1,
        'data': [
          {'t': 1010, 'p': 210, 'm': 60, 's': 225, 'f': 80},
        ],
        'final': true,
      });

      expect(onCompleteCalled, isTrue);
      expect(assembledPoints.length, 3);
      expect(assembledPoints[0].timestamp, 1000);
      expect(assembledPoints.last.timestamp, 1010);
    });

    test('ignores chunk with mismatched transferId', () {
        bool onCompleteCalled = false;
        final assembler = HistoryAssembler(
          onProgress: (_) {},
          onComplete: (_) {
            onCompleteCalled = true;
          },
        );

        assembler.handlePayload({
            'type': 'history_meta',
            'transferId': 123,
            'chunks': 1,
        });

        assembler.handlePayload({
            'type': 'history_chunk',
            'transferId': 999, // Mismatch
            'index': 0,
            'data': [],
            'final': true,
        });

        expect(onCompleteCalled, isFalse);
    });
  });
}

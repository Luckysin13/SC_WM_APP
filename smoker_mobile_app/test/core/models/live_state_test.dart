import 'package:flutter_test/flutter_test.dart';
import 'package:ossc/core/models/live_state.dart';

void main() {
  group('LiveState', () {
    test('initial state has default values', () {
      final state = LiveState.initial();
      expect(state.pitSetpoint, 225);
      expect(state.meatTemp, '---');
      expect(state.connected, false);
    });

    test('copyWithJson parses complete device update', () {
      final state = LiveState.initial();
      final update = {
        'boxValue0': '120',
        'boxValue1': '250',
        'boxValue2': 275,
        'boxValue3': '100',
        'boxValue4': true,
        'boxValue6': false,
        'boxValue8': 200,
        'boxValue9': 150,
        'keepWarmEnabled': true,
        'isAP': false,
        't': 1690000000,
        'connected': true,
      };

      final newState = state.copyWithJson(update);
      expect(newState.meatTemp, '120');
      expect(newState.pitTemp, '250');
      expect(newState.pitSetpoint, 275);
      expect(newState.fanSpeedPercent, '100');
      expect(newState.keepWarmEnabled, true);
      expect(newState.isApMode, false);
      expect(newState.connected, true);
    });
  });
}

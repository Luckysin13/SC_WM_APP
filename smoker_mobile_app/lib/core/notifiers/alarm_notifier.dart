import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_state.dart';
import 'package:ossc/core/providers/core_providers.dart';
import '../../shared/services/notification_service.dart';

class AlarmNotifier extends StateNotifier<void> {
  final Ref _ref;
  bool _meatAlarmSent = false;
  double? _lastSetpoint;

  AlarmNotifier(this._ref) : super(null) {
    // Listen to device state changes
    _ref.listen<LiveState>(deviceStateProvider, (previous, next) {
      _checkAlarm(next);
    });
  }

  void _checkAlarm(LiveState state) {
    final currentTemp = double.tryParse(state.meatTemp);
    final targetTemp = state.meatDoneSetpoint.toDouble();

    // Reset alarm if setpoint changes or meat temp drops (new cook)
    if (_lastSetpoint != targetTemp) {
      _meatAlarmSent = false;
      _lastSetpoint = targetTemp;
    }

    if (state.doneAlarmEnabled && currentTemp != null && currentTemp >= targetTemp && targetTemp > 0) {
      if (!_meatAlarmSent) {
        NotificationService().showMeatDoneNotification(
          currentTemp: currentTemp,
          targetTemp: targetTemp,
        );
        _meatAlarmSent = true;
      }
    } else if (currentTemp != null && currentTemp < targetTemp - 1) {
      _meatAlarmSent = false;
    }
  }
}

final alarmProvider = StateNotifierProvider<AlarmNotifier, void>((ref) {
  return AlarmNotifier(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ossc/features/ota/domain/ota_state.dart';

final otaProvider = StateProvider<OtaState>((ref) => OtaState.initial());

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/version.dart';

final versionInfoProvider = FutureProvider<String>((ref) async {
  return appVersion;
});


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/version_provider.dart';

class VersionDisplay extends ConsumerWidget {
  final Color? color;
  final double fontSize;

  const VersionDisplay({
    super.key,
    this.color = Colors.white24,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(versionInfoProvider);
    return versionAsync.when(
      data: (version) => Text(
        'v$version',
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

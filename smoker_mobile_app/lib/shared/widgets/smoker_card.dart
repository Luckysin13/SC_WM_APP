import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';

class SmokerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;

  const SmokerCard({
    super.key,
    required this.child,
    this.padding,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: SmokerColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SmokerColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient top border
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    gradientColors ??
                    [
                      SmokerColors.accentBlue,
                      SmokerColors.accentCyan,
                      SmokerColors.accentGreen,
                    ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(padding: padding ?? const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }
}

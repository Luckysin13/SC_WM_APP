import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import 'smoker_card.dart';

class TempCard extends StatelessWidget {
  final String title;
  final String tempDisplay;
  final bool isDone;
  final TextStyle? labelStyle;

  const TempCard({
    super.key,
    required this.title,
    required this.tempDisplay,
    this.isDone = false,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final hasProbe =
        tempDisplay != '---' &&
        tempDisplay != '--' &&
        tempDisplay != 'No Probe';

    final effectiveLabelStyle =
        labelStyle ??
        const TextStyle(
          fontSize: 22,
          color: SmokerColors.textSecondary,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
        );

    return Semantics(
      label: isDone
          ? '$title is done at $tempDisplay degrees Fahrenheit'
          : '$title is $tempDisplay degrees Fahrenheit',
      child: ExcludeSemantics(
        child: SmokerCard(
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title.toUpperCase(), style: effectiveLabelStyle),
                    if (isDone) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: SmokerColors.accentGreen,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hasProbe ? '$tempDisplay°F' : '--°F',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

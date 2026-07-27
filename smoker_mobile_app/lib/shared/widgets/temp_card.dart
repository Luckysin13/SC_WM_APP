import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import 'smoker_card.dart';

class TempCard extends StatelessWidget {
  final String title;
  final String tempDisplay;
  final bool isDone;
  final bool showAlarmBell;
  final TextStyle? labelStyle;
  final double? valueFontSize;

  const TempCard({
    super.key,
    required this.title,
    required this.tempDisplay,
    this.isDone = false,
    this.showAlarmBell = false,
    this.labelStyle,
    this.valueFontSize,
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
          : (showAlarmBell
              ? '$title alarm active, current temp $tempDisplay degrees Fahrenheit'
              : '$title is $tempDisplay degrees Fahrenheit'),
      child: ExcludeSemantics(
        child: SmokerCard(
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showAlarmBell && !isDone) ...[
                      Icon(
                        Icons.notifications_active_rounded,
                        color: SmokerColors.accentGreen,
                        size: (effectiveLabelStyle.fontSize ?? 22) * (14 / 22),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(title.toUpperCase(), style: effectiveLabelStyle),
                    if (isDone) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        color: SmokerColors.accentGreen,
                        size: (effectiveLabelStyle.fontSize ?? 22) * (14 / 22),
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
                  style: TextStyle(
                    fontSize: valueFontSize ?? 40,
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

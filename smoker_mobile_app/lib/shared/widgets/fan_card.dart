import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import 'smoker_card.dart';

class FanCard extends StatelessWidget {
  final String fanPercentDisplay;
  final bool isAuto;
  final bool enabled;
  final bool fanDisabledACK;
  final ValueChanged<bool> onToggleMode;
  final VoidCallback onAck;
  final TextStyle? labelStyle;

  const FanCard({
    super.key,
    required this.fanPercentDisplay,
    required this.isAuto,
    required this.enabled,
    required this.fanDisabledACK,
    required this.onToggleMode,
    required this.onAck,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = fanPercentDisplay != '---' && fanPercentDisplay != '--';
    final effectiveLabelStyle =
        labelStyle ??
        const TextStyle(
          fontSize: 22,
          color: SmokerColors.textSecondary,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
        );

    return SmokerCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'FAN SPEED'.toUpperCase(),
                    style: effectiveLabelStyle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Manual/Auto Toggle
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SmokerColors.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToggleButton(
                      label: 'AUTO',
                      isSelected: isAuto,
                      onPressed: enabled ? () => onToggleMode(true) : null,
                      selectedColor: SmokerColors.accentBlue,
                    ),
                    _ToggleButton(
                      label: 'OFF',
                      isSelected: !isAuto,
                      onPressed: enabled ? () => onToggleMode(false) : null,
                      selectedColor: SmokerColors.accentBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (fanDisabledACK)
            Column(
              children: [
                const Text(
                  'FAN DISABLED',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SmokerColors.accentOrange,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Target Reached',
                  style: TextStyle(fontSize: 12, color: SmokerColors.textMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: enabled ? onAck : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmokerColors.accentOrange,
                  ),
                  child: const Text('ACKNOWLEDGE'),
                ),
              ],
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    hasValue ? fanPercentDisplay : '--',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ' %',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;
  final Color selectedColor;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : SmokerColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

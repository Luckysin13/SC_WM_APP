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
  final double? valueFontSize;

  const FanCard({
    super.key,
    required this.fanPercentDisplay,
    required this.isAuto,
    required this.enabled,
    required this.fanDisabledACK,
    required this.onToggleMode,
    required this.onAck,
    this.labelStyle,
    this.valueFontSize,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('FAN SPEED'.toUpperCase(), style: effectiveLabelStyle),
          ),
          if (fanDisabledACK)
            Column(
              children: [
                const SizedBox(height: 12),
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
            Column(
              children: [
                const SizedBox(height: 12),
                _buildToggle(),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        hasValue ? fanPercentDisplay : '--',
                        style: TextStyle(
                          fontSize: valueFontSize ?? 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        ' %',
                        style: TextStyle(
                          fontSize: (valueFontSize ?? 40) * 0.6,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

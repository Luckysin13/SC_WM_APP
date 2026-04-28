import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import 'smoker_card.dart';

class SetpointEditor extends StatefulWidget {
  final int currentSetpoint;
  final bool enabled;
  final ValueChanged<int> onSet;
  final TextStyle? labelStyle;

  const SetpointEditor({
    super.key,
    required this.currentSetpoint,
    required this.enabled,
    required this.onSet,
    this.labelStyle,
  });

  @override
  State<SetpointEditor> createState() => _SetpointEditorState();
}

class _SetpointEditorState extends State<SetpointEditor> {
  bool _isEditing = false;
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentSetpoint.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant SetpointEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.currentSetpoint != widget.currentSetpoint) {
      _controller.text = widget.currentSetpoint.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _errorText = null;
        _isEditing = false;
      });
      return;
    }

    final val = int.tryParse(_controller.text);
    if (val == null || val < 145 || val > 450) {
      setState(() {
        _errorText = 'Range: 145-450°F';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isEditing = false;
    });

    widget.onSet(val);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabelStyle =
        widget.labelStyle ??
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
            child: Text(
              'PIT SETPOINT'.toUpperCase(),
              style: effectiveLabelStyle,
            ),
          ),
          const SizedBox(height: 16),
          if (!_isEditing)
            InkWell(
              onTap: widget.enabled
                  ? () {
                      setState(() {
                        _isEditing = true;
                        _errorText = null;
                        _controller.text = '';
                        _errorText = null;
                      });
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: SmokerColors.secondaryBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SmokerColors.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.currentSetpoint}°F',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit,
                      size: 18,
                      color: SmokerColors.textMuted,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        keyboardType: const TextInputType.numberWithOptions(),
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: SmokerColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          errorText: _errorText,
                          counterText: "",
                          suffixText: '°F',
                          suffixStyle: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                        maxLength: 3,
                        onSubmitted: (_) => _submit(),
                        onTapOutside: (event) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _isEditing = false;
                            _errorText = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('SET'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

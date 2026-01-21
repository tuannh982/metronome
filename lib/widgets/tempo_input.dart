import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Widget for inputting and adjusting tempo (BPM)
class TempoInput extends StatefulWidget {
  final int bpm;
  final ValueChanged<int> onChanged;

  const TempoInput({
    super.key,
    required this.bpm,
    required this.onChanged,
  });

  @override
  State<TempoInput> createState() => _TempoInputState();
}

class _TempoInputState extends State<TempoInput> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.bpm.toString());
  }

  @override
  void didUpdateWidget(TempoInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.bpm != widget.bpm) {
      _controller.text = widget.bpm.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adjustTempo(int delta) {
    final newBpm = (widget.bpm + delta).clamp(40, 300);
    widget.onChanged(newBpm);
    HapticFeedback.lightImpact();
  }

  void _submitTempo() {
    final value = int.tryParse(_controller.text);
    if (value != null) {
      widget.onChanged(value.clamp(40, 300));
    }
    _isEditing = false;
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BPM Display/Input
        GestureDetector(
          onTap: () {
            setState(() => _isEditing = true);
          },
          child: _isEditing
              ? SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: Theme.of(context).textTheme.displaySmall,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onSubmitted: (_) => _submitTempo(),
                    onEditingComplete: _submitTempo,
                  ),
                )
              : Text(
                  '${widget.bpm}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.textColor,
                      ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          'BPM',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Adjustment buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustButton(
              label: '-5',
              onPressed: () => _adjustTempo(-5),
            ),
            const SizedBox(width: 8),
            _AdjustButton(
              label: '-1',
              onPressed: () => _adjustTempo(-1),
            ),
            const SizedBox(width: 8),
            _AdjustButton(
              label: '+1',
              onPressed: () => _adjustTempo(1),
            ),
            const SizedBox(width: 8),
            _AdjustButton(
              label: '+5',
              onPressed: () => _adjustTempo(5),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Slider
        SizedBox(
          width: 300,
          child: Slider(
            value: widget.bpm.toDouble(),
            min: 40,
            max: 300,
            divisions: 260,
            onChanged: (value) {
              widget.onChanged(value.round());
            },
          ),
        ),
      ],
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AdjustButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 44,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

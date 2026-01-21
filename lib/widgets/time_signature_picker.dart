import 'package:flutter/material.dart';
import '../models/time_signature.dart';
import '../theme/app_theme.dart';

/// Widget for selecting time signature
class TimeSignaturePicker extends StatelessWidget {
  final TimeSignature selected;
  final ValueChanged<TimeSignature> onChanged;

  const TimeSignaturePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Time Signature',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final sig in TimeSignature.presets)
              _TimeSignatureChip(
                timeSignature: sig,
                isSelected: sig == selected,
                onTap: () => onChanged(sig),
              ),
            _CustomTimeSignatureButton(
              onSelected: onChanged,
              currentSelection: selected,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeSignatureChip extends StatelessWidget {
  final TimeSignature timeSignature;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSignatureChip({
    required this.timeSignature,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            timeSignature.display,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTimeSignatureButton extends StatelessWidget {
  final ValueChanged<TimeSignature> onSelected;
  final TimeSignature currentSelection;

  const _CustomTimeSignatureButton({
    required this.onSelected,
    required this.currentSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Check if current selection is a preset
    final isCustom = !TimeSignature.presets.contains(currentSelection);

    return Material(
      color: isCustom ? AppTheme.primaryColor : AppTheme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showCustomDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit,
                size: 18,
                color: isCustom ? Colors.white : AppTheme.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                isCustom ? currentSelection.display : 'Custom',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isCustom ? Colors.white : AppTheme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDialog(BuildContext context) {
    final numeratorController = TextEditingController(
      text: currentSelection.numerator.toString(),
    );
    final denominatorController = TextEditingController(
      text: currentSelection.denominator.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Custom Time Signature'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              child: TextField(
                controller: numeratorController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '4',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '/',
                style: TextStyle(fontSize: 24),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: denominatorController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '4',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final num = int.tryParse(numeratorController.text) ?? 4;
              final den = int.tryParse(denominatorController.text) ?? 4;
              final sig = TimeSignature(
                numerator: num.clamp(1, 16),
                denominator: den.clamp(2, 16),
              );
              onSelected(sig);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

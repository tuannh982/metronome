import 'package:flutter/material.dart';
import '../models/track.dart';
import '../theme/app_theme.dart';

class TrackSeeker extends StatelessWidget {
  final List<TrackDirective> flattenedBars;
  final int activeIndex;
  final Function(int) onSeek;

  const TrackSeeker({
    super.key,
    required this.flattenedBars,
    required this.activeIndex,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    if (flattenedBars.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: flattenedBars.length,
        itemBuilder: (context, index) {
          final directive = flattenedBars[index];
          final isActive = index == activeIndex;

          Color barColor;
          String label;

          if (directive is TimeDirective) {
            barColor = AppTheme.primaryColor;
            label = directive.timeSignature.display;
          } else if (directive is DelayDirective) {
            barColor = AppTheme.accentColor;
            label = '${directive.seconds}s';
          } else {
            barColor = AppTheme.textSecondary;
            label = '?';
          }

          return GestureDetector(
            onTap: () => onSeek(index),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? barColor : barColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: isActive
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: barColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : barColor,
                      ),
                    ),
                    if (directive is TimeDirective)
                      Text(
                        '${directive.tempo}',
                        style: TextStyle(
                          fontSize: 8,
                          color: (isActive ? Colors.white : barColor)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Play/pause and stop controls
class PlayControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const PlayControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop button
        Material(
          color: AppTheme.cardColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onStop,
            customBorder: const CircleBorder(),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: const Icon(
                Icons.stop_rounded,
                size: 32,
                color: AppTheme.textColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),

        // Play/Pause button (large)
        Material(
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.accentColor,
                ],
              ),
            ),
            child: InkWell(
              onTap: onPlayPause,
              customBorder: const CircleBorder(),
              child: Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(isPlaying),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Spacer to balance layout
        const SizedBox(width: 80),
      ],
    );
  }
}

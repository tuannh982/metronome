import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Play/pause and stop controls
class PlayControls extends StatelessWidget {
  final bool isPlaying;
  final bool isEnabled;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const PlayControls({
    super.key,
    required this.isPlaying,
    this.isEnabled = true,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isEnabled
                  ? [AppTheme.primaryColor, AppTheme.accentColor]
                  : [
                      AppTheme.textSecondary.withValues(alpha: 0.2),
                      AppTheme.textSecondary.withValues(alpha: 0.1),
                    ],
            ),
          ),
          child: InkWell(
            onTap: isEnabled ? (isPlaying ? onStop : onPlayPause) : null,
            customBorder: const CircleBorder(),
            child: Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

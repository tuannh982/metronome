import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Play/pause and stop controls
class PlayControls extends StatelessWidget {
  final bool isPlaying;
  final bool showStopButton;
  final bool isEnabled;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const PlayControls({
    super.key,
    required this.isPlaying,
    this.isEnabled = true,
    this.showStopButton = false,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStopButton) ...[
            _BuildButton(
              onTap: onStop,
              icon: Icons.stop_rounded,
              isEnabled: isEnabled,
              color: AppTheme.accentColor,
              size: 60, // Smaller stop button
            ),
            const SizedBox(width: 24),
          ],
          _BuildButton(
            onTap: showStopButton
                ? onPlayPause
                : (isPlaying ? onStop : onPlayPause),
            icon: showStopButton
                ? (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)
                : (isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
            isEnabled: isEnabled,
            color: AppTheme.primaryColor,
            size: 80, // Main play/pause button
          ),
        ],
      ),
    );
  }
}

class _BuildButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool isEnabled;
  final Color color;
  final double size;

  const _BuildButton({
    required this.onTap,
    required this.icon,
    required this.isEnabled,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: color.withValues(alpha: 0.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isEnabled
                ? [color, color.withValues(alpha: 0.8)]
                : [
                    AppTheme.textSecondary.withValues(alpha: 0.2),
                    AppTheme.textSecondary.withValues(alpha: 0.1),
                  ],
          ),
        ),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: size * 0.6,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

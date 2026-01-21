import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large beat counter display with animations
class BeatDisplay extends StatefulWidget {
  final int currentBeat;
  final int totalBeats;
  final bool isPlaying;
  final bool isDownbeat;

  const BeatDisplay({
    super.key,
    required this.currentBeat,
    required this.totalBeats,
    required this.isPlaying,
    required this.isDownbeat,
  });

  @override
  State<BeatDisplay> createState() => _BeatDisplayState();
}

class _BeatDisplayState extends State<BeatDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(BeatDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying &&
        widget.currentBeat != oldWidget.currentBeat) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beatColor = widget.isDownbeat
        ? AppTheme.beatHighlight
        : AppTheme.primaryColor;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.cardColor.withValues(alpha: 0.8),
            AppTheme.surfaceColor.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isPlaying
              ? beatColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: widget.isPlaying
            ? [
                BoxShadow(
                  color: beatColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current beat number
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isPlaying ? _scaleAnimation.value : 1.0,
                child: Opacity(
                  opacity: widget.isPlaying ? _opacityAnimation.value : 0.5,
                  child: Text(
                    widget.isPlaying ? '${widget.currentBeat}' : '-',
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: beatColor,
                      shadows: widget.isPlaying
                          ? [
                              Shadow(
                                color: beatColor.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Beat indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.totalBeats,
              (index) {
                final beat = index + 1;
                final isActive = widget.isPlaying && beat == widget.currentBeat;
                final isPast = widget.isPlaying && beat < widget.currentBeat;
                final isFirst = beat == 1;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: isActive ? 16 : 12,
                    height: isActive ? 16 : 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? (isFirst ? AppTheme.beatHighlight : AppTheme.primaryColor)
                          : isPast
                              ? AppTheme.primaryColor.withValues(alpha: 0.5)
                              : AppTheme.textSecondary.withValues(alpha: 0.3),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: (isFirst
                                        ? AppTheme.beatHighlight
                                        : AppTheme.primaryColor)
                                    .withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

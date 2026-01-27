import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large beat counter display with animations
class BeatDisplay extends StatefulWidget {
  final int currentBeat;
  final int totalBeats;
  final bool isPlaying;
  final bool isDownbeat;
  final String? nextTimeSignature;
  final int? nextTempo;
  final bool isDelaying;
  final double? remainingDelay;
  final double? totalDelay;
  final String? nextDelay;

  const BeatDisplay({
    super.key,
    required this.currentBeat,
    required this.totalBeats,
    required this.isPlaying,
    required this.isDownbeat,
    this.nextTimeSignature,
    this.nextTempo,
    this.isDelaying = false,
    this.remainingDelay,
    this.totalDelay,
    this.nextDelay,
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

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(BeatDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && widget.currentBeat != oldWidget.currentBeat) {
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
          // Current beat number or Delay countdown
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (widget.isDelaying) {
                final progress =
                    widget.totalDelay != null && widget.totalDelay! > 0
                    ? 1.0 - (widget.remainingDelay! / widget.totalDelay!)
                    : 0.0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Moving circle (progress)
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    // Big countdown number
                    Text(
                      widget.remainingDelay!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                );
              }

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
            children: List.generate(widget.totalBeats, (index) {
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
                        ? (isFirst
                              ? AppTheme.beatHighlight
                              : AppTheme.primaryColor)
                        : isPast
                        ? AppTheme.primaryColor.withValues(alpha: 0.5)
                        : AppTheme.textSecondary.withValues(alpha: 0.3),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color:
                                  (isFirst
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
            }),
          ),

          if (widget.nextTimeSignature != null || widget.nextDelay != null) ...[
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (widget.nextDelay != null)
                    Text(
                      widget.nextDelay!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        height: 1.1,
                      ),
                    )
                  else ...[
                    Text(
                      widget.nextTimeSignature ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        height: 1.1,
                      ),
                    ),
                    if (widget.nextTempo != null)
                      Text(
                        '${widget.nextTempo}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          height: 1.1,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

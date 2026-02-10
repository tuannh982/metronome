import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../providers/metronome_provider.dart';
import '../models/track.dart';
import '../widgets/beat_display.dart';
import '../widgets/play_controls.dart';
import '../theme/app_theme.dart';
import 'simple_mode_screen.dart';
import 'complex_mode_screen.dart';

/// Main home screen with mode switching and beat display
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FocusNode _homeFocusNode;

  @override
  void initState() {
    super.initState();
    _homeFocusNode = FocusNode(debugLabel: 'HomeScreen');
    // Initialize provider and check for deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MetronomeProvider>();
      // Request focus for the keyboard listener
      _homeFocusNode.requestFocus();

      provider.init().then((_) {
        // Handle deep links (web only)
        final uri = Uri.base;
        if (uri.queryParameters.containsKey('mode') &&
            uri.queryParameters['mode'] == 'complex' &&
            uri.queryParameters.containsKey('code')) {
          try {
            final encoded = uri.queryParameters['code']!;
            final decoded = utf8.decode(base64Url.decode(encoded));
            provider.setMode(AppMode.complex);
            provider.updateDslText(decoded);
          } catch (e) {
            debugPrint('Error parsing deep link: $e');
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _homeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MetronomeProvider>(
      builder: (context, provider, child) {
        if (!provider.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Focus(
          focusNode: _homeFocusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.space &&
                event is KeyDownEvent) {
              // Check if track editor (or any text input) is focused
              final focused = FocusManager.instance.primaryFocus;
              if (focused != null) {
                // Check for debug label we set
                if (focused.debugLabel == 'TrackEditor') {
                  return KeyEventResult.ignored;
                }
                // Check if it's an editable text widget (fallback)
                if (focused.context?.widget is EditableText ||
                    focused.descendants.any(
                      (n) => n.context?.widget is EditableText,
                    )) {
                  return KeyEventResult.ignored;
                }
              }

              if (provider.mode == AppMode.simple) {
                // In simple mode, play/stop
                if (provider.isPlaying) {
                  provider.stop();
                } else {
                  provider.play();
                }
              } else {
                // In complex mode, play/pause (toggle)
                provider.toggle();
              }
              return KeyEventResult.handled;
            }
            // 'T' key for tap tempo in simple mode (only when not playing)
            if (event.logicalKey == LogicalKeyboardKey.keyT &&
                event is KeyDownEvent) {
              // Skip if a text input is focused
              final tapFocused = FocusManager.instance.primaryFocus;
              if (tapFocused != null) {
                if (tapFocused.debugLabel == 'TrackEditor') {
                  return KeyEventResult.ignored;
                }
                if (tapFocused.context?.widget is EditableText ||
                    tapFocused.descendants.any(
                      (n) => n.context?.widget is EditableText,
                    )) {
                  return KeyEventResult.ignored;
                }
              }

              if (provider.mode == AppMode.simple && !provider.isPlaying) {
                provider.tapTempo();
                return KeyEventResult.handled;
              }
            }

            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: () {
              // Ensure focus returns to the screen when clicking empty space
              if (!_homeFocusNode.hasFocus) {
                _homeFocusNode.requestFocus();
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    // Main content area
                    Expanded(
                      child: Column(
                        children: [
                          // App bar with mode toggle
                          _buildAppBar(context, provider),

                          // Mode content
                          Expanded(
                            child: provider.mode == AppMode.simple
                                ? const SimpleModeScreen()
                                : const ComplexModeScreen(),
                          ),

                          // Play controls
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: PlayControls(
                              isPlaying: provider.isPlaying,
                              isEnabled: provider.canPlay,
                              onPlayPause: provider.toggle,
                              onStop: provider.stop,
                              showStopButton: provider.mode == AppMode.complex,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Beat display (right side)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: BeatDisplay(
                        currentBeat: provider.state.currentBeat,
                        totalBeats: provider.state.timeSignature.numerator,
                        isPlaying: provider.isPlaying,
                        isDownbeat: provider.state.isDownbeat,
                        nextTimeSignature:
                            provider.nextDirective is TimeDirective
                            ? (provider.nextDirective as TimeDirective)
                                  .timeSignature
                                  .display
                            : null,
                        nextTempo: provider.nextDirective is TimeDirective
                            ? (provider.nextDirective as TimeDirective).tempo
                            : null,
                        nextDelay: provider.nextDirective is DelayDirective
                            ? 'Delay\n${(provider.nextDirective as DelayDirective).seconds}s'
                            : null,
                        isDelaying: provider.playbackState.isDelaying,
                        remainingDelay: provider.remainingDelay,
                        totalDelay: provider.totalDelay,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, MetronomeProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // App title
          const Text(
            'Metronome',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),

          const Spacer(),

          // Mode toggle
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeTab(
                  label: 'Simple',
                  isSelected: provider.mode == AppMode.simple,
                  onTap: () => provider.setMode(AppMode.simple),
                ),
                _ModeTab(
                  label: 'Complex',
                  isSelected: provider.mode == AppMode.complex,
                  onTap: () => provider.setMode(AppMode.complex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

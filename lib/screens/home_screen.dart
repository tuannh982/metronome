import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/metronome_provider.dart';
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
  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetronomeProvider>().init();
    });
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

        return Scaffold(
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
                  ),
                ),
              ],
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
            '🎵 Metronome',
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
                  label: 'Liveset',
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../providers/metronome_provider.dart';
import '../theme/app_theme.dart';

/// Collapsible panel containing YouTube player and offset controls
class YoutubeVideoPanel extends StatefulWidget {
  const YoutubeVideoPanel({super.key});

  @override
  State<YoutubeVideoPanel> createState() => _YoutubeVideoPanelState();
}

class _YoutubeVideoPanelState extends State<YoutubeVideoPanel> {
  YoutubePlayerController? _ytController;
  String? _loadedVideoId;
  MetronomeProvider? _provider;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _songOffsetController = TextEditingController(text: '0.0');
  final TextEditingController _finetuneController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _provider = context.read<MetronomeProvider>();
    _provider!.onVideoSync = _handleVideoSync;
  }

  @override
  void dispose() {
    if (_provider?.onVideoSync == _handleVideoSync) {
      _provider?.onVideoSync = null;
    }
    _ytController?.close();
    _urlController.dispose();
    _songOffsetController.dispose();
    _finetuneController.dispose();
    super.dispose();
  }

  void _handleVideoSync(VideoSyncEvent event) {
    final controller = _ytController;
    if (controller == null) return;

    switch (event) {
      case VideoSyncPlay(:final seekToSeconds):
        controller.seekTo(seconds: seekToSeconds, allowSeekAhead: true);
        controller.playVideo();
      case VideoSyncPause():
        controller.pauseVideo();
      case VideoSyncStop(:final seekToSeconds):
        controller.pauseVideo();
        controller.seekTo(seconds: seekToSeconds, allowSeekAhead: true);
      case VideoSyncSeek(:final seekToSeconds):
        controller.seekTo(seconds: seekToSeconds, allowSeekAhead: true);
        controller.playVideo();
    }
  }

  void _loadVideo(MetronomeProvider provider) {
    final url = _urlController.text.trim();
    provider.setYoutubeUrl(url);

    final videoId = provider.youtubeVideoId;
    if (videoId == null) return;

    // Close old controller before creating new one
    _ytController?.close();
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        enableKeyboard: false,
      ),
    );
    _loadedVideoId = videoId;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MetronomeProvider>(
      builder: (context, provider, child) {
        if (!provider.isVideoPanelVisible) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // URL input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Paste YouTube URL...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _loadVideo(provider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    tooltip: 'Load video',
                    onPressed: () => _loadVideo(provider),
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // YouTube player — use ValueKey to force rebuild on video change
              if (_ytController != null && _loadedVideoId != null)
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final videoWidth = (screenWidth * 0.8).clamp(0.0, 360.0);
                      return SizedBox(
                        width: videoWidth,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: YoutubePlayer(
                            key: ValueKey(_loadedVideoId),
                            controller: _ytController!,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // Sync offset controls
              const Text(
                'TRACK SYNC',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Song start offset
                  const Text(
                    'Video start:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _songOffsetController,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textColor,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        suffixText: 's',
                        suffixStyle: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed != null) {
                          provider.setSongStartOffset(parsed);
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Fine-tune offset
                  const Text(
                    'Fine-tune:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _finetuneController,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textColor,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: false,
                      ),
                      decoration: const InputDecoration(
                        suffixText: 'ms',
                        suffixStyle: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) {
                          provider.setFinetuneOffset(parsed / 1000.0);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

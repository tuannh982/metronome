import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:uuid/uuid.dart';

import '../providers/metronome_provider.dart';
import '../widgets/liveset_editor.dart';
import '../theme/app_theme.dart';

/// Complex mode screen with liveset editor
class ComplexModeScreen extends StatelessWidget {
  const ComplexModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MetronomeProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Liveset editor
              Expanded(
                child: LivesetEditor(
                  text: provider.dslText,
                  errors: provider.parseErrors,
                  onChanged: provider.updateDslText,
                  onExport: () => _exportLiveset(context, provider),
                ),
              ),

              const SizedBox(height: 16),

              // Bar counter at the bottom
              _BarCounter(provider: provider),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportLiveset(
    BuildContext context,
    MetronomeProvider provider,
  ) async {
    try {
      final content = provider.exportDsl();
      final bytes = utf8.encode(content);
      final fileName = const Uuid().v4().replaceAll('-', '');

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'liveset',
        mimeType: MimeType.text,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liveset exported successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

/// Bar counter widget at the bottom
class _BarCounter extends StatelessWidget {
  final MetronomeProvider provider;

  const _BarCounter({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: provider.isPlaying
            ? Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                width: 2,
              )
            : null,
        boxShadow: provider.isPlaying
            ? [
                const BoxShadow(
                  color: AppTheme
                      .primaryColor, // withValues handled separately if needed, but AppTheme should be stable
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              const Text(
                'BAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.isPlaying
                    ? (provider.playbackState.isDelaying
                          ? '—'
                          : '${provider.playbackState.totalBar}')
                    : '—',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: provider.isPlaying
                      ? AppTheme.textColor
                      : AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          if (provider.isPlaying) ...[
            const SizedBox(width: 32),
            Container(
              width: 1,
              height: 50,
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.playbackState.currentTempo} BPM',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  provider.playbackState.currentTimeSignature.display,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'share_modal.dart';
import '../services/track_analyzer.dart';
import '../services/track_language.dart';
import '../services/track_parser.dart';
import '../theme/app_theme.dart';

/// Track DSL text editor with syntax highlighting and error display
class TrackEditor extends StatefulWidget {
  final String text;
  final List<ParseError> errors;
  final ValueChanged<String> onChanged;
  final VoidCallback? onExport;

  const TrackEditor({
    super.key,
    required this.text,
    required this.errors,
    required this.onChanged,
    this.onExport,
  });

  @override
  State<TrackEditor> createState() => _TrackEditorState();
}

class _TrackEditorState extends State<TrackEditor> {
  late CodeController _controller;
  late FocusNode _focusNode;
  late String _lastText;

  @override
  void initState() {
    super.initState();
    _lastText = widget.text;
    _controller = CodeController(
      text: widget.text,
      language: trackLanguage,
      analyzer: TrackAnalyzer(),
    );
    // Override dismiss action: unfocus editor when nothing to dismiss
    _controller.actions[DismissIntent] = CallbackAction<DismissIntent>(
      onInvoke: (intent) {
        if (_controller.popupController.shouldShow) {
          _controller.dismiss();
        } else {
          _focusNode.unfocus(
            disposition: UnfocusDisposition.previouslyFocusedChild,
          );
        }
        return null;
      },
    );
    // Listen for text changes to catch autocomplete insertions
    _controller.addListener(_onControllerChanged);
    _focusNode = FocusNode(debugLabel: 'TrackEditor');
  }

  void _onControllerChanged() {
    if (_controller.text != _lastText) {
      _lastText = _controller.text;
      widget.onChanged(_controller.text);
    }
  }

  @override
  void didUpdateWidget(TrackEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text && widget.text != oldWidget.text) {
      final selection = _controller.selection;
      _lastText = widget.text;
      _controller.text = widget.text;
      if (selection.baseOffset <= widget.text.length) {
        _controller.selection = selection;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LanguageSyntax'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'tempo <bpm>',
                'Sets the tempo (20-500 BPM). Example: tempo 120',
              ),
              _buildHelpItem(
                'time <num>/<den>[, <n> bars]',
                'Sets time signature and optional bar count. Example: time 4/4, 8 bars',
              ),
              _buildHelpItem(
                'delay <seconds>',
                'Adds a silent pause. Example: delay 1.5',
              ),
              _buildHelpItem('// comment', 'Single-line comment.'),
              _buildHelpItem('/* comment */', 'Multi-line comment.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String syntax, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            syntax,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with export button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Track Editor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.help_outline, size: 20),
                  tooltip: 'Syntax Help',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showHelp(context),
                ),
              ],
            ),
            if (widget.onExport != null)
              ElevatedButton.icon(
                onPressed: widget.errors.isEmpty
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => ShareModal(
                            dslText: widget.text,
                            onExport: widget.onExport!,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Editor - CodeField with syntax highlighting
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.errors.isEmpty
                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                    : AppTheme.errorColor.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Scrollbar(
              child: SingleChildScrollView(
                child: CodeTheme(
                  data: CodeThemeData(
                    styles: {
                      'root': const TextStyle(
                        color: AppTheme.textColor,
                        backgroundColor: Colors
                            .transparent, // Background handled by container
                      ),
                      'keyword': const TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                      'number': const TextStyle(color: AppTheme.successColor),
                      'operator': const TextStyle(
                        color: AppTheme.beatHighlight,
                        fontWeight: FontWeight.bold,
                      ),
                      'comment': const TextStyle(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.normal,
                      ),
                    },
                  ),
                  child: CodeField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    cursorColor: AppTheme.primaryColor,
                    gutterStyle: GutterStyle(
                      showErrors: true,
                      showFoldingHandles: false,
                      showLineNumbers: true,
                      textAlign: TextAlign.right,
                      margin: 12.0,
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.4,
                    ),
                    decoration: const BoxDecoration(color: Colors.transparent),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

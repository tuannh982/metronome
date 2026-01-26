import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import '../services/liveset_analyzer.dart';
import '../services/liveset_language.dart';
import '../services/liveset_parser.dart';
import '../theme/app_theme.dart';

/// Liveset DSL text editor with syntax highlighting and error display
class LivesetEditor extends StatefulWidget {
  final String text;
  final List<ParseError> errors;
  final ValueChanged<String> onChanged;
  final VoidCallback? onExport;

  const LivesetEditor({
    super.key,
    required this.text,
    required this.errors,
    required this.onChanged,
    this.onExport,
  });

  @override
  State<LivesetEditor> createState() => _LivesetEditorState();
}

class _LivesetEditorState extends State<LivesetEditor> {
  late CodeController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.text,
      language: livesetLanguage,
      analyzer: LivesetAnalyzer(),
    );
    _controller.autocompleter.setCustomWords(['tempo', 'time', 'bars', 'bar']);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(LivesetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text && widget.text != oldWidget.text) {
      final selection = _controller.selection;
      _controller.text = widget.text;
      if (selection.baseOffset <= widget.text.length) {
        _controller.selection = selection;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
            Text(
              'Liveset Editor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.onExport != null)
              ElevatedButton.icon(
                onPressed: widget.errors.isEmpty ? widget.onExport : null,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
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
                    onChanged: widget.onChanged,
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
                      height: 1.6,
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

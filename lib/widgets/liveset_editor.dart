import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
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

  void _insertTab() {
    final cursorOffset = _controller.selection.baseOffset;
    final text = _controller.text;
    const tab = '  ';

    final newText = text.substring(0, cursorOffset) +
        tab +
        text.substring(_controller.selection.extentOffset);

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorOffset + tab.length),
    );

    widget.onChanged(newText);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle TAB key - insert 2 spaces
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _insertTab();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
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

        // Editor - simple TextField with visible text
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
            child: Focus(
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: AppTheme.textColor,
                  height: 1.6,
                ),
                cursorColor: AppTheme.primaryColor,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintText: _hintText,
                  hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _hintText => '''
// Liveset syntax:
tempo 120

time 4/4, 8 bars
time 3/4, 4 bars

tempo 140
time 7/8, 8 bars
''';
}

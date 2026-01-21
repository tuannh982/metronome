import 'time_signature.dart';

/// A time directive in a liveset (time signature with optional bars and tempo)
class LivesetDirective {
  /// Time signature
  final TimeSignature timeSignature;

  /// Tempo in BPM
  final int tempo;

  /// Number of bars (optional, null means until next directive)
  final int? bars;

  /// Line number in source
  final int lineNumber;

  const LivesetDirective({
    required this.timeSignature,
    required this.tempo,
    this.bars,
    required this.lineNumber,
  });

  /// Convert to DSL text (multi-line format)
  String toDsl() {
    final buffer = StringBuffer();
    buffer.writeln('time ${timeSignature.display}');
    if (bars != null) {
      buffer.write('tempo $tempo, $bars bars');
    } else {
      buffer.write('tempo $tempo');
    }
    return buffer.toString();
  }

  @override
  String toString() =>
      'Directive(${timeSignature.display}, $tempo bpm${bars != null ? ', $bars bars' : ''})';
}

/// A complete liveset containing directives
class Liveset {
  final String name;
  final List<LivesetDirective> directives;

  const Liveset({
    this.name = 'Untitled',
    this.directives = const [],
  });

  /// Check if liveset is empty
  bool get isEmpty => directives.isEmpty;

  /// Get total bars (only counting directives with explicit bars)
  int get totalBars => directives
      .where((d) => d.bars != null)
      .fold(0, (sum, d) => sum + d.bars!);

  /// Convert entire liveset to DSL text
  String toDsl() {
    final buffer = StringBuffer();
    buffer.writeln('// Liveset: $name');
    buffer.writeln();
    for (final directive in directives) {
      buffer.writeln(directive.toDsl());
    }
    return buffer.toString();
  }

  @override
  String toString() => 'Liveset($name: ${directives.length} directives)';
}

/// Represents the current playback position in a liveset
class LivesetPlaybackState {
  final int directiveIndex;
  final int barInDirective;
  final int beatInBar;
  final int currentTempo;
  final TimeSignature currentTimeSignature;

  const LivesetPlaybackState({
    this.directiveIndex = 0,
    this.barInDirective = 1,
    this.beatInBar = 1,
    this.currentTempo = 120,
    this.currentTimeSignature = TimeSignature.common,
  });

  LivesetPlaybackState copyWith({
    int? directiveIndex,
    int? barInDirective,
    int? beatInBar,
    int? currentTempo,
    TimeSignature? currentTimeSignature,
  }) {
    return LivesetPlaybackState(
      directiveIndex: directiveIndex ?? this.directiveIndex,
      barInDirective: barInDirective ?? this.barInDirective,
      beatInBar: beatInBar ?? this.beatInBar,
      currentTempo: currentTempo ?? this.currentTempo,
      currentTimeSignature: currentTimeSignature ?? this.currentTimeSignature,
    );
  }
}

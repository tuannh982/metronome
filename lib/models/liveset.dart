import 'time_signature.dart';

/// Base class for all directives in a liveset
sealed class LivesetDirective {
  /// Line number in source
  final int lineNumber;

  const LivesetDirective({required this.lineNumber});

  Map<String, dynamic> toJson();
}

/// A time directive in a liveset (time signature with optional bars and tempo)
class TimeDirective extends LivesetDirective {
  /// Time signature
  final TimeSignature timeSignature;

  /// Tempo in BPM
  final int tempo;

  /// Number of bars (optional, null means until next directive)
  final int? bars;

  const TimeDirective({
    required this.timeSignature,
    required this.tempo,
    this.bars,
    required super.lineNumber,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'time',
    'timeSignature': timeSignature.toJson(),
    'tempo': tempo,
    'bars': bars,
    'lineNumber': lineNumber,
  };

  @override
  String toString() =>
      'TimeDirective(${timeSignature.display}, $tempo bpm${bars != null ? ', $bars bars' : ''})';
}

/// A delay directive in a liveset (pauses playback for a duration)
class DelayDirective extends LivesetDirective {
  /// Duration in seconds
  final double seconds;

  const DelayDirective({required this.seconds, required super.lineNumber});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'delay',
    'seconds': seconds,
    'lineNumber': lineNumber,
  };

  @override
  String toString() => 'DelayDirective($seconds s)';
}

/// A complete liveset containing directives
class Liveset {
  final String name;
  final List<LivesetDirective> directives;

  const Liveset({this.name = 'Untitled', this.directives = const []});

  /// Check if liveset is empty
  bool get isEmpty => directives.isEmpty;

  /// Get total bars (only counting time directives with explicit bars)
  int get totalBars => directives
      .whereType<TimeDirective>()
      .where((d) => d.bars != null)
      .fold(0, (sum, d) => sum + d.bars!);

  Map<String, dynamic> toJson() => {
    'name': name,
    'directives': directives.map((d) => d.toJson()).toList(),
    'totalBars': totalBars,
  };

  @override
  String toString() => 'Liveset($name: ${directives.length} directives)';
}

/// Represents the current playback position in a liveset
class LivesetPlaybackState {
  final int directiveIndex;
  final int barInDirective;
  final int totalBar;
  final int flattenedIndex;
  final int beatInBar;
  final int currentTempo;
  final TimeSignature currentTimeSignature;
  final bool isDelaying;

  const LivesetPlaybackState({
    this.directiveIndex = 0,
    this.barInDirective = 1,
    this.totalBar = 1,
    this.flattenedIndex = 0,
    this.beatInBar = 1,
    this.currentTempo = 120,
    this.currentTimeSignature = TimeSignature.common,
    this.isDelaying = false,
  });

  LivesetPlaybackState copyWith({
    int? directiveIndex,
    int? barInDirective,
    int? totalBar,
    int? flattenedIndex,
    int? beatInBar,
    int? currentTempo,
    TimeSignature? currentTimeSignature,
    bool? isDelaying,
  }) {
    return LivesetPlaybackState(
      directiveIndex: directiveIndex ?? this.directiveIndex,
      barInDirective: barInDirective ?? this.barInDirective,
      totalBar: totalBar ?? this.totalBar,
      flattenedIndex: flattenedIndex ?? this.flattenedIndex,
      beatInBar: beatInBar ?? this.beatInBar,
      currentTempo: currentTempo ?? this.currentTempo,
      currentTimeSignature: currentTimeSignature ?? this.currentTimeSignature,
      isDelaying: isDelaying ?? this.isDelaying,
    );
  }
}

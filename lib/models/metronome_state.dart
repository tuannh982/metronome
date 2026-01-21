import 'time_signature.dart';

/// Represents the current state of the metronome
class MetronomeState {
  /// Tempo in beats per minute (40-300)
  final int bpm;

  /// Current time signature
  final TimeSignature timeSignature;

  /// Current beat (1-indexed, 1 to timeSignature.numerator)
  final int currentBeat;

  /// Whether the metronome is currently playing
  final bool isPlaying;

  /// Current bar number (1-indexed)
  final int currentBar;

  const MetronomeState({
    this.bpm = 120,
    this.timeSignature = TimeSignature.common,
    this.currentBeat = 1,
    this.isPlaying = false,
    this.currentBar = 1,
  });

  /// Create a copy with optional overrides
  MetronomeState copyWith({
    int? bpm,
    TimeSignature? timeSignature,
    int? currentBeat,
    bool? isPlaying,
    int? currentBar,
  }) {
    return MetronomeState(
      bpm: bpm ?? this.bpm,
      timeSignature: timeSignature ?? this.timeSignature,
      currentBeat: currentBeat ?? this.currentBeat,
      isPlaying: isPlaying ?? this.isPlaying,
      currentBar: currentBar ?? this.currentBar,
    );
  }

  /// Duration of one beat in milliseconds
  int get beatDurationMs => (60000 / bpm).round();

  /// Duration of one beat in microseconds (for precise timing)
  int get beatDurationMicros => (60000000 / bpm).round();

  /// Whether current beat is the downbeat (first beat of measure)
  bool get isDownbeat => currentBeat == 1;

  @override
  String toString() =>
      'MetronomeState(bpm: $bpm, time: ${timeSignature.display}, beat: $currentBeat/${timeSignature.numerator}, playing: $isPlaying)';
}

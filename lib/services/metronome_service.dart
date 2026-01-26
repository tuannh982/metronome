import 'dart:async';
import 'audio_service.dart';
import '../models/metronome_state.dart';
import '../models/time_signature.dart';

/// Core metronome service with precise timing
class MetronomeService {
  final AudioService _audioService;

  Timer? _timer;
  Stopwatch? _stopwatch;
  int _expectedTick = 0;
  int _timerId = 0;

  MetronomeState _state = const MetronomeState();

  /// Callback for each beat
  void Function(MetronomeState state)? onBeat;

  /// Callback when state changes
  void Function(MetronomeState state)? onStateChanged;

  MetronomeService(this._audioService);

  /// Get current state
  MetronomeState get state => _state;

  /// Initialize the service
  Future<void> init() async {
    await _audioService.init();
  }

  /// Set tempo (BPM)
  void setTempo(int bpm, {bool immediate = true}) {
    updateConfig(bpm: bpm, immediate: immediate);
  }

  /// Set time signature
  void setTimeSignature(TimeSignature timeSignature, {bool immediate = true}) {
    updateConfig(timeSignature: timeSignature, immediate: immediate);
  }

  /// Update tempo and time signature simultaneously
  void updateConfig({
    int? bpm,
    TimeSignature? timeSignature,
    bool immediate = true,
  }) {
    MetronomeState newState = _state;
    if (bpm != null) {
      newState = newState.copyWith(bpm: bpm.clamp(40, 300));
    }
    if (timeSignature != null) {
      newState = newState.copyWith(
        timeSignature: timeSignature,
        currentBeat: 1, // Reset to beat 1 when changing time signature
      );
    }
    
    _updateState(newState);
    
    if (_state.isPlaying) {
      _restartTimer(immediate: immediate);
    }
  }

  /// Start playing
  void play() {
    if (_state.isPlaying) return;

    _updateState(_state.copyWith(isPlaying: true, currentBeat: 1, currentBar: 1));
    _startTimer();
  }

  /// Stop playing
  void stop() {
    _stopTimer();
    _updateState(_state.copyWith(
      isPlaying: false,
      currentBeat: 1,
      currentBar: 1,
    ));
  }

  /// Pause playing (preserves current beat)
  void pause() {
    _stopTimer();
    _updateState(_state.copyWith(isPlaying: false));
  }

  /// Toggle play/pause
  void toggle() {
    if (_state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void _startTimer({bool immediate = true}) {
    _stopwatch = Stopwatch()..start();
    _expectedTick = 0;

    // Play first beat immediately if requested
    if (immediate) {
      _playBeat();
    }

    // Schedule subsequent beats
    _timerId++; // Increment ID to invalidate any previous timer loops
    _scheduleNextBeat(_timerId);
  }

  void _scheduleNextBeat(int sessionId) {
    if (sessionId != _timerId) return; // Terminate if this isn't the active session

    _expectedTick++;
    final nextBeatTime = _expectedTick * _state.beatDurationMicros;
    final delay = nextBeatTime - _stopwatch!.elapsedMicroseconds;

    _timer = Timer(Duration(microseconds: delay.clamp(0, _state.beatDurationMicros)), () {
      if (!_state.isPlaying || sessionId != _timerId) return;

      // Advance beat
      int nextBeat = _state.currentBeat + 1;
      int nextBar = _state.currentBar;

      if (nextBeat > _state.timeSignature.numerator) {
        nextBeat = 1;
        nextBar++;
      }

      _updateState(_state.copyWith(
        currentBeat: nextBeat,
        currentBar: nextBar,
      ));

      _playBeat();
      _scheduleNextBeat(sessionId);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    _stopwatch = null;
    _expectedTick = 0;
    _timerId++; // Invalidate any pending timers
  }

  void _restartTimer({bool immediate = true}) {
    _stopTimer();
    if (_state.isPlaying) {
      _startTimer(immediate: immediate);
    }
  }

  void _playBeat() {
    if (_state.isDownbeat) {
      _audioService.playAccent();
    } else {
      _audioService.playClick();
    }
    onBeat?.call(_state);
  }

  void _updateState(MetronomeState newState) {
    _state = newState;
    onStateChanged?.call(_state);
  }

  /// Dispose resources
  void dispose() {
    _stopTimer();
  }
}

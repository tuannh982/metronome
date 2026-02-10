import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/metronome_state.dart';
import '../models/time_signature.dart';
import '../models/track.dart';
import '../services/audio_service.dart';
import '../services/metronome_service.dart';
import '../services/track_parser.dart';

/// App mode enum
enum AppMode { simple, complex }

/// Provider for metronome state management
class MetronomeProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  late final MetronomeService _metronomeService;
  final TrackParser _parser = TrackParser();

  AppMode _mode = AppMode.simple;
  MetronomeState _state = const MetronomeState();
  Track? _track;
  List<TrackDirective> _flattenedBars = [];
  TrackPlaybackState _playbackState = const TrackPlaybackState();
  String _dslText = '';
  List<ParseError> _parseErrors = [];
  bool _initialized = false;
  double? _remainingDelay;
  double? _totalDelay;
  Timer? _delayUpdateTimer;
  final List<int> _tapTimestamps = [];
  static const int _maxTaps = 8;
  static const int _tapResetMs = 2000;

  MetronomeProvider() {
    _metronomeService = MetronomeService(_audioService);
    _metronomeService.onStateChanged = _onStateChanged;
    _metronomeService.onBeat = _onBeat;
  }

  // Getters
  AppMode get mode => _mode;
  MetronomeState get state => _state;
  Track? get track => _track;
  TrackPlaybackState get playbackState => _playbackState;
  String get dslText => _dslText;
  List<ParseError> get parseErrors => _parseErrors;
  List<TrackDirective> get flattenedBars => _flattenedBars;
  bool get isPlaying => _state.isPlaying || _playbackState.isDelaying;
  bool get initialized => _initialized;
  bool get canPlay {
    if (_mode == AppMode.simple) return true;
    final hasDirectives = _track?.directives.isNotEmpty ?? false;
    final hasNoErrors = _parseErrors.isEmpty;
    final hasContent = _dslText.trim().isNotEmpty;
    return hasNoErrors && hasDirectives && hasContent;
  }

  double? get remainingDelay => _remainingDelay;
  double? get totalDelay => _totalDelay;

  /// Get the next directive in the track, if any
  TrackDirective? get nextDirective {
    if (_mode != AppMode.complex ||
        _track == null ||
        !isPlaying ||
        _flattenedBars.isEmpty) {
      return null;
    }

    final nextIndex = _playbackState.flattenedIndex + 1;
    if (nextIndex >= 0 && nextIndex < _flattenedBars.length) {
      return _flattenedBars[nextIndex];
    }

    return null;
  }

  /// Initialize the provider
  Future<void> init() async {
    if (_initialized) return;
    await _metronomeService.init();
    _initialized = true;
    notifyListeners();
  }

  /// Switch app mode
  void setMode(AppMode mode) {
    if (_mode == mode) return;
    // Stop playing when switching modes
    if (_state.isPlaying) {
      _metronomeService.stop();
    }
    _mode = mode;
    notifyListeners();
  }

  /// Tap tempo — record a tap and calculate BPM from recent tap intervals
  void tapTempo() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Reset if too long since last tap
    if (_tapTimestamps.isNotEmpty &&
        (now - _tapTimestamps.last) > _tapResetMs) {
      _tapTimestamps.clear();
    }

    _tapTimestamps.add(now);

    // Keep only the last N taps
    if (_tapTimestamps.length > _maxTaps) {
      _tapTimestamps.removeAt(0);
    }

    // Need at least 2 taps to calculate BPM
    if (_tapTimestamps.length >= 2) {
      final intervals = <int>[];
      for (int i = 1; i < _tapTimestamps.length; i++) {
        intervals.add(_tapTimestamps[i] - _tapTimestamps[i - 1]);
      }
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final bpm = (60000 / avgInterval).round().clamp(
        AppConstants.minBpm,
        AppConstants.maxBpm,
      );
      _metronomeService.setTempo(bpm);
    }
  }

  /// Set tempo (simple mode)
  void setTempo(int bpm) {
    _metronomeService.setTempo(bpm);
  }

  /// Set time signature (simple mode)
  void setTimeSignature(TimeSignature timeSignature) {
    _metronomeService.setTimeSignature(timeSignature);
  }

  /// Play metronome
  void play() {
    if (!canPlay) return;
    if (_mode == AppMode.complex &&
        _track != null &&
        _track!.directives.isNotEmpty) {
      _playTrack();
    } else {
      _metronomeService.play();
    }
  }

  /// Stop metronome
  void stop() {
    _metronomeService.stop();
    _playbackState = const TrackPlaybackState();
    notifyListeners();
  }

  /// Toggle play/pause
  void toggle() {
    if (isPlaying) {
      if (_playbackState.isDelaying) {
        _delayUpdateTimer?.cancel();
        _playbackState = _playbackState.copyWith(isDelaying: false);
        notifyListeners();
      } else {
        _metronomeService.pause();
      }
    } else {
      if (canPlay) {
        play();
      }
    }
  }

  void seekTo(int index) {
    if (_flattenedBars.isEmpty || index < 0 || index >= _flattenedBars.length) {
      return;
    }

    final wasPlaying = isPlaying;
    final directive = _flattenedBars[index];
    int barInDirective = 1;
    for (int i = index - 1; i >= 0; i--) {
      if (_flattenedBars[i] == directive) {
        barInDirective++;
      } else {
        break;
      }
    }

    int totalBar = 0;
    for (int i = 0; i <= index; i++) {
      if (_flattenedBars[i] is TimeDirective) {
        totalBar++;
      }
    }

    _playbackState = TrackPlaybackState(
      directiveIndex: _track!.directives.indexOf(directive),
      barInDirective: barInDirective,
      totalBar: totalBar,
      flattenedIndex: index,
      beatInBar: 1,
      currentTempo: directive is TimeDirective
          ? directive.tempo
          : _playbackState.currentTempo,
      currentTimeSignature: directive is TimeDirective
          ? directive.timeSignature
          : _playbackState.currentTimeSignature,
      isDelaying: directive is DelayDirective && wasPlaying,
    );

    if (wasPlaying) {
      if (directive is TimeDirective) {
        _delayUpdateTimer?.cancel();
        _metronomeService.updateConfig(
          bpm: directive.tempo,
          timeSignature: directive.timeSignature,
          immediate: true,
        );
        if (!_state.isPlaying) {
          _metronomeService.play(reset: false);
        }
      } else if (directive is DelayDirective) {
        _metronomeService.pause();
        _startDelay(directive.seconds);
      }
    }

    notifyListeners();
  }

  /// Update DSL text and parse
  void updateDslText(String text) {
    _dslText = text;
    final result = _parser.parse(text);
    debugPrint(result.toString());
    _parseErrors = result.errors;
    _track = result.track;
    _buildFlattenedBars();
    notifyListeners();
  }

  void _buildFlattenedBars() {
    _flattenedBars = [];
    if (_track == null) return;
    for (final d in _track!.directives) {
      if (d is TimeDirective) {
        final barsCount = d.bars ?? 1;
        for (int i = 0; i < barsCount; i++) {
          _flattenedBars.add(d);
        }
      } else if (d is DelayDirective) {
        _flattenedBars.add(d);
      }
    }
  }

  /// Get DSL export text
  String exportDsl() {
    return _dslText;
  }

  void _playTrack() {
    if (_track == null || _track!.isEmpty || _flattenedBars.isEmpty) return;

    final startIndex = _playbackState.flattenedIndex;
    final currentBar = _flattenedBars[startIndex];

    if (currentBar is TimeDirective) {
      _playbackState = _playbackState.copyWith(
        directiveIndex: _track!.directives.indexOf(currentBar),
        isDelaying: false,
        currentTempo: currentBar.tempo,
        currentTimeSignature: currentBar.timeSignature,
        beatInBar: 1, // Reset beat to start of bar
      );

      _metronomeService.setTempo(currentBar.tempo);
      _metronomeService.setTimeSignature(currentBar.timeSignature);
      _metronomeService.play();
    } else if (currentBar is DelayDirective) {
      _playbackState = _playbackState.copyWith(
        directiveIndex: _track!.directives.indexOf(currentBar),
        isDelaying: true,
      );
      _metronomeService.stop();
      _startDelay(currentBar.seconds);
    }
    notifyListeners();
  }

  void _startDelay(double seconds) {
    _totalDelay = seconds;
    _remainingDelay = seconds;
    _delayUpdateTimer?.cancel();
    _delayUpdateTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      _remainingDelay = (_remainingDelay ?? 0) - 0.05;
      if (_remainingDelay! <= 0) {
        _remainingDelay = 0;
        timer.cancel();
      }
      notifyListeners();
    });

    Future.delayed(Duration(milliseconds: (seconds * 1000).toInt()), () {
      _delayUpdateTimer?.cancel();
      _remainingDelay = null;
      _totalDelay = null;
      if (!_state.isPlaying && _playbackState.isDelaying) {
        _advanceTrackPlayback(fromDelay: true);
      }
    });
  }

  void _onStateChanged(MetronomeState newState) {
    _state = newState;
    notifyListeners();
  }

  void _onBeat(MetronomeState state) {
    if (_mode == AppMode.complex && _track != null && _state.isPlaying) {
      _advanceTrackPlayback();
    }
    notifyListeners();
  }

  void _advanceTrackPlayback({bool fromDelay = false}) {
    if (_track == null || _flattenedBars.isEmpty) return;

    final previousBeat = _playbackState.beatInBar;
    final currentBeat = fromDelay ? 1 : _state.currentBeat;

    // Only advance if a beat has actually passed (or if coming from delay)
    if (!fromDelay && currentBeat == previousBeat) return;

    // Detect bar transition: when beat resets to 1 after being on a higher beat
    // or if we are coming from a delay
    final isNewBar = fromDelay || (currentBeat == 1 && previousBeat > 1);

    if (isNewBar) {
      final nextFlattenedIndex = _playbackState.flattenedIndex + 1;
      int currentIndex = nextFlattenedIndex;

      // Handle end of track
      if (currentIndex >= _flattenedBars.length) {
        final lastDirective = _flattenedBars.last;
        if (lastDirective is TimeDirective && lastDirective.bars == null) {
          // Stay on the infinite bar
          currentIndex = _flattenedBars.length - 1;
        } else {
          stop();
          return;
        }
      }

      final currentDirective = _flattenedBars[currentIndex];

      // Calculate barInDirective
      int barInDirective = 1;
      for (int i = currentIndex - 1; i >= 0; i--) {
        if (_flattenedBars[i] == currentDirective) {
          barInDirective++;
        } else {
          break;
        }
      }

      // Calculate totalBar (only counting TimeDirectives)
      int nextTotalBar = _playbackState.totalBar;
      if (currentDirective is TimeDirective) {
        nextTotalBar++;
      }

      if (currentDirective is TimeDirective) {
        final isTransition =
            currentDirective.tempo != _playbackState.currentTempo ||
            currentDirective.timeSignature !=
                _playbackState.currentTimeSignature ||
            _playbackState.isDelaying;

        _playbackState = TrackPlaybackState(
          directiveIndex: _track!.directives.indexOf(currentDirective),
          barInDirective: barInDirective,
          totalBar: nextTotalBar,
          flattenedIndex: currentIndex,
          beatInBar: 1, // Reset to 1 for new bar
          currentTempo: currentDirective.tempo,
          currentTimeSignature: currentDirective.timeSignature,
          isDelaying: false,
        );

        if (isTransition) {
          _metronomeService.updateConfig(
            bpm: currentDirective.tempo,
            timeSignature: currentDirective.timeSignature,
            immediate: false,
          );
        }
        if (!_state.isPlaying) {
          _metronomeService.play(reset: false);
        }
      } else if (currentDirective is DelayDirective) {
        _playbackState = TrackPlaybackState(
          directiveIndex: _track!.directives.indexOf(currentDirective),
          barInDirective: 1,
          totalBar: nextTotalBar, // Keeps previous totalBar
          flattenedIndex: currentIndex,
          beatInBar: 1,
          isDelaying: true,
          // Preserve tempo and time signature from previous directive if any
          currentTempo: _playbackState.currentTempo,
          currentTimeSignature: _playbackState.currentTimeSignature,
        );
        _metronomeService.pause();
        _startDelay(currentDirective.seconds);
      }
    } else {
      // Just update beat in bar
      _playbackState = _playbackState.copyWith(beatInBar: currentBeat);
    }
  }

  @override
  void dispose() {
    _delayUpdateTimer?.cancel();
    _metronomeService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}

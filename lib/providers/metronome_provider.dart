import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/metronome_state.dart';
import '../models/time_signature.dart';
import '../models/liveset.dart';
import '../services/audio_service.dart';
import '../services/metronome_service.dart';
import '../services/liveset_parser.dart';

/// App mode enum
enum AppMode { simple, complex }

/// Provider for metronome state management
class MetronomeProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  late final MetronomeService _metronomeService;
  final LivesetParser _parser = LivesetParser();

  AppMode _mode = AppMode.simple;
  MetronomeState _state = const MetronomeState();
  Liveset? _liveset;
  List<LivesetDirective> _flattenedBars = [];
  LivesetPlaybackState _playbackState = const LivesetPlaybackState();
  String _dslText = '';
  List<ParseError> _parseErrors = [];
  bool _initialized = false;
  double? _remainingDelay;
  double? _totalDelay;
  Timer? _delayUpdateTimer;

  MetronomeProvider() {
    _metronomeService = MetronomeService(_audioService);
    _metronomeService.onStateChanged = _onStateChanged;
    _metronomeService.onBeat = _onBeat;
  }

  // Getters
  AppMode get mode => _mode;
  MetronomeState get state => _state;
  Liveset? get liveset => _liveset;
  LivesetPlaybackState get playbackState => _playbackState;
  String get dslText => _dslText;
  List<ParseError> get parseErrors => _parseErrors;
  bool get isPlaying => _state.isPlaying || _playbackState.isDelaying;
  bool get initialized => _initialized;
  bool get canPlay {
    if (_mode == AppMode.simple) return true;
    final hasDirectives = _liveset?.directives.isNotEmpty ?? false;
    final hasNoErrors = _parseErrors.isEmpty;
    final hasContent = _dslText.trim().isNotEmpty;
    return hasNoErrors && hasDirectives && hasContent;
  }

  double? get remainingDelay => _remainingDelay;
  double? get totalDelay => _totalDelay;

  /// Get the next directive in the liveset, if any
  LivesetDirective? get nextDirective {
    if (_mode != AppMode.complex ||
        _liveset == null ||
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
        _liveset != null &&
        _liveset!.directives.isNotEmpty) {
      _playLiveset();
    } else {
      _metronomeService.play();
    }
  }

  /// Stop metronome
  void stop() {
    _metronomeService.stop();
    _playbackState = const LivesetPlaybackState();
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

  /// Update DSL text and parse
  void updateDslText(String text) {
    _dslText = text;
    final result = _parser.parse(text);
    print(result.toString());
    _parseErrors = result.errors;
    _liveset = result.liveset;
    _buildFlattenedBars();
    notifyListeners();
  }

  void _buildFlattenedBars() {
    _flattenedBars = [];
    if (_liveset == null) return;
    for (final d in _liveset!.directives) {
      if (d is TimeDirective) {
        final barsCount = d.bars ?? 1;
        for (int i = 0; i < barsCount; i++) {
          _flattenedBars.add(d);
        }
        if (d.bars == null) break;
      } else if (d is DelayDirective) {
        _flattenedBars.add(d);
      }
    }
  }

  /// Get DSL export text
  String exportDsl() {
    return _liveset?.toDsl() ?? _dslText;
  }

  void _playLiveset() {
    if (_liveset == null || _liveset!.isEmpty || _flattenedBars.isEmpty) return;

    final firstBar = _flattenedBars[0];

    if (firstBar is TimeDirective) {
      _playbackState = LivesetPlaybackState(
        directiveIndex: _liveset!.directives.indexOf(firstBar),
        barInDirective: 1,
        totalBar: 1,
        flattenedIndex: 0,
        beatInBar: 1,
        currentTempo: firstBar.tempo,
        currentTimeSignature: firstBar.timeSignature,
      );

      _metronomeService.setTempo(firstBar.tempo);
      _metronomeService.setTimeSignature(firstBar.timeSignature);
      _metronomeService.play();
    } else if (firstBar is DelayDirective) {
      _playbackState = LivesetPlaybackState(
        directiveIndex: _liveset!.directives.indexOf(firstBar),
        barInDirective: 1,
        totalBar: 0, // Not counting as a bar
        flattenedIndex: 0,
        beatInBar: 1,
        isDelaying: true,
      );
      _metronomeService.stop();
      _startDelay(firstBar.seconds);
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
        _advanceLivesetPlayback(fromDelay: true);
      }
    });
  }

  void _onStateChanged(MetronomeState newState) {
    _state = newState;
    notifyListeners();
  }

  void _onBeat(MetronomeState state) {
    if (_mode == AppMode.complex && _liveset != null && _state.isPlaying) {
      _advanceLivesetPlayback();
    }
    notifyListeners();
  }

  void _advanceLivesetPlayback({bool fromDelay = false}) {
    if (_liveset == null || _flattenedBars.isEmpty) return;

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

      // Handle end of liveset
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

        _playbackState = LivesetPlaybackState(
          directiveIndex: _liveset!.directives.indexOf(currentDirective),
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
        _playbackState = LivesetPlaybackState(
          directiveIndex: _liveset!.directives.indexOf(currentDirective),
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

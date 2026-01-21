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
  LivesetPlaybackState _playbackState = const LivesetPlaybackState();
  String _dslText = '';
  List<ParseError> _parseErrors = [];
  bool _initialized = false;

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
  bool get isPlaying => _state.isPlaying;
  bool get initialized => _initialized;

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
    if (_mode == AppMode.complex && _liveset != null && _liveset!.directives.isNotEmpty) {
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
    if (_state.isPlaying) {
      _metronomeService.pause();
    } else {
      play();
    }
  }

  /// Update DSL text and parse
  void updateDslText(String text) {
    _dslText = text;
    final result = _parser.parse(text);
    _parseErrors = result.errors;
    _liveset = result.liveset;
    notifyListeners();
  }

  /// Get DSL export text
  String exportDsl() {
    return _liveset?.toDsl() ?? _dslText;
  }

  void _playLiveset() {
    if (_liveset == null || _liveset!.isEmpty) return;

    // Get first directive's settings
    final firstDirective = _liveset!.directives[0];

    _playbackState = LivesetPlaybackState(
      directiveIndex: 0,
      barInDirective: 1,
      beatInBar: 1,
      currentTempo: firstDirective.tempo,
      currentTimeSignature: firstDirective.timeSignature,
    );

    _metronomeService.setTempo(firstDirective.tempo);
    _metronomeService.setTimeSignature(firstDirective.timeSignature);
    _metronomeService.play();
    notifyListeners();
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

  void _advanceLivesetPlayback() {
    if (_liveset == null || _liveset!.directives.isEmpty) return;

    int currentIndex = _playbackState.directiveIndex;
    int currentBar = _playbackState.barInDirective;
    int currentTempo = _playbackState.currentTempo;
    TimeSignature currentTimeSig = _playbackState.currentTimeSignature;

    final previousBeat = _playbackState.beatInBar;
    final currentBeat = _state.currentBeat;

    // Detect bar transition: when beat resets to 1 after being on a higher beat
    final isNewBar = currentBeat == 1 && previousBeat > 1;

    if (isNewBar) {
      currentBar++;

      // Check if we need to advance to next directive
      final currentDirective = _liveset!.directives[currentIndex];

      if (currentDirective.bars != null && currentBar > currentDirective.bars!) {
        // Move to next directive
        currentIndex++;
        currentBar = 1;

        // Check if liveset is complete
        if (currentIndex >= _liveset!.directives.length) {
          stop();
          return;
        }

        // Apply next directive settings
        final nextDirective = _liveset!.directives[currentIndex];
        currentTempo = nextDirective.tempo;
        currentTimeSig = nextDirective.timeSignature;
        
        // Update _playbackState BEFORE calling setTempo/setTimeSignature
        // to avoid reentrancy issues (setTimeSignature triggers onBeat callback
        // which would call _advanceLivesetPlayback again before we update state)
        _playbackState = LivesetPlaybackState(
          directiveIndex: currentIndex,
          barInDirective: currentBar,
          beatInBar: currentBeat,
          currentTempo: currentTempo,
          currentTimeSignature: currentTimeSig,
        );
        
        _metronomeService.setTempo(currentTempo);
        _metronomeService.setTimeSignature(currentTimeSig);
        return; // Already updated _playbackState
      }
    }

    _playbackState = LivesetPlaybackState(
      directiveIndex: currentIndex,
      barInDirective: currentBar,
      beatInBar: currentBeat,
      currentTempo: currentTempo,
      currentTimeSignature: currentTimeSig,
    );
  }

  @override
  void dispose() {
    _metronomeService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}

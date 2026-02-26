import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Service for playing metronome click sounds
class AudioService {
  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _clickSource;

  bool _initialized = false;
  double _volume = 1.0;

  // Audio source file
  static const _clickSound = 'assets/sounds/metronome-85688-small.mp3';

  /// Initialize audio players with click sounds
  Future<void> init() async {
    if (_initialized) return;

    try {
      await _soloud.init();
      _clickSource = await _soloud.loadAsset(_clickSound);
      _initialized = true;
    } catch (e) {
      debugPrint('AudioService init error: $e');
    }
  }

  /// Play regular click sound
  Future<void> playClick() async {
    if (_clickSource == null || !_initialized) return;
    try {
      await _soloud.play(_clickSource!, volume: _volume);
    } catch (e) {
      debugPrint('playClick error: $e');
    }
  }

  /// Play accented click sound (for downbeat)
  Future<void> playAccent() async {
    if (_clickSource == null || !_initialized) return;
    try {
      await _soloud.play(_clickSource!, volume: _volume);
    } catch (e) {
      debugPrint('playAccent error: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// Get current volume
  double get volume => _volume;

  /// Dispose resources
  Future<void> dispose() async {
    if (_clickSource != null) {
      await _soloud.disposeSource(_clickSource!);
    }
    _soloud.deinit();
  }
}

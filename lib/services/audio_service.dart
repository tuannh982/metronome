import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for playing metronome click sounds
class AudioService {
  AudioPlayer? _clickPlayer;
  AudioPlayer? _accentPlayer;

  bool _initialized = false;
  double _volume = 1.0;

  // Audio source file
  static const _clickSound = 'sounds/metronome-85688-small.mp3';

  /// Initialize audio players with click sounds
  Future<void> init() async {
    if (_initialized) return;

    try {
      _clickPlayer = AudioPlayer();
      _accentPlayer = AudioPlayer();

      // Set player mode for low latency
      await _clickPlayer!.setPlayerMode(PlayerMode.lowLatency);
      await _accentPlayer!.setPlayerMode(PlayerMode.lowLatency);
      await _clickPlayer!.setVolume(_volume);
      await _accentPlayer!.setVolume(_volume);
      _initialized = true;
    } catch (e) {
      debugPrint('AudioService init error: $e');
    }
  }

  /// Play regular click sound
  Future<void> playClick() async {
    if (_clickPlayer == null || !_initialized) return;
    try {
      await _clickPlayer!.setVolume(_volume);
      await _clickPlayer!.play(AssetSource(_clickSound));
    } catch (e) {
      debugPrint('playClick error: $e');
    }
  }

  /// Play accented click sound (for downbeat)
  Future<void> playAccent() async {
    if (_accentPlayer == null || !_initialized) return;
    try {
      await _accentPlayer!.setVolume(_volume);
      await _accentPlayer!.play(AssetSource(_clickSound));
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
    await _clickPlayer?.dispose();
    await _accentPlayer?.dispose();
  }
}

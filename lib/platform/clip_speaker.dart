import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/platform/voice_clips.dart';
import 'package:cadence/state/speaker.dart';
import 'package:just_audio/just_audio.dart';

/// The recorded voice ([VoiceClips]), played with `just_audio`: the same
/// voice on every phone, offline. Only `main.dart` knows this class: the
/// rest of the app sees a [Speaker].
class ClipSpeaker implements Speaker {
  final _player = AudioPlayer();

  /// The clips ship with the app: there is nothing to look for. A clip that
  /// cannot be played makes [speak] fail, and the session goes on silently
  /// (S4).
  @override
  Future<bool> init() async => true;

  /// Plays the call of [step] at [pace], a little faster with the pace but
  /// at the same pitch.
  @override
  Future<void> speak(ComboStep step, Pace pace) async {
    try {
      await _player.setAsset(VoiceClips.of(step, pace));
    } on PlayerInterruptedException {
      return; // Cut by stop() while loading: the call is over.
    }
    await _player.setSpeed(pace.speed);
    // play() completes at the end of the call, or at once when stop() cuts
    // it, but leaves the player "playing": pause() resets it, or the next
    // play() would return at once.
    await _player.play();
    await _player.pause();
  }

  @override
  Future<void> stop() => _player.stop();
}

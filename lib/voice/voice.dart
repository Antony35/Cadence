import 'package:cadence/models/combo.dart';
import 'package:cadence/voice/voice_clips.dart';
import 'package:just_audio/just_audio.dart';

/// Says the steps of a combo out loud with the recorded clips ([VoiceClips]):
/// the same voice on every phone, and offline.
class Voice {
  Voice() : _player = AudioPlayer();

  final AudioPlayer _player;

  /// Plays the clips of [step] without a gap between them. Completes when the
  /// last one ends, so the caller decides the pause before the next step.
  Future<void> say(ComboStep step) async {
    await _player.setAudioSources([
      for (final clip in VoiceClips.of(step)) AudioSource.asset(clip),
    ]);
    // play() completes at the end of the playlist but leaves the player
    // "playing": pause() resets it, or the next play() would return at once.
    await _player.play();
    await _player.pause();
  }

  /// Cuts the voice off, for instance when the session is left.
  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}

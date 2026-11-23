import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/platform/voice_clips.dart';
import 'package:cadence/state/speaker.dart';
import 'package:just_audio/just_audio.dart';

class ClipSpeaker implements Speaker {
  final _player = AudioPlayer();

  @override
  Future<bool> init() async => true;

  @override
  Future<void> speak(ComboStep step, Pace pace) async {
    try {
      await _player.setAsset(VoiceClips.of(step, pace));
    } on PlayerInterruptedException {
      return; // Cut by stop(): not a failure.
    }
    await _player.setSpeed(pace.speed);
    // play() leaves the player "playing" once the clip ends: without pause(),
    // the next play() would return at once.
    await _player.play();
    await _player.pause();
  }

  @override
  Future<void> stop() => _player.stop();
}

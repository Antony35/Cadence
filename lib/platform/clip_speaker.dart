import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/platform/voice_clips.dart';
import 'package:cadence/state/speaker.dart';
import 'package:just_audio/just_audio.dart';

class ClipSpeaker implements Speaker {
  ClipSpeaker({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  // Each speech gets a number, and stop() makes it stale: a stopped player
  // reloads its clip on play(), so a speech stopped between two awaits would
  // still be heard.
  int _speechCount = 0;

  @override
  Future<bool> init() async => true;

  @override
  Future<void> speak(ComboStep step, Pace pace) async {
    final speech = ++_speechCount;
    try {
      await _player.setAsset(VoiceClips.of(step, pace));
    } on PlayerInterruptedException {
      return; // Cut by stop(): not a failure.
    }
    if (speech != _speechCount) return;
    await _player.setSpeed(pace.speed);
    if (speech != _speechCount) return;
    // play() leaves the player "playing" once the clip ends: without pause(),
    // the next play() would return at once.
    await _player.play();
    await _player.pause();
  }

  @override
  Future<void> stop() {
    _speechCount++;
    return _player.stop();
  }
}

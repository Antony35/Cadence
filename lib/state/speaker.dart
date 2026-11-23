import 'dart:async';

import 'package:cadence/models/combo.dart';
import 'package:cadence/models/drill.dart';

abstract interface class Speaker {
  Future<bool> init();

  Future<void> speak(ComboStep step, Pace pace);

  Future<void> stop();
}

// Takes about the time the voice would, so the repetitions keep their rhythm.
class SilentSpeaker implements Speaker {
  static const _durationPerLetter = Duration(milliseconds: 70);

  Timer? _timer;
  Completer<void>? _speech;

  @override
  Future<bool> init() async => true;

  @override
  Future<void> speak(ComboStep step, Pace pace) {
    _endSpeech();
    final speech = _speech = Completer<void>();
    final letterCount = Drill.announcement(step, pace).length;
    _timer = Timer(_durationPerLetter * (letterCount / pace.speed), _endSpeech);
    return speech.future;
  }

  @override
  Future<void> stop() async => _endSpeech();

  void _endSpeech() {
    _timer?.cancel();
    _timer = null;
    final speech = _speech;
    _speech = null;
    if (speech != null && !speech.isCompleted) speech.complete();
  }
}

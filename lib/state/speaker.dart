import 'dart:async';

import 'package:cadence/models/drill.dart';

/// The voice of the session (R7).
///
/// A contract, like the repositories: the app plugs Android's voice
/// (`lib/platform/tts_speaker.dart`), the tests a fake that writes down what
/// it is asked to say. The phone's engine never runs in a test.
abstract interface class Speaker {
  /// Prepares a French voice. False when there is none (S4).
  Future<bool> init();

  /// Says [text] at [pace]. Completes when the sentence is over, or cut by
  /// [stop].
  Future<void> speak(String text, Pace pace);

  /// Cuts the sentence being said.
  Future<void> stop();
}

/// S4: no voice. Says nothing, but takes about the time the voice would
/// take, so that the repetitions keep their rhythm on screen.
class SilentSpeaker implements Speaker {
  /// About the time of one letter, at the normal speed of the voice.
  static const _perLetter = Duration(milliseconds: 70);

  /// A [Timer] calls a function once a duration has passed; cancelled, it
  /// never calls it.
  Timer? _timer;
  Completer<void>? _done;

  @override
  Future<bool> init() async => true;

  @override
  Future<void> speak(String text, Pace pace) {
    _finish();
    // A Completer makes a Future and decides when it completes.
    final done = _done = Completer<void>();
    final scale = Pace.medium.speechRate / pace.speechRate;
    _timer = Timer(_perLetter * (text.length * scale), _finish);
    return done.future;
  }

  @override
  Future<void> stop() async => _finish();

  void _finish() {
    _timer?.cancel();
    _timer = null;
    final done = _done;
    _done = null;
    if (done != null && !done.isCompleted) done.complete();
  }
}

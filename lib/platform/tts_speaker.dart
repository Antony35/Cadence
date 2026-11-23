import 'package:cadence/models/drill.dart';
import 'package:cadence/state/speaker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Android's speech synthesis, through `flutter_tts`. Only `main.dart` knows
/// this class: the rest of the app sees a [Speaker].
class TtsSpeaker implements Speaker {
  static const language = 'fr-FR';

  final _tts = FlutterTts();

  @override
  Future<bool> init() async {
    try {
      // Without a speech engine, the plugin's calls wait forever: after a
      // few seconds, the session goes on without the voice (S4).
      return await _prepare().timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('TtsSpeaker.init: $error');
      return false;
    }
  }

  Future<bool> _prepare() async {
    if (await _tts.isLanguageAvailable(language) != true) return false;
    await _tts.setLanguage(language);
    // `speak` then completes at the end of the sentence, not at its start.
    await _tts.awaitSpeakCompletion(true);
    return true;
  }

  @override
  Future<void> speak(String text, Pace pace) async {
    await _tts.setSpeechRate(pace.speechRate);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

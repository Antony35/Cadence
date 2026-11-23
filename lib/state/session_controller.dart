import 'dart:async';

import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/models/drill.dart';
import 'package:cadence/models/leitner.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/state/clock.dart';
import 'package:cadence/state/speaker.dart';
import 'package:flutter/foundation.dart';

/// Where the session is (E4). A `sealed` class, like `LoadState`: the
/// screen handles each phase in an exhaustive `switch`.
sealed class SessionPhase {
  const SessionPhase();
}

/// Reading the combos and preparing the voice.
final class Preparing extends SessionPhase {
  const Preparing();
}

/// The combos could not be read (S1, S3).
final class SessionFailed extends SessionPhase {
  const SessionFailed(this.message);

  final String message;
}

/// F20: the combo is shown, the voice waits for « Commencer »: time to
/// put the phone down and get on guard.
final class Ready extends SessionPhase {
  const Ready();
}

/// F20, F21: the voice says [cue]; or waits on it, when [paused].
final class Drilling extends SessionPhase {
  const Drilling(this.cue, {this.paused = false});

  final Cue cue;
  final bool paused;
}

/// F22: the grade is asked. [saving] while it is written, [failed] when the
/// write was refused: the grade can be given again.
final class Grading extends SessionPhase {
  const Grading({this.saving = false, this.failed = false});

  final bool saving;
  final bool failed;
}

/// F23: the series is over. [canContinue] when other combos are waiting.
final class Finished extends SessionPhase {
  const Finished({required this.reviewed, required this.canContinue});

  final int reviewed;
  final bool canContinue;
}

/// The state of a session (F19 to F23).
///
/// The course itself (paces, order, gaps) comes from [Drill], a pure class.
/// This controller plays it: it asks the [Speaker] to say each cue, waits
/// for the end of the sentence, then for the silence after it.
class SessionController extends ChangeNotifier {
  SessionController({
    required this._combos,
    required this._reviews,
    required this._clock,
    required this._speaker,
    required this.ahead,
  });

  final ComboRepository _combos;
  final ReviewRepository _reviews;
  final Clock _clock;

  /// « Réviser en avance »: the next combos, even if not due yet (F19).
  final bool ahead;

  /// Not final: the silent voice replaces it when it fails (S4).
  Speaker _speaker;
  bool? _voiceAvailable;

  SessionPhase _phase = const Preparing();
  List<Combo> _series = const [];
  List<Combo> _next = const [];
  int _index = 0;
  List<Cue> _cues = const [];
  int _cue = 0;
  final _reviewed = <int>{};

  /// Counts the runs of the voice, like `_loads` in `HomeController`: a
  /// pause starts a new count, and the old run stops at its next check.
  int _runs = 0;
  Timer? _silence;
  bool _disposed = false;

  SessionPhase get phase => _phase;

  /// False after the voice failed (S4): the screen says so.
  bool get voiceAvailable => _voiceAvailable ?? true;

  /// The combo being reviewed, and its place in the series (« 2 / 5 »).
  Combo get current => _series[_index];
  int get index => _index;
  int get seriesLength => _series.length;

  DateTime get today => dateOnly(_clock.now());

  /// F22: the next due day if [grade] is given, shown on its button.
  DateTime dueOnAfter(Grade grade) =>
      Leitner.dueOn(Leitner.nextBox(current.box, grade), _clock.now());

  /// Prepares the voice once, reads the series and starts the first combo.
  /// Also « Réessayer » after a read error.
  Future<void> start() async {
    _set(const Preparing());
    if (_voiceAvailable == null) {
      final ready = await _speaker.init();
      _voiceAvailable = ready;
      if (!ready) _goSilent();
    }
    final List<Combo> series;
    try {
      series = await _pick();
    } catch (error) {
      debugPrint('SessionController.start: $error');
      _set(const SessionFailed('Impossible de lire vos enchaînements.'));
      return;
    }
    if (_disposed) return;
    _play(series);
  }

  /// F20: « Commencer », the first strike is said.
  void startCombo() {
    if (_phase is Ready) unawaited(_run());
  }

  /// F21: the voice stops at once; [resume] says the cut strike again.
  void pause() {
    if (_phase case Drilling(:final cue, paused: false)) {
      _halt();
      _set(Drilling(cue, paused: true));
    }
  }

  void resume() {
    if (_phase case Drilling(paused: true)) unawaited(_run());
  }

  /// F21: « Passer à la note ».
  void skipToGrade() {
    if (_phase is Drilling) {
      _halt();
      _set(const Grading());
    }
  }

  /// F22: the grade is saved at once, so nothing is lost if the session is
  /// stopped afterwards.
  Future<void> grade(Grade grade) async {
    if (_phase case Grading(saving: false)) {
      _set(const Grading(saving: true));
      try {
        await _reviews.record(current, grade, now: _clock.now());
      } catch (error) {
        debugPrint('SessionController.grade: $error');
        _set(const Grading(failed: true));
        return;
      }
      if (_disposed) return; // Stopped while saving: no next combo.
      _reviewed.add(current.id);
      if (_index + 1 < _series.length) {
        _index++;
        _begin();
      } else {
        await _finish();
      }
    }
  }

  /// F23: a new series with the combos still waiting.
  void continueSession() {
    if (_phase case Finished(canContinue: true)) _play(_next);
  }

  /// F21: « Arrêter ». The grades already given are saved.
  void stop() => _halt();

  Future<List<Combo>> _pick() async {
    final candidates = ahead
        ? await _combos.findAll()
        : await _combos.findDue(today);
    return Drill.series(candidates, _reviewed);
  }

  void _play(List<Combo> series) {
    if (series.isEmpty) {
      _set(Finished(reviewed: _reviewed.length, canContinue: false));
      return;
    }
    _series = series;
    _index = 0;
    _begin();
  }

  /// Prepares the cues of the current combo; the voice waits for
  /// [startCombo].
  void _begin() {
    _cues = Drill.cues(current.steps);
    _cue = 0;
    _set(const Ready());
  }

  /// Says the cues from [_cue] to the end, then asks the grade. Returns as
  /// soon as a pause, a skip or a stop has started a new count.
  Future<void> _run() async {
    final run = ++_runs;
    while (_cue < _cues.length) {
      final cue = _cues[_cue];
      _set(Drilling(cue));
      await _say(cue);
      if (run != _runs) return;
      await _wait(cue.pauseAfter);
      if (run != _runs) return;
      _cue++;
    }
    _set(const Grading());
  }

  /// S4: if the voice fails during the session, the silent one takes over.
  Future<void> _say(Cue cue) async {
    try {
      await _speaker.speak(cue.text, cue.pace);
    } catch (error) {
      debugPrint('SessionController._say: $error');
      _goSilent();
      notifyListeners();
      await _speaker.speak(cue.text, cue.pace);
    }
  }

  Future<void> _wait(Duration duration) {
    if (duration == Duration.zero) return Future.value();
    final done = Completer<void>();
    _silence = Timer(duration, done.complete);
    return done.future;
  }

  /// Stops the voice and the silence; the run in progress ends.
  void _halt() {
    _runs++;
    _silence?.cancel();
    unawaited(_speaker.stop());
  }

  void _goSilent() {
    _voiceAvailable = false;
    _speaker = SilentSpeaker();
  }

  Future<void> _finish() async {
    try {
      _next = await _pick();
    } catch (error) {
      debugPrint('SessionController._finish: $error');
      _next = const [];
    }
    _set(Finished(reviewed: _reviewed.length, canContinue: _next.isNotEmpty));
  }

  void _set(SessionPhase phase) {
    if (_disposed) return;
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _halt();
    super.dispose();
  }
}

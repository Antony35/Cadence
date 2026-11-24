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

sealed class SessionPhase {
  const SessionPhase();
}

final class Preparing extends SessionPhase {
  const Preparing();
}

final class SessionFailed extends SessionPhase {
  const SessionFailed(this.message);

  final String message;
}

final class Ready extends SessionPhase {
  const Ready();
}

final class Drilling extends SessionPhase {
  const Drilling(this.cue, {this.isPaused = false});

  final Cue cue;
  final bool isPaused;
}

final class Grading extends SessionPhase {
  const Grading({this.isSaving = false, this.hasFailed = false});

  final bool isSaving;
  final bool hasFailed;
}

final class Finished extends SessionPhase {
  const Finished({required this.reviewed, required this.canContinue});

  final int reviewed;
  final bool canContinue;
}

class SessionController extends ChangeNotifier {
  SessionController({
    required this._combos,
    required this._reviews,
    required this._clock,
    required this._speaker,
    required this.reviewAhead,
    required this.seriesSize,
  });

  final ComboRepository _combos;
  final ReviewRepository _reviews;
  final Clock _clock;

  final bool reviewAhead;
  final int seriesSize;

  // Not final: SilentSpeaker replaces a failing voice.
  Speaker _speaker;
  bool? _voiceAvailable;

  SessionPhase _phase = const Preparing();
  List<Combo> _series = const [];
  List<Combo> _nextSeries = const [];
  int _comboIndex = 0;
  List<Cue> _cues = const [];
  int _cueIndex = 0;
  final _reviewedIds = <int>{};

  // Each run of the voice gets a number: a pause, a skip or a stop makes it
  // stale, and the run ends at its next check.
  int _runCount = 0;
  Timer? _silenceTimer;
  bool _disposed = false;

  SessionPhase get phase => _phase;

  bool get voiceAvailable => _voiceAvailable ?? true;

  Combo get currentCombo => _series[_comboIndex];
  int get comboIndex => _comboIndex;
  int get seriesLength => _series.length;

  DateTime get today => dateOnly(_clock.now());

  DateTime dueOnAfter(Grade grade) =>
      Leitner.dueOn(Leitner.nextBox(currentCombo.box, grade), _clock.now());

  Future<void> start() async {
    _setPhase(const Preparing());
    if (_voiceAvailable == null) {
      final ready = await _speaker.init();
      _voiceAvailable = ready;
      if (!ready) _goSilent();
    }
    final List<Combo> series;
    try {
      series = await _pickSeries();
    } catch (error) {
      debugPrint('SessionController.start: $error');
      _setPhase(const SessionFailed('Impossible de lire vos enchaînements.'));
      return;
    }
    if (_disposed) return;
    _startSeries(series);
  }

  void startCombo() {
    if (_phase is Ready) unawaited(_run());
  }

  void pause() {
    if (_phase case Drilling(:final cue, isPaused: false)) {
      _interrupt();
      _setPhase(Drilling(cue, isPaused: true));
    }
  }

  void resume() {
    if (_phase case Drilling(isPaused: true)) unawaited(_run());
  }

  void skipToGrade() {
    if (_phase is Drilling) {
      _interrupt();
      _setPhase(const Grading());
    }
  }

  Future<void> grade(Grade grade) async {
    if (_phase case Grading(isSaving: false)) {
      _setPhase(const Grading(isSaving: true));
      try {
        await _reviews.record(currentCombo, grade, now: _clock.now());
      } catch (error) {
        debugPrint('SessionController.grade: $error');
        _setPhase(const Grading(hasFailed: true));
        return;
      }
      if (_disposed) return; // Stopped while saving: no next combo.
      _reviewedIds.add(currentCombo.id);
      if (_comboIndex + 1 < _series.length) {
        _comboIndex++;
        _prepareCurrentCombo();
      } else {
        await _finish();
      }
    }
  }

  void continueSession() {
    if (_phase case Finished(canContinue: true)) _startSeries(_nextSeries);
  }

  void stop() => _interrupt();

  Future<List<Combo>> _pickSeries() async {
    final candidates = reviewAhead
        ? await _combos.findAll()
        : await _combos.findDue(today);
    return Drill.series(candidates, _reviewedIds, size: seriesSize);
  }

  void _startSeries(List<Combo> series) {
    if (series.isEmpty) {
      _setPhase(Finished(reviewed: _reviewedIds.length, canContinue: false));
      return;
    }
    _series = series;
    _comboIndex = 0;
    _prepareCurrentCombo();
  }

  void _prepareCurrentCombo() {
    _cues = Drill.cues(currentCombo.steps);
    _cueIndex = 0;
    _setPhase(const Ready());
  }

  Future<void> _run() async {
    final run = ++_runCount;
    while (_cueIndex < _cues.length) {
      final cue = _cues[_cueIndex];
      _setPhase(Drilling(cue));
      await _say(cue, run);
      if (_isStale(run)) return;
      await _waitSilence(cue.pauseAfter);
      if (_isStale(run)) return;
      _cueIndex++;
    }
    _setPhase(const Grading());
  }

  Future<void> _say(Cue cue, int run) async {
    try {
      await _speaker.speak(cue.step, cue.pace);
    } catch (error) {
      if (_isStale(run)) return;
      debugPrint('SessionController._say: $error');
      _goSilent();
      notifyListeners();
      await _speaker.speak(cue.step, cue.pace);
    }
  }

  bool _isStale(int run) => run != _runCount;

  Future<void> _waitSilence(Duration duration) {
    if (duration == Duration.zero) return Future.value();
    final done = Completer<void>();
    _silenceTimer = Timer(duration, done.complete);
    return done.future;
  }

  void _interrupt() {
    _runCount++;
    _silenceTimer?.cancel();
    unawaited(_speaker.stop());
  }

  void _goSilent() {
    _voiceAvailable = false;
    _speaker = SilentSpeaker();
  }

  Future<void> _finish() async {
    try {
      _nextSeries = await _pickSeries();
    } catch (error) {
      debugPrint('SessionController._finish: $error');
      _nextSeries = const [];
    }
    _setPhase(
      Finished(
        reviewed: _reviewedIds.length,
        canContinue: _nextSeries.isNotEmpty,
      ),
    );
  }

  void _setPhase(SessionPhase phase) {
    if (_disposed) return;
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _interrupt();
    super.dispose();
  }
}

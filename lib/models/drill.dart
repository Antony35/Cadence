import 'package:cadence/models/combo.dart';

/// The three speeds of the voice (D10). Fixed in the code, tuned by ear on
/// the Pixel.
enum Pace {
  slow('Lent', speechRate: 0.5, stepGap: Duration(milliseconds: 500)),
  medium('Moyen', speechRate: 0.65, stepGap: Duration(milliseconds: 250)),
  fast('Rapide', speechRate: 0.8, stepGap: Duration(milliseconds: 100));

  const Pace(this.label, {required this.speechRate, required this.stepGap});

  final String label;

  /// The speed of Android's voice, from 0 to 1: 0.5 is the normal speed,
  /// 0.8 is 1.6 times faster.
  final double speechRate;

  /// The silence after each strike: the faster, the shorter.
  final Duration stepGap;
}

/// One thing the voice says: [step] (from 0) of [repetition] (from 1), then
/// a silence of [pauseAfter]. A record, like `ReviewSummary`.
typedef Cue = ({
  int repetition,
  int step,
  Pace pace,
  String text,
  Duration pauseAfter,
});

/// The course of a session (D10, F19, F20), without the clock nor the
/// voice: pure functions, tested without waiting.
abstract final class Drill {
  static const repetitions = 12;

  /// Repetitions per pace: 4 slow, 4 medium, 4 fast.
  static const perPace = repetitions ~/ 3;

  /// The breath between two repetitions.
  static const repetitionGap = Duration(milliseconds: 1000);

  /// Combos per series, until the setting of step 6 (`sessionSize`).
  static const seriesSize = 5;

  /// D10: repetitions 1 to 4 slow, 5 to 8 medium, 9 to 12 fast.
  static Pace paceOf(int repetition) =>
      Pace.values[(repetition - 1) ~/ perPace];

  /// F20: everything the voice says for [steps], in order: each step one
  /// after the other, 12 times.
  static List<Cue> cues(List<ComboStep> steps) => [
    for (var repetition = 1; repetition <= repetitions; repetition++)
      for (final (index, step) in steps.indexed)
        (
          repetition: repetition,
          step: index,
          pace: paceOf(repetition),
          text: step.spokenLabel,
          pauseAfter: _pauseAfter(repetition, index, steps.length),
        ),
  ];

  static Duration _pauseAfter(int repetition, int step, int length) {
    if (step < length - 1) return paceOf(repetition).stepGap;
    if (repetition < repetitions) return repetitionGap;
    return Duration.zero; // The last strike: the grade comes at once.
  }

  /// F19, F23: the next series. [candidates] are in review order (D7);
  /// those already reviewed in this session are left out, so « Continuer »
  /// never brings the same combo back.
  static List<Combo> series(
    List<Combo> candidates,
    Set<int> reviewed, {
    int size = seriesSize,
  }) => candidates.where((c) => !reviewed.contains(c.id)).take(size).toList();
}

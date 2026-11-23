import 'package:cadence/models/combo.dart';

/// The three speeds of the voice (D10). Fixed in the code, tuned by ear on
/// the Pixel. The pace mostly comes from shorter calls ([Drill.call]): the
/// voice itself is only a little faster.
enum Pace {
  slow('Lent', speed: 1, stepGap: Duration(milliseconds: 500)),
  medium('Moyen', speed: 1.1, stepGap: Duration(milliseconds: 250)),
  fast('Rapide', speed: 1.2, stepGap: Duration(milliseconds: 100));

  const Pace(this.label, {required this.speed, required this.stepGap});

  final String label;

  /// The speed of the recorded voice: 1 as recorded, 1.2 is 20 % faster
  /// (at the same pitch).
  final double speed;

  /// The silence after each strike: the faster, the shorter.
  final Duration stepGap;
}

/// One thing the voice says: [step], at [index] (from 0) in the combo, in
/// [repetition] (from 1), then a silence of [pauseAfter]. A record, like
/// `ReviewSummary`.
typedef Cue = ({
  int repetition,
  int index,
  ComboStep step,
  Pace pace,
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

  /// D10: what the voice says for [step] at [pace], like a coach: all of it
  /// when slow (« Crochet arrière au corps »), the target in one word when
  /// medium (« Crochet corps »), the technique alone when fast
  /// (« Crochet »). The side and the target are then remembered, not heard.
  static String call(ComboStep step, Pace pace) => switch (pace) {
    Pace.slow => step.label,
    Pace.medium => [
      step.technique.name,
      ?step.saidTarget?.shortLabel,
    ].join(' '),
    Pace.fast => step.technique.name,
  };

  /// F20: everything the voice says for [steps], in order: each step one
  /// after the other, 12 times.
  static List<Cue> cues(List<ComboStep> steps) => [
    for (var repetition = 1; repetition <= repetitions; repetition++)
      for (final (index, step) in steps.indexed)
        (
          repetition: repetition,
          index: index,
          step: step,
          pace: paceOf(repetition),
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

import 'package:cadence/models/combo.dart';

enum Pace {
  slow('Lent', speed: 1, stepGap: Duration(milliseconds: 500)),
  medium('Moyen', speed: 1.1, stepGap: Duration(milliseconds: 250)),
  fast('Rapide', speed: 1.2, stepGap: Duration(milliseconds: 100));

  const Pace(this.label, {required this.speed, required this.stepGap});

  final String label;

  final double speed;

  final Duration stepGap;
}

typedef Cue = ({
  int repetition,
  int stepIndex,
  ComboStep step,
  Pace pace,
  Duration pauseAfter,
});

abstract final class Drill {
  static const repetitions = 12;

  static const repetitionsPerPace = repetitions ~/ 3;

  static const repetitionGap = Duration(milliseconds: 1000);

  static const seriesSize = 5;

  static Pace paceOf(int repetition) =>
      Pace.values[(repetition - 1) ~/ repetitionsPerPace];

  static String announcement(ComboStep step, Pace pace) => switch (pace) {
    Pace.slow => step.label,
    Pace.medium => [
      step.technique.name,
      ?step.saidTarget?.shortLabel,
    ].join(' '),
    Pace.fast => step.technique.name,
  };

  static List<Cue> cues(List<ComboStep> steps) => [
    for (var repetition = 1; repetition <= repetitions; repetition++)
      for (final (index, step) in steps.indexed)
        (
          repetition: repetition,
          stepIndex: index,
          step: step,
          pace: paceOf(repetition),
          pauseAfter: _pauseAfter(repetition, index, steps.length),
        ),
  ];

  static Duration _pauseAfter(int repetition, int stepIndex, int stepCount) {
    if (stepIndex < stepCount - 1) return paceOf(repetition).stepGap;
    if (repetition < repetitions) return repetitionGap;
    return Duration.zero;
  }

  static List<Combo> series(
    List<Combo> candidates,
    Set<int> reviewedIds, {
    int size = seriesSize,
  }) => candidates
      .where((combo) => !reviewedIds.contains(combo.id))
      .take(size)
      .toList();
}

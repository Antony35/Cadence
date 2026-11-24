import 'package:cadence/models/drill.dart';
import 'package:cadence/models/technique.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('T7 — paces (D10)', () {
    test('4 slow, 4 medium, 4 fast repetitions', () {
      expect(
        [for (var r = 1; r <= 12; r++) Drill.paceOf(r)],
        [
          ...List.filled(4, Pace.slow),
          ...List.filled(4, Pace.medium),
          ...List.filled(4, Pace.fast),
        ],
      );
    });

    test('the faster the pace, the quicker the voice and the gap', () {
      expect(Pace.slow.speed, lessThan(Pace.medium.speed));
      expect(Pace.medium.speed, lessThan(Pace.fast.speed));
      expect(Pace.slow.stepGap, greaterThan(Pace.medium.stepGap));
      expect(Pace.medium.stepGap, greaterThan(Pace.fast.stepGap));
    });
  });

  group('T7 — calls (D10)', () {
    final hook = step('hook', side: Side.rear, target: Target.body);

    test('all of it when slow, less and less when faster', () {
      expect(Drill.announcement(hook, Pace.slow), 'Crochet arrière au corps');
      expect(Drill.announcement(hook, Pace.medium), 'Crochet corps');
      expect(Drill.announcement(hook, Pace.fast), 'Crochet');
    });

    test('the target is said as soon as it was chosen, even the default '
        'one', () {
      final hookHead = step('hook', target: Target.head);
      expect(
        Drill.announcement(hookHead, Pace.slow),
        'Crochet avant à la tête',
      );
      expect(Drill.announcement(hookHead, Pace.medium), 'Crochet tête');
    });

    test('nothing to choose, the same call at every pace', () {
      for (final pace in Pace.values) {
        expect(Drill.announcement(step('pivot'), pace), 'Pivot');
      }
    });
  });

  group('T7 — cues (F20)', () {
    final steps = [step('jab'), step('cross'), step('hook')];
    final cues = Drill.cues(steps);

    test('each step in order, 12 times', () {
      expect(cues, hasLength(36));
      expect(cues.take(3).map((c) => c.step.label), [
        'Jab à la tête',
        'Direct à la tête',
        'Crochet avant à la tête',
      ]);
      expect(cues.map((c) => c.repetition).toSet(), hasLength(12));
      expect(cues.last.repetition, 12);
      expect(cues.last.stepIndex, 2);
    });

    test('the pace follows the repetition', () {
      expect(cues[0].pace, Pace.slow);
      expect(cues[12].pace, Pace.medium); // Repetition 5.
      expect(cues[35].pace, Pace.fast);
    });

    test('a short gap between strikes, a breath between repetitions', () {
      expect(cues[0].pauseAfter, Pace.slow.stepGap);
      expect(cues[2].pauseAfter, Drill.repetitionGap);
      expect(cues[33].pauseAfter, Pace.fast.stepGap);
      expect(cues.last.pauseAfter, Duration.zero);
    });

    test('each cue carries its step, for the clips of the voice', () {
      final hook = Drill.cues([step('hook'), step('jab')]).first;
      expect(hook.step, step('hook'));
    });
  });

  group('T7 — series (F19, F23)', () {
    final due = DateTime(2026, 11, 23);
    final combos = [for (var id = 1; id <= 7; id++) combo(id: id, dueOn: due)];

    test('5 combos per series, in the given order', () {
      expect(Drill.series(combos, {}, size: 5).map((c) => c.id), [
        1,
        2,
        3,
        4,
        5,
      ]);
    });

    test('« Continuer » leaves out the combos already reviewed', () {
      final reviewed = {1, 2, 3, 4, 5};
      expect(Drill.series(combos, reviewed, size: 5).map((c) => c.id), [6, 7]);
      expect(Drill.series(combos.take(5).toList(), reviewed, size: 5), isEmpty);
    });
  });
}

import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/models/technique.dart';

/// Ten realistic combos, to try the app on a phone and for the oral demo.
///
/// Loaded only when the app is started with
/// `flutter run --dart-define=CADENCE_DEMO=true`, and only into an empty
/// notebook: a real user starts with nothing. Written through the
/// repositories, like the form will, so the data obeys every rule.
abstract final class DemoData {
  /// Read at compile time from `--dart-define`; false by default.
  static const enabled = bool.fromEnvironment('CADENCE_DEMO');

  static Future<void> loadIfEmpty({
    required TechniqueRepository techniques,
    required ComboRepository combos,
    required ReviewRepository reviews,
    required DateTime now,
  }) async {
    if ((await combos.findAll()).isNotEmpty) return;

    final bySlug = {
      for (final technique in await techniques.findAll())
        technique.slug: technique,
    };
    final today = dateOnly(now);
    // An evening class: the hour does not matter, only the day.
    DateTime daysAgo(int days) =>
        addDays(today, -days).add(const Duration(hours: 20));

    for (final sample in _samples) {
      var combo = await combos.create(
        name: sample.name,
        steps: [for (final step in sample.steps) step.build(bySlug)],
        now: daysAgo(sample.createdDaysAgo),
      );
      for (final (days, grade) in sample.reviews) {
        combo = await reviews.record(combo, grade, now: daysAgo(days));
      }
    }
  }

  // Due dates, counted from today: 2 due today, 3 overdue, 5 later.
  static const _samples = [
    // Due today.
    _Sample(createdDaysAgo: 1, [
      _Step('jab'),
      _Step('cross'),
      _Step('low_kick'),
    ]),
    // Box 2, overdue by one day.
    _Sample(
      name: 'Fin de round',
      createdDaysAgo: 6,
      reviews: [(4, Grade.good)],
      [
        _Step('jab'),
        _Step('hook', side: Side.rear, target: Target.body),
        _Step('low_kick'),
      ],
    ),
    // Overdue by two days.
    _Sample(createdDaysAgo: 3, [_Step('teep'), _Step('jab'), _Step('cross')]),
    // Box 4, due in 7 days.
    _Sample(
      name: 'Contre du low',
      createdDaysAgo: 12,
      reviews: [(10, Grade.good), (7, Grade.easy)],
      [_Step('shin_block'), _Step('cross'), _Step('hook'), _Step('low_kick')],
    ),
    // Box 2, due in 2 days.
    _Sample(
      name: 'Sortie de coin',
      createdDaysAgo: 2,
      reviews: [(1, Grade.good)],
      [_Step('slip'), _Step('uppercut'), _Step('step_off')],
    ),
    // Back to box 1 after a hard review, then up again: box 3.
    _Sample(
      name: 'Travail au clinch',
      createdDaysAgo: 20,
      reviews: [
        (19, Grade.good),
        (16, Grade.hard),
        (8, Grade.good),
        (5, Grade.good),
      ],
      [
        _Step('clinch'),
        _Step('knee_clinch'),
        _Step('knee_clinch', side: Side.lead),
        _Step('elbow_horizontal'),
      ],
    ),
    // Created today: due tomorrow.
    _Sample(createdDaysAgo: 0, [
      _Step('jab'),
      _Step('cross'),
      _Step('hook'),
      _Step('cross'),
    ]),
    // Box 5, due in 8 days.
    _Sample(
      name: 'Middle et pivot',
      createdDaysAgo: 30,
      reviews: [(29, Grade.easy), (22, Grade.easy)],
      [
        _Step('middle_kick', side: Side.lead),
        _Step('pivot'),
        _Step('middle_kick'),
      ],
    ),
    // Due today.
    _Sample(name: 'Superman', createdDaysAgo: 1, [
      _Step('low_kick', side: Side.lead),
      _Step('superman_punch'),
      _Step('high_kick'),
    ]),
    // Eight steps: the list shows six thumbnails, then « +2 ».
    _Sample(name: 'Série longue', createdDaysAgo: 2, [
      _Step('jab'),
      _Step('cross'),
      _Step('hook'),
      _Step('uppercut'),
      _Step('low_kick'),
      _Step('teep'),
      _Step('step_back'),
      _Step('jab', target: Target.body),
    ]),
  ];
}

class _Sample {
  const _Sample(
    this.steps, {
    required this.createdDaysAgo,
    this.name,
    this.reviews = const [],
  });

  final String? name;
  final List<_Step> steps;
  final int createdDaysAgo;

  /// (days ago, grade), oldest first.
  final List<(int, Grade)> reviews;
}

/// A step by slug; the technique's default side and target when not given.
class _Step {
  const _Step(this.slug, {this.side, this.target});

  final String slug;
  final Side? side;
  final Target? target;

  ComboStep build(Map<String, Technique> bySlug) {
    final technique = bySlug[slug]!;
    return ComboStep(
      technique: technique,
      side: side ?? technique.defaultSide,
      target: target ?? technique.defaultTarget,
    );
  }
}

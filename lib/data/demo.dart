import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/combo.dart';
import 'package:cadence/models/dates.dart';
import 'package:cadence/models/review.dart';
import 'package:cadence/models/technique.dart';

abstract final class DemoData {
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

  static const _samples = [
    _Sample(createdDaysAgo: 1, [
      _Step('jab'),
      _Step('cross'),
      _Step('low_kick'),
    ]),
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
    _Sample(createdDaysAgo: 3, [_Step('teep'), _Step('jab'), _Step('cross')]),
    _Sample(
      name: 'Contre du low',
      createdDaysAgo: 12,
      reviews: [(10, Grade.good), (7, Grade.easy)],
      [_Step('shin_block'), _Step('cross'), _Step('hook'), _Step('low_kick')],
    ),
    _Sample(
      name: 'Sortie de coin',
      createdDaysAgo: 2,
      reviews: [(1, Grade.good)],
      [_Step('slip'), _Step('uppercut'), _Step('step_off')],
    ),
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
    _Sample(createdDaysAgo: 0, [
      _Step('jab'),
      _Step('cross'),
      _Step('hook'),
      _Step('cross'),
    ]),
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
    _Sample(name: 'Superman', createdDaysAgo: 1, [
      _Step('low_kick', side: Side.lead),
      _Step('superman_punch'),
      _Step('high_kick'),
    ]),
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

  final List<(int, Grade)> reviews;
}

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

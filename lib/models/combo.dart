import 'package:cadence/models/technique.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'combo.freezed.dart';

@freezed
class ComboStep with _$ComboStep {
  ComboStep({required this.technique, this.side, this.target}) {
    if (!_accepts(technique.sides, side)) {
      throw ArgumentError.value(side, 'side', 'refused by ${technique.slug}');
    }
    if (!_accepts(technique.targets, target)) {
      throw ArgumentError.value(
        target,
        'target',
        'refused by ${technique.slug}',
      );
    }
  }

  factory ComboStep.withDefaults(Technique technique) => ComboStep(
    technique: technique,
    side: technique.defaultSide,
    target: technique.defaultTarget,
  );

  final Technique technique;
  final Side? side;
  final Target? target;

  Side? get saidSide => technique.sides.length > 1 ? side : null;

  // Even the default target: a beginner must know where to strike.
  Target? get saidTarget => technique.targets.length > 1 ? target : null;

  String get label =>
      [technique.name, ?saidSide?.label, ?saidTarget?.label].join(' ');

  static bool _accepts<T>(Set<T> accepted, T? value) =>
      value == null ? accepted.isEmpty : accepted.contains(value);

  String get _key =>
      '${technique.slug}:${side?.name ?? '-'}:${target?.name ?? '-'}';
}

@freezed
class Combo with _$Combo {
  const Combo({
    required this.id,
    required this.steps,
    required this.box,
    required this.dueOn,
    required this.createdAt,
    required this.updatedAt,
    this.name,
  });

  final int id;

  final String? name;

  final List<ComboStep> steps;

  final int box;

  final DateTime dueOn;

  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName => ComboRules.displayName(name, steps);

  String get signature => ComboRules.signature(steps);
}

enum ComboError { tooFewSteps, tooManySteps, nameTooLong }

abstract final class ComboRules {
  static const minSteps = 2;
  static const maxSteps = 12;
  static const maxNameLength = 60;

  static String displayName(String? name, List<ComboStep> steps) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return steps.map((step) => step.label).join(' · ');
  }

  // Stored in a UNIQUE column, which forbids duplicate sequences.
  static String signature(List<ComboStep> steps) =>
      steps.map((step) => step._key).join('|');

  static ComboError? validate(String? name, List<ComboStep> steps) {
    if (steps.length < minSteps) return ComboError.tooFewSteps;
    if (steps.length > maxSteps) return ComboError.tooManySteps;
    if ((name?.trim().length ?? 0) > maxNameLength) {
      return ComboError.nameTooLong;
    }
    return null;
  }
}

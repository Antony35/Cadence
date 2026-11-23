import 'package:cadence/models/technique.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'combo.freezed.dart';

/// One step of a combo: a technique, thrown from a side, to a target.
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

  /// The step with the technique's default side and target.
  factory ComboStep.withDefaults(Technique technique) => ComboStep(
    technique: technique,
    side: technique.defaultSide,
    target: technique.defaultTarget,
  );

  final Technique technique;
  final Side? side;
  final Target? target;

  /// The side, said only when the technique accepts two.
  Side? get saidSide => technique.sides.length > 1 ? side : null;

  /// The target, said only when it is not the default one.
  Target? get saidTarget => target != technique.defaultTarget ? target : null;

  /// « Crochet arrière au corps »: the name, [saidSide] and [saidTarget].
  String get label =>
      [technique.name, ?saidSide?.label, ?saidTarget?.label].join(' ');

  /// A value is accepted if it belongs to [accepted], or if it is empty and
  /// there is nothing to accept.
  static bool _accepts<T>(Set<T> accepted, T? value) =>
      value == null ? accepted.isEmpty : accepted.contains(value);

  /// Part of the D8 signature: `hook:rear:body`, `-` for an empty value.
  String get _key =>
      '${technique.slug}:${side?.name ?? '-'}:${target?.name ?? '-'}';
}

/// A combo saved in the database. Before saving, the form only handles a name
/// and a list of steps: a [Combo] always exists in the database.
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

  /// Optional name; when empty, [displayName] is built from the steps.
  final String? name;

  final List<ComboStep> steps;

  /// Leitner box, 1 to 6 (D5).
  final int box;

  /// Next review day, at midnight (D9).
  final DateTime dueOn;

  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName => ComboRules.displayName(name, steps);

  String get signature => ComboRules.signature(steps);
}

/// Why a combo cannot be saved (F11). The screen picks the French message.
enum ComboError { tooFewSteps, tooManySteps, nameTooLong }

/// Rules on a name and a list of steps, shared by [Combo] and the form.
abstract final class ComboRules {
  static const minSteps = 2;
  static const maxSteps = 12;
  static const maxNameLength = 60;

  /// D4: the name if filled in, else the step labels joined by « · ».
  static String displayName(String? name, List<ComboStep> steps) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return steps.map((step) => step.label).join(' · ');
  }

  /// D8: the sequence of (technique, side, target), without the name.
  /// Readable on purpose (`jab:lead:head|cross:rear:head`): the database
  /// stores it in a unique column, which forbids duplicates.
  static String signature(List<ComboStep> steps) =>
      steps.map((step) => step._key).join('|');

  /// F11: the first reason why the combo cannot be saved, or null.
  static ComboError? validate(String? name, List<ComboStep> steps) {
    if (steps.length < minSteps) return ComboError.tooFewSteps;
    if (steps.length > maxSteps) return ComboError.tooManySteps;
    if ((name?.trim().length ?? 0) > maxNameLength) {
      return ComboError.nameTooLong;
    }
    return null;
  }
}

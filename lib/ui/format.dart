import 'package:cadence/models/dates.dart';
import 'package:cadence/models/technique.dart';
import 'package:intl/intl.dart';

// French wording of computed values. The calculations stay in `models/`:
// these functions only choose the words.

/// F3: « En retard », « Aujourd'hui », « Demain », « Dans 5 j ».
String dueLabel(DateTime dueOn, DateTime today) {
  final days = daysBetween(today, dueOn);
  return switch (days) {
    < 0 => 'En retard',
    0 => "Aujourd'hui",
    1 => 'Demain',
    _ => 'Dans $days j',
  };
}

/// « 0 enchaînement », « 1 enchaînement », « 12 enchaînements »: in French,
/// 0 and 1 take the singular.
String plural(int count, String singular, String plural) =>
    '$count ${count < 2 ? singular : plural}';

/// F25: « avant ou arrière », or null for a technique without side.
String? sidesText(Set<Side> sides) => sides.isEmpty
    ? null
    : _or([
        for (final side in Side.values)
          if (sides.contains(side)) side.label,
      ]);

/// F25: « à la tête ou au corps », or null when the target is in the name
/// (Low kick).
String? targetsText(Set<Target> targets) => targets.isEmpty
    ? null
    : _or([
        for (final target in Target.values)
          if (targets.contains(target)) target.label,
      ]);

/// « a », « a ou b », « a, b ou c ».
String _or(List<String> words) => words.length < 2
    ? words.join()
    : '${words.sublist(0, words.length - 1).join(', ')} ou ${words.last}';

/// F16: « 24 novembre 2026 ». The French month names come from `intl`,
/// loaded with the French locale of the app.
String dayLabel(DateTime day) => DateFormat('d MMMM y', 'fr').format(day);

/// The number of a step, on two digits like a round: « 01 », « 12 ».
String stepNumber(int index) => (index + 1).toString().padLeft(2, '0');

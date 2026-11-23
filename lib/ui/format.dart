import 'package:cadence/models/dates.dart';
import 'package:cadence/models/technique.dart';
import 'package:intl/intl.dart';

String dueLabel(DateTime dueOn, DateTime today) {
  final days = daysBetween(today, dueOn);
  return switch (days) {
    < 0 => 'En retard',
    0 => "Aujourd'hui",
    1 => 'Demain',
    _ => 'Dans $days j',
  };
}

String plural(int count, String singular, String plural) =>
    '$count ${count < 2 ? singular : plural}';

String? sidesText(Set<Side> sides) => sides.isEmpty
    ? null
    : _or([
        for (final side in Side.values)
          if (sides.contains(side)) side.label,
      ]);

String? targetsText(Set<Target> targets) => targets.isEmpty
    ? null
    : _or([
        for (final target in Target.values)
          if (targets.contains(target)) target.label,
      ]);

String _or(List<String> words) => words.length < 2
    ? words.join()
    : '${words.sublist(0, words.length - 1).join(', ')} ou ${words.last}';

String dayLabel(DateTime day) => DateFormat('d MMMM y', 'fr').format(day);

String stepNumber(int index) => (index + 1).toString().padLeft(2, '0');

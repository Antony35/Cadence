import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 23, 21);

  test('F3 — the next review, in words', () {
    expect(dueLabel(DateTime(2026, 11, 20), today), 'En retard');
    expect(dueLabel(DateTime(2026, 11, 23), today), "Aujourd'hui");
    expect(dueLabel(DateTime(2026, 11, 24), today), 'Demain');
    expect(dueLabel(DateTime(2026, 11, 28), today), 'Dans 5 j');
  });

  test('0 and 1 take the singular', () {
    expect(plural(0, 'enchaînement', 'enchaînements'), '0 enchaînement');
    expect(plural(1, 'enchaînement', 'enchaînements'), '1 enchaînement');
    expect(plural(2, 'enchaînement', 'enchaînements'), '2 enchaînements');
  });

  test('F25 — sides and targets of a technique', () {
    expect(sidesText({Side.rear, Side.lead}), 'avant ou arrière');
    expect(sidesText({}), isNull);
    expect(
      targetsText(Target.values.toSet()),
      'à la tête, au corps ou à la cuisse',
    );
    expect(targetsText({Target.head}), 'à la tête');
  });
}

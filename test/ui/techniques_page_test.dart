import 'package:cadence/ui/widgets/technique_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';
import 'pump_app.dart';

void main() {
  testWidgets('F24, F25 — from the menu to a technique sheet', (tester) async {
    final combos = FakeComboRepository([
      combo(
        name: 'Ouverture au teep',
        steps: [step('teep'), step('jab')],
        dueOn: DateTime(2026, 11, 25),
      ),
    ]);
    await pumpApp(tester, combos: combos);

    // The menu opens with a slide: wait for each animation to end. Allowed
    // here: no spinner turns on these screens.
    await tester.tap(find.byTooltip('Ouvrir le menu de navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Techniques'));
    await tester.pumpAndSettle();
    expect(find.byType(TechniqueGrid), findsOneWidget);
    expect(find.text('Jab'), findsOneWidget);

    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'teep');
    await tester.pump();
    expect(find.text('Jab'), findsNothing);

    await tester.tap(find.text('Teep'));
    await tester.pumpAndSettle();
    expect(find.text('Côté : avant ou arrière'), findsOneWidget);
    expect(find.text('Utilisée dans'), findsOneWidget);
    expect(find.text('Ouverture au teep'), findsOneWidget);
  });

  testWidgets('F24 — a family without the text: no result', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Ouvrir le menu de navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Techniques'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Coudes'));
    await tester.pump();
    expect(find.text('Coude horizontal'), findsOneWidget);
    expect(find.text('Jab'), findsNothing);
  });
}

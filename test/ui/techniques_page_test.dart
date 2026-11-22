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
    await tester.tap(find.text('TECHNIQUES'));
    await tester.pumpAndSettle();
    expect(find.byType(TechniqueGrid), findsOneWidget);
    expect(find.text('JAB'), findsOneWidget);

    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'teep');
    await tester.pump();
    expect(find.text('JAB'), findsNothing);

    await tester.tap(find.text('TEEP'));
    await tester.pumpAndSettle();
    expect(find.text('avant ou arrière'), findsOneWidget);
    expect(find.text('UTILISÉE DANS'), findsOneWidget);
    expect(find.text('Ouverture au teep'), findsOneWidget);
  });

  testWidgets('F24 — a family without the text: no result', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Ouvrir le menu de navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TECHNIQUES'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('COUDES'));
    await tester.pump();
    expect(find.text('COUDE HORIZONTAL'), findsOneWidget);
    expect(find.text('JAB'), findsNothing);
  });

  testWidgets('V4 — 3 columns on a 320 px phone with doubled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester, keepView: true);
    await tester.tap(find.byTooltip('Ouvrir le menu de navigation'));
    await tester.pumpAndSettle();
    // On so small a screen, the menu scrolls below the poster.
    await tester.scrollUntilVisible(
      find.text('TECHNIQUES'),
      100,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('TECHNIQUES'));
    await tester.pumpAndSettle();

    // An overflow would have failed the test with an exception.
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(find.text('JAB'), findsOneWidget);
  });
}

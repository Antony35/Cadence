import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';
import 'pump_app.dart';

void main() {
  late FakeComboRepository combos;

  setUp(() {
    combos = FakeComboRepository([
      combo(
        name: 'Base',
        steps: [step('jab'), step('hook'), step('low_kick')],
        dueOn: DateTime(2026, 11, 25),
        createdAt: DateTime(2026, 11, 20, 19),
      ),
    ]);
  });

  Future<void> openSheet(WidgetTester tester) async {
    await pumpApp(
      tester,
      combos: combos,
      reviews: FakeReviewRepository()..counts = {1: 2},
    );
    await tester.tap(find.text('Base'));
    await tester.pumpAndSettle();
  }

  testWidgets('F16 — the sheet: steps, next review, reviews, dates', (
    tester,
  ) async {
    await openSheet(tester);
    expect(find.text('BASE'), findsOneWidget);
    expect(find.text('Dans 2 j · 25 novembre 2026'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('Crochet avant à la tête'), findsOneWidget);
    expect(find.text('2 révisions'), findsOneWidget);
    expect(find.text('20 novembre 2026'), findsNWidgets(2));
  });

  testWidgets('T16 — delete: cancel changes nothing, confirm removes it', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer « Base » ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('BASE'), findsOneWidget);
    expect(combos.combos, hasLength(1));

    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(combos.combos, isEmpty);
    expect(find.text('AUCUN ENCHAÎNEMENT'), findsOneWidget);
  });

  testWidgets('F17 — edit, then the sheet shows the change', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byTooltip('Modifier'));
    await tester.pumpAndSettle();
    expect(find.text('MODIFIER'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Ouverture');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('OUVERTURE'), findsOneWidget);
    expect(combos.combos.single.id, 1);
  });

  testWidgets('a step opens its technique, aligned with the page gutter', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('Crochet avant à la tête'));
    await tester.pumpAndSettle();

    expect(find.text('CROCHET'), findsOneWidget);
    expect(find.text('UTILISÉE DANS'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Base')).dx,
      tester.getTopLeft(find.text('FAMILLE')).dx,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('BASE'), findsOneWidget);
  });

  testWidgets('deleted from its technique sheet: the sheet says it is gone', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('Crochet avant à la tête'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Base'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(
      find.text("Aucun enchaînement ne l'utilise pour l'instant."),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text("Cet enchaînement n'existe plus."), findsOneWidget);
    expect(find.byTooltip('Supprimer'), findsNothing);
  });
}

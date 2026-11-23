import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';
import 'pump_app.dart';

// No spinner turns on these screens once the fakes have answered:
// pumpAndSettle can wait for the end of each animation.

Future<void> openForm(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Ajouter un enchaînement'));
  await tester.pumpAndSettle();
}

/// Touches a tile, then « Ajouter » in the technique window.
Future<void> addFromGrid(WidgetTester tester, String tile) async {
  await tester.tap(find.text(tile));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ajouter'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('T12 — build a combo with the window, save, find it', (
    tester,
  ) async {
    final combos = FakeComboRepository();
    await pumpApp(tester, combos: combos);
    await openForm(tester);
    expect(find.text('NOUVEL ENCHAÎNEMENT'), findsOneWidget);

    await addFromGrid(tester, 'JAB');
    await tester.tap(find.text('CROCHET'));
    await tester.pumpAndSettle();
    // The window offers only what the technique accepts (F9).
    await tester.tap(find.text('arrière'));
    await tester.tap(find.text('au corps'));
    await tester.pump();
    expect(find.text('« Crochet arrière au corps »'), findsOneWidget);
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    expect(find.text('SÉQUENCE 2 / 12'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('NOUVEL ENCHAÎNEMENT'), findsNothing);
    expect(find.text('Jab · Crochet arrière au corps'), findsOneWidget);
    expect(find.text('Enregistré · à réviser demain'), findsOneWidget);
    expect(combos.combos, hasLength(1));
  });

  testWidgets('T13 — one step: the message, the screen stays open', (
    tester,
  ) async {
    final combos = FakeComboRepository();
    await pumpApp(tester, combos: combos);
    await openForm(tester);
    await addFromGrid(tester, 'JAB');

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Ajoutez au moins 2 techniques.'), findsOneWidget);
    expect(find.text('NOUVEL ENCHAÎNEMENT'), findsOneWidget);
    expect(combos.combos, isEmpty);
  });

  testWidgets('a step is corrected, moved and removed from its window', (
    tester,
  ) async {
    await pumpApp(tester);
    await openForm(tester);
    await addFromGrid(tester, 'JAB');
    await addFromGrid(tester, 'DIRECT');

    // The second step (« Direct »), moved before the first.
    await tester.tap(find.text('Direct'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avant'));
    await tester.pumpAndSettle();
    final labels = tester
        .widgetList<Text>(find.textContaining(RegExp(r'^(Jab|Direct)$')))
        .map((t) => t.data);
    expect(labels, ['Direct', 'Jab']);

    await tester.tap(find.text('Jab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();
    expect(find.text('SÉQUENCE 1 / 12'), findsOneWidget);
  });

  testWidgets('F12 — a duplicate, then « Ouvrir l\'existant »', (tester) async {
    final combos = FakeComboRepository([
      combo(name: 'Base', dueOn: DateTime(2026, 11, 25)),
    ]);
    await pumpApp(tester, combos: combos);
    await openForm(tester);
    await addFromGrid(tester, 'JAB');
    await addFromGrid(tester, 'DIRECT');

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Cet enchaînement existe déjà.'), findsOneWidget);

    await tester.tap(find.text("Ouvrir l'existant"));
    await tester.pumpAndSettle();
    expect(find.text('BASE'), findsOneWidget);
    expect(combos.combos, hasLength(1));

    // Deleted from its sheet: back on the main screen, the list is read
    // again only once the sheet is closed, so it no longer shows it.
    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('AUCUN ENCHAÎNEMENT'), findsOneWidget);
  });

  testWidgets('F15 — leaving with unsaved input asks first', (tester) async {
    await pumpApp(tester);
    await openForm(tester);
    await addFromGrid(tester, 'JAB');

    // The Android back button.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Abandonner la saisie ?'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('NOUVEL ENCHAÎNEMENT'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandonner'));
    await tester.pumpAndSettle();
    expect(find.text('AUCUN ENCHAÎNEMENT'), findsOneWidget);
  });

  testWidgets('leaving an untouched form asks nothing', (tester) async {
    await pumpApp(tester);
    await openForm(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('AUCUN ENCHAÎNEMENT'), findsOneWidget);
  });

  testWidgets('V4 — the form and the window on 320 px with doubled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // An overflow fails the test with an exception.
    await pumpApp(tester, keepView: true);
    await openForm(tester);
    // The name field scrolls away: the grid comes up under the sequence.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await addFromGrid(tester, 'JAB');
    await tester.tap(find.text('CROCHET'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter'), findsOneWidget);
  });

  testWidgets('choosing a technique does not bring the keyboard back', (
    tester,
  ) async {
    await pumpApp(tester);
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField), 'Base');
    expect(tester.testTextInput.isVisible, isTrue);

    await addFromGrid(tester, 'JAB');
    expect(tester.testTextInput.isVisible, isFalse);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isFalse);
    expect(find.text('Base'), findsOneWidget);
  });
}

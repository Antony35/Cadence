import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';
import 'pump_app.dart';

void main() {
  late FakeComboRepository combos;

  setUp(() {
    combos = FakeComboRepository([
      combo(id: 1, name: 'Base', dueOn: DateTime(2026, 11, 21)),
      combo(
        id: 2,
        steps: [step('teep'), step('low_kick')],
        dueOn: DateTime(2026, 11, 23),
      ),
      combo(
        id: 3,
        name: 'Clinch',
        steps: [step('clinch'), step('knee_clinch'), step('elbow_horizontal')],
        dueOn: DateTime(2026, 11, 30),
      ),
    ]);
  });

  testWidgets('loading: a spinner, then the list', (tester) async {
    combos.gate = Completer();
    await pumpApp(tester, combos: combos);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    combos.gate!.complete();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Base'), findsOneWidget);
  });

  testWidgets('F1, F3 — the card and the list', (tester) async {
    await pumpApp(tester, combos: combos);

    expect(find.text('02 À RÉVISER'), findsOneWidget);
    expect(find.text('dont 1 en retard · 3 enchaînements'), findsOneWidget);
    expect(find.text('Teep avant au corps · Low kick arrière'), findsOneWidget);
    expect(find.text('EN RETARD'), findsOneWidget);
    expect(find.text("AUJOURD'HUI"), findsOneWidget);
    expect(find.text('DANS 7 J'), findsOneWidget);
  });

  testWidgets('F2 — nothing due today', (tester) async {
    combos.combos = [combo(dueOn: DateTime(2026, 11, 24))];
    await pumpApp(tester, combos: combos);
    expect(find.text("RIEN À RÉVISER AUJOURD'HUI"), findsOneWidget);
    expect(find.text('Réviser en avance'), findsOneWidget);
  });

  testWidgets('empty: the invitation, not a list', (tester) async {
    await pumpApp(tester);
    expect(find.text('AUCUN ENCHAÎNEMENT'), findsOneWidget);
    expect(find.text('Ajouter un enchaînement'), findsOneWidget);
  });

  testWidgets('T14 — a read error, then « Réessayer » (S1, S3)', (
    tester,
  ) async {
    combos.error = Exception('disk I/O error');
    await pumpApp(tester, combos: combos);
    expect(find.text('Impossible de lire vos enchaînements.'), findsOneWidget);
    expect(find.text('AUCUN ENCHAÎNEMENT'), findsNothing);

    combos.error = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(find.text('Base'), findsOneWidget);
  });

  testWidgets('F4, S2 — a search without result, then « Tout effacer »', (
    tester,
  ) async {
    await pumpApp(tester, combos: combos);

    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'genou');
    await tester.pump();
    expect(find.text('Clinch'), findsOneWidget);
    expect(find.text('Base'), findsNothing);

    await tester.enterText(find.byType(TextField), 'superman');
    await tester.pump();
    expect(find.text('AUCUN RÉSULTAT'), findsOneWidget);

    await tester.tap(find.text('Tout effacer'));
    await tester.pump();
    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Clinch'), findsOneWidget);
  });

  testWidgets('F4 — the family filter', (tester) async {
    await pumpApp(tester, combos: combos);
    await tester.tap(find.text('POINGS'));
    await tester.pump();
    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Teep avant au corps · Low kick arrière'), findsNothing);
  });

  testWidgets('back to the foreground, the list is read again', (tester) async {
    await pumpApp(tester, combos: combos);
    final reads = combos.reads;
    // The phone goes to sleep, then wakes up: the states in their order.
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(combos.reads, reads + 1);
  });

  testWidgets('V4 — the main screen on a 320 px phone with doubled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // An overflow fails the test with an exception.
    await pumpApp(tester, combos: combos, keepView: true);
    expect(find.text('02 À RÉVISER'), findsOneWidget);
  });
}

import 'package:cadence/models/drill.dart';
import 'package:cadence/models/review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';
import 'pump_app.dart';

// The session runs on timers (the silences between strikes). A widget test
// runs in a fake time: `pump(duration)` moves it forward at once, firing
// every timer due on the way. `pumpAndSettle` is not used: it would stop at
// the first silence without a frame.

/// Touches the button of the « À réviser » card and waits for the page.
Future<void> openSession(
  WidgetTester tester, [
  String button = 'Commencer',
]) async {
  await tester.tap(find.text(button));
  await tester.pump(); // The session reads its combos.
  await tester.pump(const Duration(milliseconds: 500)); // The page slides in.
}

/// « Commencer » on the session page: the voice says the first strike. The
/// main screen below is offstage, so only this button is found.
Future<void> startCombo(WidgetTester tester) async {
  await tester.tap(find.text('Commencer'));
  await tester.pump();
}

/// Opens the session and starts its first combo.
Future<void> startSession(
  WidgetTester tester, [
  String button = 'Commencer',
]) async {
  await openSession(tester, button);
  await startCombo(tester);
}

/// Longer than the 12 repetitions of a short combo.
const allRepetitions = Duration(minutes: 2);

final today = DateTime(2026, 11, 23);

void main() {
  testWidgets('T15 — each strike 12 times in three paces, then the grade '
      'is saved', (tester) async {
    final combos = FakeComboRepository([combo(name: 'Base', dueOn: today)]);
    final reviews = FakeReviewRepository(combos);
    final speaker = FakeSpeaker();
    await pumpApp(tester, combos: combos, reviews: reviews, speaker: speaker);

    await openSession(tester);
    expect(find.text('ENCHAÎNEMENT 1 / 1'), findsOneWidget);
    // F20: nothing is said before « Commencer ».
    await tester.pump(allRepetitions);
    expect(speaker.said, isEmpty);

    await startCombo(tester);
    expect(find.text('LENT'), findsOneWidget);
    expect(speaker.said.first, ('Djab', Pace.slow));

    await tester.pump(allRepetitions);
    expect(speaker.said, hasLength(24));
    expect(speaker.said.take(2).map((s) => s.$1), ['Djab', 'Direct']);
    for (final pace in Pace.values) {
      expect(speaker.said.where((s) => s.$2 == pace), hasLength(8));
    }
    expect(find.text("COMMENT C'ÉTAIT ?"), findsOneWidget);
    // Box 1 → box 2: three days.
    expect(find.text('Dans 3 j'), findsOneWidget);

    await tester.tap(find.text('Correct'));
    await tester.pump();
    expect(reviews.recorded, [(1, Grade.good)]);
    expect(find.text('SÉANCE TERMINÉE'), findsOneWidget);
    expect(find.text('1 enchaînement révisé'), findsOneWidget);
    expect(find.text('Continuer'), findsNothing);

    await tester.tap(find.text('Terminer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Back on the main screen, read again: nothing left to review.
    expect(find.text("RIEN À RÉVISER AUJOURD'HUI"), findsOneWidget);
  });

  testWidgets('F21 — pause stops the voice, resume says the strike again', (
    tester,
  ) async {
    final speaker = FakeSpeaker();
    await pumpApp(
      tester,
      combos: FakeComboRepository([combo(dueOn: today)]),
      speaker: speaker,
    );
    await startSession(tester);
    expect(speaker.said, hasLength(1));

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('EN PAUSE'), findsOneWidget);
    expect(speaker.stops, greaterThan(0));

    await tester.pump(allRepetitions);
    expect(speaker.said, hasLength(1));

    await tester.tap(find.text('Reprendre'));
    await tester.pump();
    expect(speaker.said.map((s) => s.$1), ['Djab', 'Djab']);
    expect(find.text('LENT'), findsOneWidget);
  });

  testWidgets('F21 — hidden in the background, the session pauses', (
    tester,
  ) async {
    final speaker = FakeSpeaker();
    await pumpApp(
      tester,
      combos: FakeComboRepository([combo(dueOn: today)]),
      speaker: speaker,
    );
    await startSession(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(find.text('EN PAUSE'), findsOneWidget);

    // Back to the foreground: still paused, the voice waits for a touch.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(allRepetitions);
    expect(find.text('EN PAUSE'), findsOneWidget);
    expect(speaker.said, hasLength(1));
  });

  testWidgets('S4 — without a French voice, the repetitions go on silently', (
    tester,
  ) async {
    final speaker = FakeSpeaker(available: false);
    await pumpApp(
      tester,
      combos: FakeComboRepository([combo(dueOn: today)]),
      speaker: speaker,
    );
    await startSession(tester);
    expect(
      find.text('Voix indisponible : les répétitions défilent sans le son.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(minutes: 5));
    expect(find.text("COMMENT C'ÉTAIT ?"), findsOneWidget);
    expect(speaker.said, isEmpty);
  });

  testWidgets('F19, F23 — series of 5, then « Continuer » with the rest', (
    tester,
  ) async {
    final combos = FakeComboRepository([
      for (var id = 1; id <= 6; id++)
        combo(id: id, name: 'Combo $id', dueOn: today),
    ]);
    await pumpApp(
      tester,
      combos: combos,
      reviews: FakeReviewRepository(combos),
    );
    await startSession(tester);

    for (var i = 1; i <= 5; i++) {
      expect(find.text('ENCHAÎNEMENT $i / 5'), findsOneWidget);
      await tester.tap(find.text('Passer à la note'));
      await tester.pump();
      await tester.tap(find.text('Facile'));
      await tester.pump();
      if (i < 5) await startCombo(tester);
    }
    expect(find.text('5 enchaînements révisés'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pump();
    expect(find.text('ENCHAÎNEMENT 1 / 1'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    expect(find.text('Combo 6'), findsOneWidget);
  });

  testWidgets('F19 — « Réviser en avance » when nothing is due', (
    tester,
  ) async {
    await pumpApp(
      tester,
      combos: FakeComboRepository([
        combo(name: 'Plus tard', dueOn: DateTime(2026, 11, 30)),
      ]),
    );
    await startSession(tester, 'Réviser en avance');
    expect(find.text('Plus tard'), findsOneWidget);
    expect(find.text('ENCHAÎNEMENT 1 / 1'), findsOneWidget);
  });

  testWidgets('F22 — a refused grade can be given again', (tester) async {
    final combos = FakeComboRepository([combo(dueOn: today)]);
    final reviews = FakeReviewRepository(combos)..error = Exception('disk');
    await pumpApp(tester, combos: combos, reviews: reviews);
    await startSession(tester);

    await tester.tap(find.text('Passer à la note'));
    await tester.pump();
    await tester.tap(find.text('Correct'));
    await tester.pump();
    expect(
      find.text("La note n'a pas été enregistrée : réessayez."),
      findsOneWidget,
    );

    reviews.error = null;
    await tester.tap(find.text('Correct'));
    await tester.pump();
    expect(find.text('SÉANCE TERMINÉE'), findsOneWidget);
  });

  testWidgets('F21 — the screen stays on until « Arrêter »', (tester) async {
    final speaker = FakeSpeaker();
    final awake = FakeScreenAwake();
    await pumpApp(
      tester,
      combos: FakeComboRepository([combo(dueOn: today)]),
      speaker: speaker,
      screenAwake: awake,
    );
    await startSession(tester);
    expect(awake.on, isTrue);

    await tester.tap(find.byTooltip('Arrêter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(awake.on, isFalse);
    expect(speaker.stops, greaterThan(0));
    expect(find.text('CADENCE'), findsOneWidget);
  });
}

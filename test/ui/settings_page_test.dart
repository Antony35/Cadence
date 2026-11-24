import 'package:cadence/models/settings.dart';
import 'package:cadence/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';
import '../models/fixtures.dart';
import 'pump_app.dart';

Future<void> openFromMenu(WidgetTester tester, String entry) async {
  await tester.tap(find.byTooltip('Ouvrir le menu de navigation'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(entry),
    100,
    scrollable: find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.tap(find.text(entry));
  await tester.pumpAndSettle();
}

Brightness brightnessOf(WidgetTester tester) =>
    Theme.of(tester.element(find.text('PARAMÈTRES'))).brightness;

void main() {
  testWidgets('F26, F28 — the chosen theme applies at once and is saved', (
    tester,
  ) async {
    final repository = FakeSettingsRepository();
    await pumpApp(
      tester,
      settings: SettingsController(
        repository: repository,
        initial: const Settings(theme: ThemeChoice.light),
      ),
    );
    await openFromMenu(tester, 'PARAMÈTRES');
    expect(brightnessOf(tester), Brightness.light);

    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    expect(brightnessOf(tester), Brightness.dark);
    expect(repository.stored.theme, ThemeChoice.dark);
  });

  testWidgets('F27 — the counter stops at 20', (tester) async {
    final repository = FakeSettingsRepository();
    await pumpApp(
      tester,
      settings: SettingsController(
        repository: repository,
        initial: const Settings(sessionSize: 19),
      ),
    );
    await openFromMenu(tester, 'PARAMÈTRES');
    expect(find.text('19'), findsOneWidget);

    await tester.tap(find.byTooltip('Un de plus'));
    await tester.pump();
    expect(find.text('20'), findsOneWidget);
    expect(repository.stored.sessionSize, 20);
    final grow = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add_rounded),
    );
    expect(grow.onPressed, isNull);
  });

  testWidgets('F27 — the session takes the chosen size', (tester) async {
    await pumpApp(
      tester,
      combos: FakeComboRepository([
        for (var id = 1; id <= 4; id++)
          combo(id: id, name: 'Combo $id', dueOn: DateTime(2026, 11, 23)),
      ]),
      settings: SettingsController(
        repository: FakeSettingsRepository(),
        initial: const Settings(sessionSize: 2),
      ),
    );
    await tester.tap(find.text('Commencer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ENCHAÎNEMENT 1 / 2'), findsOneWidget);
  });

  testWidgets('F29 — À propos: version, data, licences', (tester) async {
    await pumpApp(tester);
    await openFromMenu(tester, 'À PROPOS');
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.textContaining('compte Google'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Licences'), 100);
    await tester.tap(find.text('Licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  for (final entry in ['PARAMÈTRES', 'À PROPOS']) {
    testWidgets('V4 — $entry on 320 px with doubled text', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(tester, keepView: true);
      await openFromMenu(tester, entry);

      // An overflow would have failed the test with an exception.
      expect(find.text(entry), findsOneWidget);
    });
  }
}

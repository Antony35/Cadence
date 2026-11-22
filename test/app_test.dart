import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui/pump_app.dart';

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold))).brightness;

void main() {
  testWidgets('the app starts on its main screen', (tester) async {
    await pumpApp(tester);
    expect(find.text('CADENCE'), findsOneWidget);
    expect(find.text('AUCUN ENCHAÎNEMENT'), findsOneWidget);
  });

  testWidgets('the app follows the phone light or dark setting', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpApp(tester);
    expect(_brightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    // MaterialApp animates between themes: wait for the end of the
    // transition. The empty state has no spinner.
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);
  });

  testWidgets('screens stop above the Android navigation bar', (tester) async {
    // A 3-button navigation bar of 48 px at the bottom of the screen.
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPadding);

    await pumpApp(tester);
    final screen = tester.getRect(find.byType(Scaffold));
    expect(screen.bottom, 915 - 48);
    final button = tester.getRect(find.byType(FloatingActionButton));
    expect(button.bottom, lessThanOrEqualTo(915 - 48));
  });
}

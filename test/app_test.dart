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
}

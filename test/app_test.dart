import 'package:cadence/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold))).brightness;

void main() {
  testWidgets('the app starts on its home screen', (tester) async {
    await tester.pumpWidget(const CadenceApp());

    expect(find.text('Cadence'), findsOneWidget);
    expect(find.text("Carnet d'enchaînements"), findsOneWidget);
  });

  testWidgets('the app follows the phone light or dark setting', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const CadenceApp());
    expect(_brightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    // MaterialApp animates between themes: wait for the end of the transition.
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);
  });
}

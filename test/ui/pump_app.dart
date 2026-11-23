import 'package:cadence/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

/// Starts the whole app on fake services, on Monday 23 November, on a
/// phone-sized screen (412 × 915, a Pixel), unless [keepView] keeps the
/// size the test has set.
Future<void> pumpApp(
  WidgetTester tester, {
  bool keepView = false,
  FakeComboRepository? combos,
  FakeTechniqueRepository? techniques,
  FakeReviewRepository? reviews,
  FakeSpeaker? speaker,
  FakeScreenAwake? screenAwake,
}) async {
  if (!keepView) {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    CadenceApp(
      techniques: techniques ?? FakeTechniqueRepository(),
      combos: combos ?? FakeComboRepository(),
      reviews: reviews ?? FakeReviewRepository(),
      speaker: speaker ?? FakeSpeaker(),
      screenAwake: screenAwake ?? FakeScreenAwake(),
      clock: FixedClock(),
    ),
  );
  // One more frame: the fake read has answered, the screen shows it.
  await tester.pump();
}

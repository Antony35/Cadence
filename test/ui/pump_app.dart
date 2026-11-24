import 'package:cadence/models/app_info.dart';
import 'package:cadence/models/settings.dart';
import 'package:cadence/state/settings_controller.dart';
import 'package:cadence/state/speaker.dart';
import 'package:cadence/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  bool keepView = false,
  FakeComboRepository? combos,
  FakeTechniqueRepository? techniques,
  FakeReviewRepository? reviews,
  Speaker? speaker,
  FakeScreenAwake? screenAwake,
  SettingsController? settings,
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
      settings:
          settings ??
          SettingsController(
            repository: FakeSettingsRepository(),
            initial: const Settings(),
          ),
      appInfo: const AppInfo(version: '1.0.0'),
      clock: FixedClock(),
    ),
  );
  // One more frame: the fake read has answered, the screen shows it.
  await tester.pump();
}

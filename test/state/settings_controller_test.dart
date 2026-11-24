import 'package:cadence/models/settings.dart';
import 'package:cadence/state/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeSettingsRepository repository;
  late SettingsController controller;

  setUp(() {
    repository = FakeSettingsRepository();
    controller = SettingsController(
      repository: repository,
      initial: const Settings(),
    );
  });

  test('F26, F28 — a theme applies at once and is saved', () async {
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.chooseTheme(ThemeChoice.dark);

    expect(controller.settings.theme, ThemeChoice.dark);
    expect(repository.stored.theme, ThemeChoice.dark);
    expect(notified, 1);
  });

  test('F27 — the session size stays between 1 and 20', () async {
    controller = SettingsController(
      repository: repository,
      initial: const Settings(sessionSize: 20),
    );
    await controller.growSession();
    expect(controller.settings.sessionSize, 20);

    for (var i = 0; i < 30; i++) {
      await controller.shrinkSession();
    }
    expect(controller.settings.sessionSize, 1);
    expect(repository.stored.sessionSize, 1);
  });

  test('a failed save keeps the choice on screen', () async {
    repository.error = Exception('disk');

    await controller.growSession();

    expect(controller.settings.sessionSize, 6);
    expect(repository.stored.sessionSize, 5);
  });
}

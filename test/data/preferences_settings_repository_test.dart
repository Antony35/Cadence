import 'package:cadence/data/preferences/preferences_settings_repository.dart';
import 'package:cadence/models/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesAsync preferences;
  late PreferencesSettingsRepository repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    repository = PreferencesSettingsRepository(preferences);
  });

  test('nothing saved yet: the defaults', () async {
    expect(await repository.load(), const Settings());
  });

  test('F28 — what is saved is read back after a restart', () async {
    const chosen = Settings(theme: ThemeChoice.dark, sessionSize: 12);
    await repository.save(chosen);

    final afterRestart = PreferencesSettingsRepository(
      SharedPreferencesAsync(),
    );
    expect(await afterRestart.load(), chosen);
  });

  test('unknown or out-of-range values fall back to the defaults', () async {
    await preferences.setString(PreferencesSettingsRepository.themeKey, 'neon');
    await preferences.setInt(PreferencesSettingsRepository.sessionSizeKey, 99);

    expect(await repository.load(), const Settings());
  });
}

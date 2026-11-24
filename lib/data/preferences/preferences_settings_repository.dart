import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesSettingsRepository implements SettingsRepository {
  PreferencesSettingsRepository(this._preferences);

  static const themeKey = 'themeMode';
  static const sessionSizeKey = 'sessionSize';

  final SharedPreferencesAsync _preferences;

  @override
  Future<Settings> load() async {
    final themeName = await _preferences.getString(themeKey);
    final sessionSize = await _preferences.getInt(sessionSizeKey);
    return Settings(
      theme: ThemeChoice.values.asNameMap()[themeName] ?? ThemeChoice.system,
      sessionSize: _isValidSessionSize(sessionSize)
          ? sessionSize!
          : Settings.defaultSessionSize,
    );
  }

  @override
  Future<void> save(Settings settings) async {
    await _preferences.setString(themeKey, settings.theme.name);
    await _preferences.setInt(sessionSizeKey, settings.sessionSize);
  }

  static bool _isValidSessionSize(int? size) =>
      size != null &&
      size >= Settings.minSessionSize &&
      size <= Settings.maxSessionSize;
}

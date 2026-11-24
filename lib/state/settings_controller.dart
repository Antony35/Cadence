import 'package:cadence/data/repositories.dart';
import 'package:cadence/models/settings.dart';
import 'package:flutter/foundation.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({required this._repository, required Settings initial})
    : _settings = initial;

  final SettingsRepository _repository;
  Settings _settings;

  Settings get settings => _settings;

  Future<void> chooseTheme(ThemeChoice theme) =>
      _apply(_settings.copyWith(theme: theme));

  Future<void> growSession() async {
    if (_settings.canGrowSession) {
      await _apply(_settings.copyWith(sessionSize: _settings.sessionSize + 1));
    }
  }

  Future<void> shrinkSession() async {
    if (_settings.canShrinkSession) {
      await _apply(_settings.copyWith(sessionSize: _settings.sessionSize - 1));
    }
  }

  // Applied before saving: the screen never waits for the disk. A failed
  // save only loses the choice at the next restart.
  Future<void> _apply(Settings next) async {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    try {
      await _repository.save(next);
    } catch (error) {
      debugPrint('SettingsController.save: $error');
    }
  }
}

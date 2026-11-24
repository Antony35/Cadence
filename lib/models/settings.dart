import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';

enum ThemeChoice {
  system('Système'),
  light('Clair'),
  dark('Sombre');

  const ThemeChoice(this.label);

  final String label;
}

@freezed
class Settings with _$Settings {
  const Settings({
    this.theme = ThemeChoice.system,
    this.sessionSize = defaultSessionSize,
  });

  static const minSessionSize = 1;
  static const maxSessionSize = 20;
  static const defaultSessionSize = 5;

  final ThemeChoice theme;
  final int sessionSize;

  bool get canGrowSession => sessionSize < maxSessionSize;
  bool get canShrinkSession => sessionSize > minSessionSize;
}

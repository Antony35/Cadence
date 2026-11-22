import 'package:cadence/models/technique.dart';
import 'package:flutter/material.dart';

/// The only place where colors are declared. Screens read them through
/// `Theme.of(context).colorScheme`, so switching theme never touches a screen.
///
/// Palette: black and gold, after the gloves of the illustrations.
abstract final class AppTheme {
  static final ThemeData light = _build(lightScheme, CadenceColors.light);
  static final ThemeData dark = _build(darkScheme, CadenceColors.dark);

  /// Bright gold cannot carry small text on a light background (contrast
  /// 2.5:1), so [ColorScheme.primary] is a dark gold and the bright one only
  /// fills [ColorScheme.primaryContainer].
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF7A5A0E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF3DFA2),
    onPrimaryContainer: Color(0xFF2A2000),
    secondary: Color(0xFF1F1B16),
    onSecondary: Color(0xFFF7F5F0),
    secondaryContainer: Color(0xFFEAE4D8),
    onSecondaryContainer: Color(0xFF1F1B16),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFF7F5F0),
    onSurface: Color(0xFF1F1B16),
    onSurfaceVariant: Color(0xFF5C5346),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFBFAF7),
    surfaceContainer: Color(0xFFF1EEE7),
    surfaceContainerHigh: Color(0xFFEAE4D8),
    surfaceContainerHighest: Color(0xFFE3DCCE),
    outline: Color(0xFF857A68),
    outlineVariant: Color(0xFFDDD6C8),
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE0B44C),
    onPrimary: Color(0xFF2A2000),
    primaryContainer: Color(0xFF5A4208),
    onPrimaryContainer: Color(0xFFF8E3A8),
    secondary: Color(0xFFF2EDE4),
    onSecondary: Color(0xFF1F1B16),
    secondaryContainer: Color(0xFF353028),
    onSecondaryContainer: Color(0xFFF2EDE4),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF121110),
    onSurface: Color(0xFFF2EDE4),
    onSurfaceVariant: Color(0xFFC9C1B2),
    surfaceContainerLowest: Color(0xFF1E1C19),
    surfaceContainerLow: Color(0xFF191715),
    surfaceContainer: Color(0xFF24211D),
    surfaceContainerHigh: Color(0xFF2E2A25),
    surfaceContainerHighest: Color(0xFF353028),
    outline: Color(0xFF9A907E),
    outlineVariant: Color(0xFF48423A),
  );

  static ThemeData _build(ColorScheme scheme, CadenceColors cadence) {
    return ThemeData(
      colorScheme: scheme,
      extensions: [cadence],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        // No tint when content scrolls under the bar: the page stays flat.
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

/// The badge colors of a family: [fill] for the disc, [ink] for its icon.
typedef FamilyColors = ({Color fill, Color ink});

/// The colors Material has no slot for: one per family (V3).
///
/// A [ThemeExtension] is added to [ThemeData], so each theme has its own
/// values and screens read them like the others:
/// `CadenceColors.of(context).family(Family.kick)`.
@immutable
class CadenceColors extends ThemeExtension<CadenceColors> {
  const CadenceColors(this.families);

  /// Pale discs with a dark icon of the same hue.
  static const light = CadenceColors({
    Family.punch: (fill: Color(0xFFF6D5CF), ink: Color(0xFF7D2418)),
    Family.elbow: (fill: Color(0xFFF5E0C3), ink: Color(0xFF6E3F0C)),
    Family.kick: (fill: Color(0xFFD3E2F4), ink: Color(0xFF1F4B7A)),
    Family.knee: (fill: Color(0xFFE3D6F0), ink: Color(0xFF54307A)),
    Family.defense: (fill: Color(0xFFD4EBD9), ink: Color(0xFF1F5C33)),
    Family.footwork: (fill: Color(0xFFD9E3E3), ink: Color(0xFF2E4F50)),
  });

  /// Deep discs with a pale icon: the same hues, reversed.
  static const dark = CadenceColors({
    Family.punch: (fill: Color(0xFF5C1F16), ink: Color(0xFFF6D5CF)),
    Family.elbow: (fill: Color(0xFF5A3510), ink: Color(0xFFF5E0C3)),
    Family.kick: (fill: Color(0xFF1B3A5C), ink: Color(0xFFD3E2F4)),
    Family.knee: (fill: Color(0xFF3E2559), ink: Color(0xFFE3D6F0)),
    Family.defense: (fill: Color(0xFF1C4428), ink: Color(0xFFD4EBD9)),
    Family.footwork: (fill: Color(0xFF2A3B3C), ink: Color(0xFFD9E3E3)),
  });

  final Map<Family, FamilyColors> families;

  FamilyColors family(Family family) => families[family]!;

  static CadenceColors of(BuildContext context) =>
      Theme.of(context).extension<CadenceColors>()!;

  @override
  CadenceColors copyWith({Map<Family, FamilyColors>? families}) =>
      CadenceColors(families ?? this.families);

  /// Blends two themes, for the animated switch between light and dark.
  @override
  CadenceColors lerp(CadenceColors? other, double t) {
    if (other == null) return this;
    return CadenceColors({
      for (final family in Family.values)
        family: (
          fill: Color.lerp(
            this.family(family).fill,
            other.family(family).fill,
            t,
          )!,
          ink: Color.lerp(
            this.family(family).ink,
            other.family(family).ink,
            t,
          )!,
        ),
    });
  }
}

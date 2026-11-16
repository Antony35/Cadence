import 'package:flutter/material.dart';

/// The only place where colors are declared. Screens read them through
/// `Theme.of(context).colorScheme`, so switching theme never touches a screen.
///
/// Palette: black and gold, after the gloves of the illustrations.
abstract final class AppTheme {
  static final ThemeData light = _build(lightScheme);
  static final ThemeData dark = _build(darkScheme);

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

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
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

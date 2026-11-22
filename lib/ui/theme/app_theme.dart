import 'package:cadence/models/technique.dart';
import 'package:flutter/material.dart';

/// The only place where colors, fonts and shapes are declared. Screens read
/// them through `Theme.of(context)`, so switching theme never touches a
/// screen.
///
/// Identity « fight poster »: black and gold like the gloves of the
/// illustrations, condensed capitals like a gala poster or a round board,
/// nearly square corners, lists without cards.
abstract final class AppTheme {
  static final ThemeData light = _build(lightScheme, CadenceColors.light);
  static final ThemeData dark = _build(darkScheme, CadenceColors.dark);

  /// Text font: Barlow, a grotesque drawn after road signs, easy to read.
  static const textFont = 'Barlow';

  /// Display font: its condensed cut, for titles, figures and labels.
  static const displayFont = 'BarlowCondensed';

  /// One corner radius for buttons, fields, tiles and badges.
  static const radius = 4.0;

  /// A cold off-white: no cream, which reads as a default of AI tools.
  /// Bright gold cannot carry small text on a light background (contrast
  /// 2.5:1), so [ColorScheme.primary] is a dark gold and the bright one only
  /// fills [ColorScheme.primaryContainer].
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF7A5A0E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF3DFA2),
    onPrimaryContainer: Color(0xFF2A2000),
    secondary: Color(0xFF1A1A1A),
    onSecondary: Color(0xFFF4F4F2),
    secondaryContainer: Color(0xFFE3E3E0),
    onSecondaryContainer: Color(0xFF1A1A1A),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFF4F4F2),
    onSurface: Color(0xFF1A1A1A),
    onSurfaceVariant: Color(0xFF56585B),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF9F9F8),
    surfaceContainer: Color(0xFFEBEBE8),
    surfaceContainerHigh: Color(0xFFE3E3E0),
    surfaceContainerHighest: Color(0xFFDADAD6),
    outline: Color(0xFF7C7E80),
    outlineVariant: Color(0xFFD6D6D2),
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

  /// Our own scale rather than Material's default one. Display, title and
  /// label styles use the condensed cut; body styles the regular one.
  static const TextTheme _text = TextTheme(
    displaySmall: TextStyle(
      fontFamily: displayFont,
      fontWeight: FontWeight.w700,
      fontSize: 64,
      height: 1,
    ),
    headlineSmall: TextStyle(
      fontFamily: displayFont,
      fontWeight: FontWeight.w700,
      fontSize: 32,
      height: 1.1,
      letterSpacing: 0.5,
    ),
    titleLarge: TextStyle(
      fontFamily: displayFont,
      fontWeight: FontWeight.w700,
      fontSize: 24,
      height: 1.15,
      letterSpacing: 0.5,
    ),
    titleMedium: TextStyle(
      fontFamily: displayFont,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      height: 1.25,
      letterSpacing: 1.2,
    ),
    titleSmall: TextStyle(
      fontFamily: textFont,
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.3,
    ),
    bodyLarge: TextStyle(fontFamily: textFont, fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(fontFamily: textFont, fontSize: 14, height: 1.45),
    bodySmall: TextStyle(fontFamily: textFont, fontSize: 12, height: 1.4),
    labelLarge: TextStyle(
      fontFamily: displayFont,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.25,
      letterSpacing: 0.6,
    ),
    labelMedium: TextStyle(
      fontFamily: displayFont,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.25,
      letterSpacing: 1,
    ),
    labelSmall: TextStyle(
      fontFamily: displayFont,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1.25,
      letterSpacing: 1,
    ),
  );

  static ThemeData _build(ColorScheme scheme, CadenceColors cadence) {
    final corners = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final buttonText = _text.labelLarge;

    return ThemeData(
      colorScheme: scheme,
      fontFamily: textFont,
      textTheme: _text,
      extensions: [cadence],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        // No tint when content scrolls under the bar: the page stays flat.
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: _text.titleLarge?.copyWith(
          color: scheme.onSurface,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: corners,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: corners, textStyle: buttonText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: corners, textStyle: buttonText),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: corners, textStyle: buttonText),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: corners,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      chipTheme: ChipThemeData(shape: corners, labelStyle: _text.labelMedium),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      dialogTheme: DialogThemeData(shape: corners),
      drawerTheme: const DrawerThemeData(shape: RoundedRectangleBorder()),
    );
  }
}

/// The badge colors of a family: [fill] for the square, [ink] for its icon.
typedef FamilyColors = ({Color fill, Color ink});

/// The « À réviser » round board: [ink] for text, [accent] for the figure
/// and the button, [muted] for the secondary line. The button label is
/// written in [fill].
typedef ScoreboardColors = ({Color fill, Color ink, Color accent, Color muted});

/// The colors Material has no slot for: one per family (V3), and the round
/// board of the main screen.
///
/// A [ThemeExtension] is added to [ThemeData], so each theme has its own
/// values and screens read them like the others:
/// `CadenceColors.of(context).family(Family.kick)`.
@immutable
class CadenceColors extends ThemeExtension<CadenceColors> {
  const CadenceColors(this.families, this.scoreboard);

  /// Pale squares with a dark icon of the same hue; a grey board with a
  /// dark gold figure, like the rest of the light theme.
  static const light = CadenceColors(
    {
      Family.punch: (fill: Color(0xFFF6D5CF), ink: Color(0xFF7D2418)),
      Family.elbow: (fill: Color(0xFFF5E0C3), ink: Color(0xFF6E3F0C)),
      Family.kick: (fill: Color(0xFFD3E2F4), ink: Color(0xFF1F4B7A)),
      Family.knee: (fill: Color(0xFFE3D6F0), ink: Color(0xFF54307A)),
      Family.defense: (fill: Color(0xFFD4EBD9), ink: Color(0xFF1F5C33)),
      Family.footwork: (fill: Color(0xFFD9E3E3), ink: Color(0xFF2E4F50)),
    },
    (
      fill: Color(0xFFE3E3E0),
      ink: Color(0xFF1A1A1A),
      accent: Color(0xFF7A5A0E),
      muted: Color(0xFF505255),
    ),
  );

  /// Deep squares with a pale icon: the same hues, reversed. The board is
  /// lifted a little above the black background.
  static const dark = CadenceColors(
    {
      Family.punch: (fill: Color(0xFF5C1F16), ink: Color(0xFFF6D5CF)),
      Family.elbow: (fill: Color(0xFF5A3510), ink: Color(0xFFF5E0C3)),
      Family.kick: (fill: Color(0xFF1B3A5C), ink: Color(0xFFD3E2F4)),
      Family.knee: (fill: Color(0xFF3E2559), ink: Color(0xFFE3D6F0)),
      Family.defense: (fill: Color(0xFF1C4428), ink: Color(0xFFD4EBD9)),
      Family.footwork: (fill: Color(0xFF2A3B3C), ink: Color(0xFFD9E3E3)),
    },
    (
      fill: Color(0xFF262320),
      ink: Color(0xFFF2EDE4),
      accent: Color(0xFFE0B44C),
      muted: Color(0xFFC9C1B2),
    ),
  );

  final Map<Family, FamilyColors> families;
  final ScoreboardColors scoreboard;

  FamilyColors family(Family family) => families[family]!;

  static CadenceColors of(BuildContext context) =>
      Theme.of(context).extension<CadenceColors>()!;

  @override
  CadenceColors copyWith({
    Map<Family, FamilyColors>? families,
    ScoreboardColors? scoreboard,
  }) => CadenceColors(families ?? this.families, scoreboard ?? this.scoreboard);

  /// Blends two themes, for the animated switch between light and dark.
  @override
  CadenceColors lerp(CadenceColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    final (a, b) = (scoreboard, other.scoreboard);
    return CadenceColors(
      {
        for (final family in Family.values)
          family: (
            fill: mix(this.family(family).fill, other.family(family).fill),
            ink: mix(this.family(family).ink, other.family(family).ink),
          ),
      },
      (
        fill: mix(a.fill, b.fill),
        ink: mix(a.ink, b.ink),
        accent: mix(a.accent, b.accent),
        muted: mix(a.muted, b.muted),
      ),
    );
  }
}

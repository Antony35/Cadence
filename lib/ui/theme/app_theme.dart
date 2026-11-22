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

  /// The side margin of every page: room to breathe.
  static const gutter = 24.0;

  /// A cold off-white: no cream, which reads as a default of AI tools, and a
  /// charcoal ink rather than a hard black.
  ///
  /// Two golds. [ColorScheme.primaryContainer] is the bright, matte gold of
  /// the actions (buttons, + button), always with dark text on it. Bright
  /// gold cannot carry small text on a light background (contrast 2.2:1),
  /// so [ColorScheme.primary], for gold text, is a deeper gold.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF85620F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0B54D),
    onPrimaryContainer: Color(0xFF1F2324),
    secondary: Color(0xFF2A2F30),
    onSecondary: Color(0xFFF4F4F2),
    secondaryContainer: Color(0xFFE3E3E0),
    onSecondaryContainer: Color(0xFF2A2F30),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFF4F4F2),
    onSurface: Color(0xFF2A2F30),
    onSurfaceVariant: Color(0xFF606266),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF9F9F8),
    surfaceContainer: Color(0xFFEBEBE8),
    surfaceContainerHigh: Color(0xFFE3E3E0),
    surfaceContainerHighest: Color(0xFFDADAD6),
    outline: Color(0xFF7C7E80),
    outlineVariant: Color(0xFFD6D6D2),
  );

  /// The charcoal of the logo poster (#1F2324), slightly blue-grey, and
  /// its off-white; no more brown-black.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE0B54D),
    onPrimary: Color(0xFF1F2324),
    // The same action gold as in the light theme.
    primaryContainer: Color(0xFFE0B54D),
    onPrimaryContainer: Color(0xFF1F2324),
    secondary: Color(0xFFECEAE3),
    onSecondary: Color(0xFF1F2324),
    secondaryContainer: Color(0xFF30373A),
    onSecondaryContainer: Color(0xFFECEAE3),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF1A1E1F),
    onSurface: Color(0xFFECEAE3),
    onSurfaceVariant: Color(0xFFB9BDB9),
    surfaceContainerLowest: Color(0xFF1F2324),
    surfaceContainerLow: Color(0xFF1D2122),
    surfaceContainer: Color(0xFF252A2C),
    surfaceContainerHigh: Color(0xFF2D3335),
    surfaceContainerHighest: Color(0xFF353C3E),
    outline: Color(0xFF8D9390),
    outlineVariant: Color(0xFF3B4244),
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
      // The main action of a screen: the action gold, tall and bold.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: corners,
          textStyle: buttonText?.copyWith(fontWeight: FontWeight.w700),
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: corners,
          textStyle: buttonText,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: corners, textStyle: buttonText),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: corners,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 2,
      ),
      chipTheme: ChipThemeData(shape: corners, labelStyle: _text.labelMedium),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: corners,
          textStyle: _text.labelMedium,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: corners,
        behavior: SnackBarBehavior.floating,
      ),
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

/// The « À réviser » round board: [ink] for text, [accent] for the figure,
/// [muted] for the secondary line. Its button is a normal action button.
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

  /// Muted, earthy hues, dark enough to stand out on the off-white (3:1
  /// at least, the threshold for borders and icons); a grey board with a
  /// dark gold figure, like the rest of the light theme.
  static const light = CadenceColors(
    {
      Family.punch: Color(0xFFA8473A),
      Family.elbow: Color(0xFF9A6420),
      Family.kick: Color(0xFF3F6A9A),
      Family.knee: Color(0xFF765A9C),
      Family.defense: Color(0xFF4A7A55),
      Family.footwork: Color(0xFF3F7576),
    },
    (
      fill: Color(0xFFEBEBE8),
      ink: Color(0xFF2A2F30),
      accent: Color(0xFF85620F),
      muted: Color(0xFF55575B),
    ),
  );

  /// The same hues, lighter, on the charcoal. The board is lifted a little
  /// above the background.
  static const dark = CadenceColors(
    {
      Family.punch: Color(0xFFD98A7E),
      Family.elbow: Color(0xFFD1A26A),
      Family.kick: Color(0xFF8DB0D6),
      Family.knee: Color(0xFFB5A0D2),
      Family.defense: Color(0xFF8DBE98),
      Family.footwork: Color(0xFF85BDBD),
    },
    (
      fill: Color(0xFF262B2D),
      ink: Color(0xFFECEAE3),
      accent: Color(0xFFE0B54D),
      muted: Color(0xFFB9BDB9),
    ),
  );

  /// One color per family: the fine line around its images, its icon, the
  /// square of its filter tab.
  final Map<Family, Color> families;
  final ScoreboardColors scoreboard;

  Color family(Family family) => families[family]!;

  static CadenceColors of(BuildContext context) =>
      Theme.of(context).extension<CadenceColors>()!;

  @override
  CadenceColors copyWith({
    Map<Family, Color>? families,
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
          family: mix(this.family(family), other.family(family)),
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

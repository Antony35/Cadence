import 'package:cadence/models/technique.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2 contrast ratio between two opaque colors, from 1 (same) to 21.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const schemes = {'light': AppTheme.lightScheme, 'dark': AppTheme.darkScheme};

  for (final MapEntry(key: name, value: scheme) in schemes.entries) {
    group('$name theme', () {
      // Every (text, background) pair the screens are allowed to combine.
      final textPairs = {
        'onSurface on surface': (scheme.onSurface, scheme.surface),
        'onSurface on card': (scheme.onSurface, scheme.surfaceContainerLowest),
        'onSurfaceVariant on surface': (
          scheme.onSurfaceVariant,
          scheme.surface,
        ),
        'onSurfaceVariant on card': (
          scheme.onSurfaceVariant,
          scheme.surfaceContainerLowest,
        ),
        'primary on surface': (scheme.primary, scheme.surface),
        'primary on card': (scheme.primary, scheme.surfaceContainerLowest),
        'onPrimary on primary': (scheme.onPrimary, scheme.primary),
        'onPrimaryContainer on primaryContainer': (
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
        ),
        'onSecondary on secondary': (scheme.onSecondary, scheme.secondary),
        'onSecondaryContainer on secondaryContainer': (
          scheme.onSecondaryContainer,
          scheme.secondaryContainer,
        ),
        'error on surface': (scheme.error, scheme.surface),
        'error on card': (scheme.error, scheme.surfaceContainerLowest),
        'onError on error': (scheme.onError, scheme.error),
        'onErrorContainer on errorContainer': (
          scheme.onErrorContainer,
          scheme.errorContainer,
        ),
      };

      for (final MapEntry(key: pair, value: (fg, bg)) in textPairs.entries) {
        test('V2 — $pair reaches 4.5:1', () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }

      test('outlines reach 3:1, the threshold for non-text elements', () {
        expect(
          contrast(scheme.outline, scheme.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          contrast(scheme.outline, scheme.surfaceContainerLowest),
          greaterThanOrEqualTo(3),
        );
      });
    });
  }

  const families = {'light': CadenceColors.light, 'dark': CadenceColors.dark};
  for (final MapEntry(key: name, value: colors) in families.entries) {
    for (final family in Family.values) {
      test('V3 — $name ${family.name} badge: icon on disc reaches 4.5:1', () {
        final (:fill, :ink) = colors.family(family);
        expect(contrast(ink, fill), greaterThanOrEqualTo(4.5));
      });
    }
  }

  for (final MapEntry(key: name, value: colors) in families.entries) {
    test('$name round board: text and gold figure reach 4.5:1', () {
      final (:fill, :ink, :accent, :muted) = colors.scoreboard;
      expect(contrast(ink, fill), greaterThanOrEqualTo(4.5));
      expect(contrast(accent, fill), greaterThanOrEqualTo(4.5));
      expect(contrast(muted, fill), greaterThanOrEqualTo(4.5));
      // The gold button carries its label in the board color.
      expect(contrast(fill, accent), greaterThanOrEqualTo(4.5));
    });
  }

  test('V1 — the light theme uses no pure black', () {
    const scheme = AppTheme.lightScheme;
    final colors = [
      scheme.onSurface,
      scheme.onSurfaceVariant,
      scheme.primary,
      scheme.secondary,
      scheme.onPrimaryContainer,
      scheme.onSecondaryContainer,
      scheme.onErrorContainer,
      scheme.outline,
    ];
    expect(colors, isNot(contains(const Color(0xFF000000))));
  });
}

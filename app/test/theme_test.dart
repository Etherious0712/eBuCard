// The design system's promises (docs/design-system/ebucard/MASTER.md):
// readable text in both modes, visible control borders, the bundled fonts,
// and touch targets of at least 48 pixels.

import 'dart:math' as math;

import 'package:ebucard/src/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio between [a] and [b].
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, scheme) in [('light', lightScheme), ('dark', darkScheme)]) {
    group(name, () {
      test('text meets WCAG AA (4.5:1)', () {
        for (final (fg, bg) in [
          (scheme.onSurface, scheme.surface),
          (scheme.onSurfaceVariant, scheme.surface),
          (scheme.onSurfaceVariant, scheme.surfaceContainerLow),
          (scheme.primary, scheme.surface),
          (scheme.primary, scheme.surfaceContainerLow),
          (scheme.onPrimary, scheme.primary),
          (scheme.onTertiary, scheme.tertiary),
          (scheme.onPrimaryContainer, scheme.primaryContainer),
          (scheme.error, scheme.surface),
          (scheme.onError, scheme.error),
        ]) {
          expect(
            contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$fg on $bg',
          );
        }
      });

      test('control borders are visible (3:1)', () {
        expect(
          contrast(scheme.outline, scheme.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          contrast(scheme.outline, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(3),
        );
      });
    });
  }

  test('headings use Poppins, text uses Open Sans; buttons are 48 high', () {
    final theme = lightTheme();
    expect(theme.textTheme.titleLarge!.fontFamily, headingFont);
    expect(theme.textTheme.headlineSmall!.fontWeight, FontWeight.w700);
    expect(theme.textTheme.bodyLarge!.fontFamily, textFont);
    expect(theme.textTheme.bodyLarge!.fontFamilyFallback, cjkFallback);
    expect(theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height, 48);
    expect(darkTheme().colorScheme.brightness, Brightness.dark);
  });
}

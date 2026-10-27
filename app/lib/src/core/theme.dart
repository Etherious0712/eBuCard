// The app's look: the eBuCard design system
// (docs/design-system/ebucard/MASTER.md). Flat, professional blue, Poppins
// headings and Open Sans text, light and dark. Screens read colours and
// text styles from Theme.of(context), never hard-coded values.
//
// Contrast: text colours meet WCAG AA (4.5:1) on their backgrounds in both
// modes; borders of controls meet 3:1.

import 'package:flutter/material.dart';

/// Heading font (Poppins 600/700, bundled in assets/fonts).
const headingFont = 'Poppins';

/// Text font (Open Sans 400/600, bundled in assets/fonts).
const textFont = 'OpenSans';

/// System fonts for Chinese, which the bundled Latin fonts don't cover.
const cjkFallback = [
  'PingFang TC',
  'PingFang SC',
  'Noto Sans CJK TC',
  'Noto Sans CJK SC',
  'Noto Sans TC',
  'Noto Sans SC',
];

/// Light colours (design-system tokens).
const lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF2563EB),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFDBEAFE),
  onPrimaryContainer: Color(0xFF1E3A8A),
  secondary: Color(0xFF3B82F6),
  onSecondary: Color(0xFF000000),
  secondaryContainer: Color(0xFFEFF6FF),
  onSecondaryContainer: Color(0xFF1E3A8A),
  // The accent: "Save contact" and other positive main actions.
  tertiary: Color(0xFF047857),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFD1FAE5),
  onTertiaryContainer: Color(0xFF064E3B),
  error: Color(0xFFDC2626),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFEE2E2),
  onErrorContainer: Color(0xFF7F1D1D),
  surface: Color(0xFFF8FAFC),
  onSurface: Color(0xFF0F172A),
  onSurfaceVariant: Color(0xFF475569),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFF1F5F9),
  surfaceContainerHigh: Color(0xFFE9EEF5),
  surfaceContainerHighest: Color(0xFFE2E8F0),
  outline: Color(0xFF8391A7),
  outlineVariant: Color(0xFFE2E8F0),
  inverseSurface: Color(0xFF1E293B),
  onInverseSurface: Color(0xFFF1F5F9),
  inversePrimary: Color(0xFF93C5FD),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

/// Dark colours (design-system tokens).
const darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF60A5FA),
  onPrimary: Color(0xFF0F172A),
  primaryContainer: Color(0xFF1E3A8A),
  onPrimaryContainer: Color(0xFFDBEAFE),
  secondary: Color(0xFF93C5FD),
  onSecondary: Color(0xFF0F172A),
  secondaryContainer: Color(0xFF1C2A44),
  onSecondaryContainer: Color(0xFFDBEAFE),
  tertiary: Color(0xFF34D399),
  onTertiary: Color(0xFF052E16),
  tertiaryContainer: Color(0xFF064E3B),
  onTertiaryContainer: Color(0xFFD1FAE5),
  error: Color(0xFFF87171),
  onError: Color(0xFF450A0A),
  errorContainer: Color(0xFF7F1D1D),
  onErrorContainer: Color(0xFFFEE2E2),
  surface: Color(0xFF0B1120),
  onSurface: Color(0xFFF1F5F9),
  onSurfaceVariant: Color(0xFFA3B1C6),
  surfaceContainerLowest: Color(0xFF0B1120),
  surfaceContainerLow: Color(0xFF162033),
  surfaceContainer: Color(0xFF162033),
  surfaceContainerHigh: Color(0xFF1C2A44),
  surfaceContainerHighest: Color(0xFF26334A),
  outline: Color(0xFF6B7A93),
  outlineVariant: Color(0xFF26334A),
  inverseSurface: Color(0xFFF1F5F9),
  onInverseSurface: Color(0xFF0F172A),
  inversePrimary: Color(0xFF2563EB),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

/// The light theme.
ThemeData lightTheme() => _theme(lightScheme);

/// The dark theme.
ThemeData darkTheme() => _theme(darkScheme);

/// Builds a theme from [scheme]: fonts, shapes and component styles.
ThemeData _theme(ColorScheme scheme) {
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: textFont,
    fontFamilyFallback: cjkFallback,
  );
  final text = _textTheme(base.textTheme, scheme);
  const minButton = Size(64, 48);
  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  final buttonText = text.labelLarge;
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: scheme.outline),
  );

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      // Flat: no tint or shadow when content scrolls under the bar.
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minButton,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minButton,
        shape: buttonShape,
        textStyle: buttonText,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minButton,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      extendedTextStyle: buttonText,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: scheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    listTileTheme: ListTileThemeData(
      minTileHeight: 56,
      iconColor: scheme.primary,
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: text.titleLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: minButton,
        textStyle: buttonText,
        side: BorderSide(color: scheme.outline),
      ),
    ),
  );
}

/// Poppins for display, headline and title styles; Open Sans for the rest.
/// Weights match the bundled files (Poppins 600/700, Open Sans 400/600).
TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
  TextStyle? heading(TextStyle? s, FontWeight w) => s?.copyWith(
    fontFamily: headingFont,
    fontFamilyFallback: cjkFallback,
    fontWeight: w,
    color: scheme.onSurface,
  );
  TextStyle? body(TextStyle? s, FontWeight w) =>
      s?.copyWith(fontWeight: w, color: scheme.onSurface);
  return base.copyWith(
    displayLarge: heading(base.displayLarge, FontWeight.w700),
    displayMedium: heading(base.displayMedium, FontWeight.w700),
    displaySmall: heading(base.displaySmall, FontWeight.w700),
    headlineLarge: heading(base.headlineLarge, FontWeight.w700),
    headlineMedium: heading(base.headlineMedium, FontWeight.w700),
    headlineSmall: heading(base.headlineSmall, FontWeight.w700),
    titleLarge: heading(base.titleLarge, FontWeight.w600),
    titleMedium: heading(base.titleMedium, FontWeight.w600),
    titleSmall: heading(base.titleSmall, FontWeight.w600),
    bodyLarge: body(base.bodyLarge, FontWeight.w400),
    bodyMedium: body(base.bodyMedium, FontWeight.w400),
    bodySmall: body(
      base.bodySmall,
      FontWeight.w400,
    )?.copyWith(color: scheme.onSurfaceVariant),
    labelLarge: body(base.labelLarge, FontWeight.w600),
    labelMedium: body(base.labelMedium, FontWeight.w600),
    labelSmall: body(base.labelSmall, FontWeight.w600),
  );
}

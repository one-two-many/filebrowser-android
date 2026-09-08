import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nocturne_colors.dart';

class AppTheme {
  static ThemeData _build(NocturneColors colors, Brightness brightness) {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: colors.text,
      displayColor: colors.text,
    );
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      cardColor: colors.surface,
      dividerColor: colors.divider,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.text,
        secondary: colors.accent,
        onSecondary: colors.text,
        surface: colors.surface,
        onSurface: colors.text,
        error: const Color(0xFFCF6679),
        onError: colors.text,
      ),
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 24,
          letterSpacing: -0.02,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.55),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.bg,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.divider),
        ),
      ),
      extensions: [colors],
    );
  }

  static final dark = _build(NocturneColors.dark, Brightness.dark);
  static final light = _build(NocturneColors.light, Brightness.light);
}

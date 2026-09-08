import 'package:flutter/material.dart';

/// Color tokens from the Nocturne design system (see design_handoff_drive_app/).
class NocturneColors extends ThemeExtension<NocturneColors> {
  final Color bg;
  final Color surface;
  final Color text;
  final Color accent;
  final Color accent100;
  final Color accent800;
  final Color divider;

  const NocturneColors({
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.accent100,
    required this.accent800,
    required this.divider,
  });

  /// CSS `color-mix(in srgb, var(--color-text) X%, transparent)` is just
  /// the text color at X% opacity.
  Color mutedText([double opacity = 0.55]) => text.withValues(alpha: opacity);

  static const dark = NocturneColors(
    bg: Color(0xFF161826),
    surface: Color(0xFF232532),
    text: Color(0xFFE9E9ED),
    accent: Color(0xFF9184D9),
    accent100: Color(0xFFF5F4FF),
    accent800: Color(0xFF423A6A),
    divider: Color(0x29E9E9ED), // text @ 16%
  );

  static const light = NocturneColors(
    bg: Color(0xFFEAECF6),
    surface: Color(0xFFF8F9FE),
    text: Color(0xFF232532),
    // accent is not overridden between themes in the source design.
    accent: Color(0xFF9184D9),
    accent100: Color(0xFFF5F4FF),
    accent800: Color(0xFF423A6A),
    divider: Color(0x24232532), // text @ 14%
  );

  @override
  NocturneColors copyWith({
    Color? bg,
    Color? surface,
    Color? text,
    Color? accent,
    Color? accent100,
    Color? accent800,
    Color? divider,
  }) {
    return NocturneColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      accent100: accent100 ?? this.accent100,
      accent800: accent800 ?? this.accent800,
      divider: divider ?? this.divider,
    );
  }

  @override
  NocturneColors lerp(ThemeExtension<NocturneColors>? other, double t) {
    if (other is! NocturneColors) return this;
    return NocturneColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accent100: Color.lerp(accent100, other.accent100, t)!,
      accent800: Color.lerp(accent800, other.accent800, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension NocturneColorsContext on BuildContext {
  NocturneColors get nocturne =>
      Theme.of(this).extension<NocturneColors>() ?? NocturneColors.dark;
}

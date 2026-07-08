import 'package:flutter/material.dart';

abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class Radii {
  static const double sm = 4;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  /// Fully-rounded pill shape for chips and nav elements.
  static const double pill = 999;
}

/// Approved redesign palette. These constants exist ONLY for building the
/// [ColorScheme]s and [AppTokens] in core/theme.dart — widgets must read
/// colors via Theme.of(context) / AppTokens.of(context), never from here.
abstract final class Palette {
  // Light
  static const paper = Color(0xFFF5F2EA);
  static const ink = Color(0xFF22201C);
  static const inkSoft = Color(0xFF6B665C);
  static const accent = Color(0xFF2C6155);
  static const accentSoft = Color(0xFFDCE7E2);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE4DFD2);

  // Dark
  static const paperDark = Color(0xFF17181B);
  static const inkOnDark = Color(0xFFE9E6DD);
  static const inkSoftOnDark = Color(0xFF8B887F);
  static const accentBright = Color(0xFF8FCABB);
  static const accentSoftDark = Color(0xFF1E3B34);
  static const cardDark = Color(0xFF212226);
  static const lineDark = Color(0xFF2E2F33);

  // Both modes
  static const stamp = Color(0xFFB4472E);
}

/// Design tokens that don't map cleanly onto Material's [ColorScheme] roles.
/// Attached to [ThemeData.extensions]; resolve with `AppTokens.of(context)`.
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.paper,
    required this.card,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.accentFill,
    required this.onAccent,
    required this.accentEmphasis,
    required this.accentSoft,
    required this.stamp,
  });

  /// Screen background.
  final Color paper;

  /// Raised surface (cards, sheets). In dark mode elevation comes from this
  /// being lighter than [paper] plus a 1px [line] border — never shadows.
  final Color card;

  /// 1px borders and dividers.
  final Color line;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color inkSoft;

  /// Solid button/nav fills. Stays #2C6155 in both modes.
  final Color accentFill;

  /// Text/icons placed ON an [accentFill] surface. White in light mode,
  /// warm ink in dark. Don't use ColorScheme.onPrimary for this — dark
  /// onPrimary pairs with the brightened teal, not the deep fill.
  final Color onAccent;

  /// Accent for text and icons — brightened in dark mode for contrast.
  final Color accentEmphasis;

  /// Chip/badge background tint.
  final Color accentSoft;

  /// Destructive/reject. Same in both modes.
  final Color stamp;

  static const light = AppTokens(
    paper: Palette.paper,
    card: Palette.card,
    line: Palette.line,
    ink: Palette.ink,
    inkSoft: Palette.inkSoft,
    accentFill: Palette.accent,
    onAccent: Color(0xFFFFFFFF),
    accentEmphasis: Palette.accent,
    accentSoft: Palette.accentSoft,
    stamp: Palette.stamp,
  );

  static const dark = AppTokens(
    paper: Palette.paperDark,
    card: Palette.cardDark,
    line: Palette.lineDark,
    ink: Palette.inkOnDark,
    inkSoft: Palette.inkSoftOnDark,
    accentFill: Palette.accent,
    onAccent: Palette.inkOnDark,
    accentEmphasis: Palette.accentBright,
    accentSoft: Palette.accentSoftDark,
    stamp: Palette.stamp,
  );

  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? light;

  @override
  AppTokens copyWith({
    Color? paper,
    Color? card,
    Color? line,
    Color? ink,
    Color? inkSoft,
    Color? accentFill,
    Color? onAccent,
    Color? accentEmphasis,
    Color? accentSoft,
    Color? stamp,
  }) {
    return AppTokens(
      paper: paper ?? this.paper,
      card: card ?? this.card,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      accentFill: accentFill ?? this.accentFill,
      onAccent: onAccent ?? this.onAccent,
      accentEmphasis: accentEmphasis ?? this.accentEmphasis,
      accentSoft: accentSoft ?? this.accentSoft,
      stamp: stamp ?? this.stamp,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      paper: Color.lerp(paper, other.paper, t) ?? paper,
      card: Color.lerp(card, other.card, t) ?? card,
      line: Color.lerp(line, other.line, t) ?? line,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t) ?? inkSoft,
      accentFill: Color.lerp(accentFill, other.accentFill, t) ?? accentFill,
      onAccent: Color.lerp(onAccent, other.onAccent, t) ?? onAccent,
      accentEmphasis:
          Color.lerp(accentEmphasis, other.accentEmphasis, t) ?? accentEmphasis,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      stamp: Color.lerp(stamp, other.stamp, t) ?? stamp,
    );
  }
}

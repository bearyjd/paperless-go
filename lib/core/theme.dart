import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// App-wide theme built from the approved redesign palette (design_tokens.dart).
///
/// Both fonts are bundled as variable-font assets — the app must never fetch
/// fonts from Google's CDN at runtime (hard F-Droid requirement):
///  - SpaceGrotesk: display / headlines / titles
///  - Inter: body and UI text
///
/// Dark-mode elevation comes from a lighter card fill over the background plus
/// a 1px border — component themes here use elevation 0, not shadows.
class AppTheme {
  static ThemeData light() {
    const t = AppTokens.light;
    final scheme = ColorScheme.light(
      primary: t.accentEmphasis,
      onPrimary: Colors.white,
      primaryContainer: t.accentSoft,
      onPrimaryContainer: t.accentFill,
      secondary: t.inkSoft,
      onSecondary: Colors.white,
      secondaryContainer: t.accentSoft,
      onSecondaryContainer: t.ink,
      tertiary: t.accentFill,
      tertiaryContainer: t.accentSoft,
      onTertiaryContainer: t.ink,
      error: t.stamp,
      onError: Colors.white,
      errorContainer: Color.alphaBlend(
        t.stamp.withValues(alpha: 0.12),
        t.paper,
      ),
      onErrorContainer: t.stamp,
      surface: t.paper,
      onSurface: t.ink,
      onSurfaceVariant: t.inkSoft,
      surfaceContainerLowest: t.card,
      surfaceContainerLow: t.card,
      surfaceContainer: t.card,
      surfaceContainerHigh: t.card,
      surfaceContainerHighest: Color.alphaBlend(
        t.ink.withValues(alpha: 0.06),
        t.paper,
      ),
      outline: t.inkSoft,
      outlineVariant: t.line,
      inverseSurface: t.ink,
      onInverseSurface: t.paper,
      inversePrimary: Palette.accentBright,
    );
    return _buildTheme(scheme, t);
  }

  static ThemeData dark() {
    const t = AppTokens.dark;
    final scheme = ColorScheme.dark(
      // Brightened teal so accent text/icons hold contrast on dark surfaces;
      // solid fills keep the deep accent via AppTokens.accentFill overrides.
      primary: t.accentEmphasis,
      onPrimary: t.paper,
      primaryContainer: t.accentSoft,
      onPrimaryContainer: t.accentEmphasis,
      secondary: t.inkSoft,
      onSecondary: t.paper,
      secondaryContainer: t.accentSoft,
      onSecondaryContainer: t.ink,
      tertiary: t.accentEmphasis,
      tertiaryContainer: t.accentSoft,
      onTertiaryContainer: t.ink,
      error: t.stamp,
      onError: Colors.white,
      errorContainer: Color.alphaBlend(
        t.stamp.withValues(alpha: 0.24),
        t.card,
      ),
      onErrorContainer: Color.alphaBlend(
        Colors.white.withValues(alpha: 0.6),
        t.stamp,
      ),
      surface: t.paper,
      onSurface: t.ink,
      onSurfaceVariant: t.inkSoft,
      surfaceContainerLowest: t.paper,
      surfaceContainerLow: t.card,
      surfaceContainer: t.card,
      surfaceContainerHigh: t.card,
      surfaceContainerHighest: Color.alphaBlend(
        Colors.white.withValues(alpha: 0.05),
        t.card,
      ),
      outline: t.inkSoft,
      outlineVariant: t.line,
      inverseSurface: t.ink,
      onInverseSurface: t.paper,
      inversePrimary: t.accentFill,
    );
    return _buildTheme(scheme, t);
  }

  static ThemeData _buildTheme(ColorScheme scheme, AppTokens tokens) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    // Two families, two weights per screen: SpaceGrotesk w600 for
    // display/headline/title, Inter w400 for body/label.
    final inter = base.textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: tokens.ink,
      displayColor: tokens.ink,
    );
    TextStyle? grotesk(TextStyle? s) => s?.copyWith(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w600,
        );
    final textTheme = inter.copyWith(
      displayLarge: grotesk(inter.displayLarge),
      displayMedium: grotesk(inter.displayMedium),
      displaySmall: grotesk(inter.displaySmall),
      headlineLarge: grotesk(inter.headlineLarge),
      headlineMedium: grotesk(inter.headlineMedium),
      headlineSmall: grotesk(inter.headlineSmall),
      titleLarge: grotesk(inter.titleLarge),
      titleMedium: grotesk(inter.titleMedium),
      titleSmall: grotesk(inter.titleSmall),
      bodyMedium: inter.bodyMedium?.copyWith(color: tokens.ink),
      bodySmall: inter.bodySmall?.copyWith(color: tokens.inkSoft),
      labelMedium: inter.labelMedium?.copyWith(color: tokens.inkSoft),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.lg),
      side: BorderSide(color: tokens.line),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: tokens.paper,
      dividerColor: tokens.line,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: tokens.paper,
        foregroundColor: tokens.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: tokens.card,
        elevation: 0,
        shape: cardShape,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.card,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: tokens.line),
        backgroundColor: tokens.card,
        selectedColor: tokens.accentSoft,
        labelStyle: textTheme.labelLarge,
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide(color: tokens.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide(color: tokens.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide(color: tokens.accentEmphasis, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: tokens.accentFill,
          foregroundColor: tokens.onAccent,
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: tokens.accentEmphasis,
          side: BorderSide(color: tokens.line),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: tokens.accentEmphasis,
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.accentFill,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.card,
        elevation: 0,
        indicatorColor: tokens.accentSoft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? tokens.accentEmphasis
                : tokens.inkSoft,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? tokens.accentEmphasis
                : tokens.inkSoft,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.paper),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accentEmphasis,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.inkSoft,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: tokens.line),
        ),
      ),
    );
  }
}

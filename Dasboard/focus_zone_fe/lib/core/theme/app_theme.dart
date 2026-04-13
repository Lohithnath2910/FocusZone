import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData theme(double t) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1D9BF0),
      brightness: Brightness.light,
      primary: const Color(0xFF0EA5E9),
      secondary: const Color(0xFF8B5CF6),
      tertiary: const Color(0xFF14B8A6),
      surface: const Color(0xFFF5F9FF),
      background: const Color(0xFFEAF1FF),
      onSurface: const Color(0xFF132033),
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00F5FF),
      brightness: Brightness.dark,
      primary: const Color(0xFF00F5FF),
      secondary: const Color(0xFFA78BFA),
      tertiary: const Color(0xFF22D3EE),
      surface: const Color(0xFF111827),
      background: const Color(0xFF070B14),
      onSurface: const Color(0xFFF5F7FF),
    );

    final scheme = ColorScheme.lerp(lightScheme, darkScheme, t);
    final scaffoldBackground =
        Color.lerp(lightScheme.background, darkScheme.background, t) ??
        darkScheme.background;

    final baseTextTheme = ThemeData.light().textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface.withOpacity(0.42),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(color: scheme.onSurface.withOpacity(0.12)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface.withOpacity(0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: scheme.primary.withOpacity(0.85),
            width: 1.4,
          ),
        ),
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.55)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.onSurface.withOpacity(0.14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.onSurface.withOpacity(0.16),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withOpacity(0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.onSurface.withOpacity(0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface.withOpacity(0.8),
        labelStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: scheme.onSurface.withOpacity(0.08)),
      ),
    );
  }
}

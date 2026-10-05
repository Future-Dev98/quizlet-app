import 'package:flutter/material.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF6961E8),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFFBBB7FF) : const Color(0xFF6961E8),
        onPrimary: dark ? const Color(0xFF24204F) : Colors.white,
        surface: dark ? const Color(0xFF24263B) : Colors.white,
        onSurface: dark ? const Color(0xFFF1F2FA) : const Color(0xFF222642),
        onSurfaceVariant: dark
            ? const Color(0xFFBEC2D6)
            : const Color(0xFF646A80),
        primaryContainer: dark
            ? const Color(0xFF353052)
            : const Color(0xFFE8E6FD),
        onPrimaryContainer: dark
            ? const Color(0xFFF1EFFF)
            : const Color(0xFF222642),
      );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    fontFamilyFallback: const ['Noto Sans KR', 'sans-serif'],
    scaffoldBackgroundColor: dark
        ? const Color(0xFF171827)
        : const Color(0xFFF7F7FC),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colors.onSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(color: colors.surface),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      hintStyle: TextStyle(color: colors.onSurfaceVariant),
      labelStyle: TextStyle(color: colors.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineSmall: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ).apply(bodyColor: colors.onSurface, displayColor: colors.onSurface),
  );
}

import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SmokerColors.primaryBg,
      colorScheme: const ColorScheme.dark(
        primary: SmokerColors.accentBlue,
        secondary: SmokerColors.accentCyan,
        surface: SmokerColors.secondaryBg,
        error: SmokerColors.accentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: SmokerColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.tealAccent),
      ),
      cardTheme: CardThemeData(
        color: SmokerColors.cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SmokerColors.borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: SmokerColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: SmokerColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: SmokerColors.textSecondary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(color: SmokerColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: SmokerColors.textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SmokerColors.accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SmokerColors.secondaryBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SmokerColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SmokerColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: SmokerColors.accentCyan,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: SmokerColors.textSecondary),
        hintStyle: const TextStyle(color: SmokerColors.textMuted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SmokerColors.accentBlue;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SmokerColors.accentBlue.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
      iconTheme: const IconThemeData(color: Colors.tealAccent),
      extensions: [
        const SmokerThemeExtension(
          primaryGradient: SmokerColors.primaryGradient,
          accentGradient: SmokerColors.accentGradient,
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    // Light mode override based on CSS
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: SmokerColors.accentBlue,
        brightness: Brightness.light,
      ),
      // Add similar overrides if needed
    );
  }
}

class SmokerThemeExtension extends ThemeExtension<SmokerThemeExtension> {
  final LinearGradient primaryGradient;
  final LinearGradient accentGradient;

  const SmokerThemeExtension({
    required this.primaryGradient,
    required this.accentGradient,
  });

  @override
  SmokerThemeExtension copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? accentGradient,
  }) {
    return SmokerThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      accentGradient: accentGradient ?? this.accentGradient,
    );
  }

  @override
  SmokerThemeExtension lerp(
    ThemeExtension<SmokerThemeExtension>? other,
    double t,
  ) {
    if (other is! SmokerThemeExtension) return this;
    return SmokerThemeExtension(
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
      accentGradient: LinearGradient.lerp(
        accentGradient,
        other.accentGradient,
        t,
      )!,
    );
  }
}

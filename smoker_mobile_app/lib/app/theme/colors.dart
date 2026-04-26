import 'package:flutter/material.dart';

class SmokerColors {
  // Brand / Base Colors
  static const Color primaryBg = Color(0xFF0F172A);
  static const Color secondaryBg = Color(0xFF1E293B);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color borderColor = Color(0xFF334155);

  // Accents
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF0A5BAE);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentRed = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentBlue, primaryBg],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentBlue, accentCyan, accentGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

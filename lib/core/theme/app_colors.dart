import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42D6);
  static const Color primaryLight = Color(0xFF9B95FF);
  static const Color accent = Color(0xFF00D4AA);

  // Surface Colors - Dark Theme
  static const Color darkBg = Color(0xFF0F0E17);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkElevated = Color(0xFF1F2544);

  // Surface Colors - Light Theme
  static const Color lightBg = Color(0xFFF5F5FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0EEFF);

  // Status Colors
  static const Color success = Color(0xFF00D4AA);
  static const Color successLight = Color(0xFFE0FAF5);
  static const Color danger = Color(0xFFFF5A7E);
  static const Color dangerLight = Color(0xFFFFEAEF);
  static const Color warning = Color(0xFFFFC542);
  static const Color warningLight = Color(0xFFFFF8E7);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C6);
  static const Color textLight = Color(0xFF0F0E17);
  static const Color textLightSecondary = Color(0xFF6B6D80);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9B95FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00A882)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF5A7E), Color(0xFFFF3A62)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF0F0E17), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

import 'package:flutter/material.dart';

/// Ultra-sleek dark palette matching the Quanto UI specification.
class AppColors {
  AppColors._();

  // Backgrounds & Gradient (Matching Quanto IMG_6026.PNG)
  static const Color backgroundTop = Color(0xFF182B3A);
  static const Color backgroundMid = Color(0xFF0F1A24);
  static const Color backgroundBottom = Color(0xFF080C10);
  static const Color background = Color(0xFF080C10);
  static const Color backgroundSecondary = Color(0xFF121921);

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A2D3C), // Atmospheric midnight teal-slate glow at the top
      Color(0xFF101B25),
      Color(0xFF0A0F15),
      Color(0xFF070B0E),
    ],
    stops: [0.0, 0.25, 0.65, 1.0],
  );

  // Surfaces matching Quanto
  static const Color surface = Color(0xFF121921);
  static const Color surfaceElevated = Color(0xFF18222C);
  static const Color surfaceBorder = Color(0xFF212D3A);
  static const Color surfaceHover = Color(0xFF1B2632);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8EA0AE);
  static const Color textTertiary = Color(0xFF5C6F7D);
  static const Color textMuted = Color(0xFF43525E);

  // Financial Semantics
  static const Color expense = Color(0xFFF43F5E); // Soft vibrant coral red
  static const Color income = Color(0xFF10B981);  // Mint/emerald green
  static const Color transfer = Color(0xFF6366F1); // Soft violet
  static const Color warning = Color(0xFFF59E0B);  // Amber

  // Accents & Brand
  static const Color primary = Color(0xFF6366F1);  // Electric Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFF6366F1);
  static const Color accentHover = Color(0xFF818CF8);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentPink = Color(0xFFEC4899);

  // Charts
  static const Color chartBar = Color(0xFF6366F1);
  static const Color chartOrange = Color(0xFFF59E0B);

  // Category Palette (for donut chart segments & category icons)
  static const List<Color> categoryPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF38BDF8), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFF43F5E), // Coral
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF8B5CF6), // Violet
  ];
}

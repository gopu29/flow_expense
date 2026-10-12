import 'package:flutter/material.dart';

/// Ultra-sleek dark palette matching the Quanto UI specification.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF090A0E);
  static const Color surface = Color(0xFF14151B);
  static const Color surfaceElevated = Color(0xFF1C1D26);
  static const Color surfaceBorder = Color(0xFF262836);
  static const Color surfaceHover = Color(0xFF232532);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF475569);

  // Financial Semantics
  static const Color expense = Color(0xFFF43F5E); // Soft vibrant coral red
  static const Color income = Color(0xFF10B981);  // Mint/emerald green
  static const Color transfer = Color(0xFF6366F1); // Soft violet
  static const Color warning = Color(0xFFF59E0B);  // Amber

  // Accents
  static const Color primary = Color(0xFF6366F1);  // Electric Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentPink = Color(0xFFEC4899);

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

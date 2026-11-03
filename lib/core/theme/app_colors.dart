import 'package:flutter/material.dart';

/// Centralized Color Tokens and Palettes for OM MAVTAR GROUP
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color primaryBlueHover = Color(0xFF0052CC);
  static const Color primaryBlueLight = Color(0xFFEFF6FF);

  // Neutral Slate Palette (Light Theme)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Dark Mode Surfaces
  static const Color darkScaffoldBg = Color(0xFF0B1120);
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkSurfaceSubtle = Color(0xFF0F172A);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEF2F2);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleDark = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFFAF5FF);

  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanDark = Color(0xFF0891B2);
  static const Color cyanLight = Color(0xFFECFEFF);

  /// Computes optimal readable text color on any background color
  static Color getContrastText(Color background) {
    return background.computeLuminance() > 0.38
        ? slate900
        : Colors.white;
  }

  /// Computes secondary muted text color on any background color
  static Color getContrastSecondaryText(Color background) {
    return background.computeLuminance() > 0.38
        ? slate700
        : const Color(0xFFE2E8F0);
  }
}

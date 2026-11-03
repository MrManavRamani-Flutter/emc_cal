import 'package:flutter/material.dart';

class AppTheme {
  // Preset Theme Colors Available to Users (Vibrant, Light & Dark categories)
  static const List<Map<String, String>> presetThemeColors = [
    // Vibrant / Classic
    {'name': 'Sapphire Blue', 'hex': '#0066FF', 'type': 'vibrant'},
    {'name': 'Royal Indigo', 'hex': '#4F46E5', 'type': 'vibrant'},
    {'name': 'Violet Purple', 'hex': '#7C3AED', 'type': 'vibrant'},
    {'name': 'Emerald Green', 'hex': '#059669', 'type': 'vibrant'},
    {'name': 'Crimson Ruby', 'hex': '#DC2626', 'type': 'vibrant'},
    {'name': 'Sunset Amber', 'hex': '#D97706', 'type': 'vibrant'},
    {'name': 'Ocean Teal', 'hex': '#0891B2', 'type': 'vibrant'},

    // Light / Pastel Palette (हल्के एवं शांत रंग)
    {'name': 'Soft Sky Blue (Light)', 'hex': '#38BDF8', 'type': 'light'},
    {'name': 'Mint Aqua (Light)', 'hex': '#34D399', 'type': 'light'},
    {'name': 'Lavender Mist (Light)', 'hex': '#A78BFA', 'type': 'light'},
    {'name': 'Golden Honey (Light)', 'hex': '#FBBF24', 'type': 'light'},
    {'name': 'Pastel Peach (Light)', 'hex': '#FB923C', 'type': 'light'},
    {'name': 'Rose Quartz (Light)', 'hex': '#F472B6', 'type': 'light'},
    {'name': 'Soft Cyan (Light)', 'hex': '#22D3EE', 'type': 'light'},

    // Dark / Deep Palette (गहरे एवं रॉयल रंग)
    {'name': 'Midnight Slate (Dark)', 'hex': '#334155', 'type': 'dark'},
    {'name': 'Deep Navy (Dark)', 'hex': '#1E3A8A', 'type': 'dark'},
    {'name': 'Forest Emerald (Dark)', 'hex': '#065F46', 'type': 'dark'},
    {'name': 'Dark Burgundy (Dark)', 'hex': '#881337', 'type': 'dark'},
    {'name': 'Charcoal Shadow (Dark)', 'hex': '#1F2937', 'type': 'dark'},
    {'name': 'Royal Indigo (Dark)', 'hex': '#3730A3', 'type': 'dark'},
  ];

  // Brand Colors
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color primaryBlueHover = Color(0xFF0052CC);
  static const Color primaryBlueLight = Color(0xFFEFF6FF);

  static const Color darkNavy = Color(0xFF0F172A);
  static const Color slateDark = Color(0xFF1E293B);
  static const Color slateMedium = Color(0xFF475569);
  static const Color slateLight = Color(0xFF64748B);
  static const Color slateBorder = Color(0xFFE2E8F0);
  static const Color slateBackground = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);

  // Dark Mode Base Colors
  static const Color darkScaffoldBg = Color(0xFF0B1120);
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkSurfaceSubtle = Color(0xFF0F172A);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Status & Action Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenDark = Color(0xFF059669);
  static const Color successGreenLight = Color(0xFFECFDF5);

  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerRedLight = Color(0xFFFEF2F2);
  static const Color dangerRedDark = Color(0xFFDC2626);

  static const Color purpleAccent = Color(0xFF9333EA);
  static const Color purpleLight = Color(0xFFFAF5FF);

  static const Color amberAccent = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFFFBEB);

  // Hex Color Parsing Helper
  static Color parseColor(String? hex, [Color fallback = primaryBlue]) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    String clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    if (clean.length == 8) {
      final val = int.tryParse(clean, radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  /// Calculates guaranteed high-contrast text color on top of any background color.
  /// Prevents light accent colors from causing unreadable labels.
  static Color contrastText(Color bg) {
    return bg.computeLuminance() > 0.38 ? const Color(0xFF0F172A) : Colors.white;
  }

  /// Calculates secondary text color for muted labels on top of accent color
  static Color contrastSecondaryText(Color bg) {
    return bg.computeLuminance() > 0.38 ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  }

  /// Checks if a color is light (luminance > 0.38)
  static bool isLightColor(Color c) => c.computeLuminance() > 0.38;

  // Theme Helpers for Dynamic Styling
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkCardBg : white;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : slateBorder;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : darkNavy;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : slateMedium;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : slateLight;

  static Color hintColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  static Color surfaceSubtle(BuildContext context) =>
      isDark(context) ? darkSurfaceSubtle : slateBackground;

  static Color tableHeaderBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  static Color tableRowHover(BuildContext context) =>
      isDark(context) ? const Color(0xFF26354A) : const Color(0xFFF8FAFC);

  static Color tableRowSelected(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);

  // Dynamic ThemeData Generator
  static ThemeData getTheme({required bool isDark, Color? accentColor}) {
    final accent = accentColor ?? primaryBlue;

    if (isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Segoe UI',
        primaryColor: accent,
        scaffoldBackgroundColor: darkScaffoldBg,
        colorScheme: ColorScheme.dark(
          primary: accent,
          surface: darkCardBg,
          surfaceTint: Colors.transparent,
          outline: darkBorder,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: darkTextPrimary),
          bodyMedium: TextStyle(color: darkTextSecondary),
          bodySmall: TextStyle(color: darkTextMuted),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: darkCardBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: const TextStyle(color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: darkCardBg,
          surfaceTintColor: Colors.transparent,
          headerBackgroundColor: accent,
          headerForegroundColor: Colors.white,
          headerHeadlineStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
          headerHelpStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white70),
          dayStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            if (states.contains(WidgetState.disabled)) return darkTextMuted;
            return darkTextPrimary;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accent;
            return null;
          }),
          todayForegroundColor: WidgetStateProperty.all(accent),
          todayBorder: BorderSide(color: accent, width: 1.5),
          yearForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return darkTextPrimary;
          }),
          yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accent;
            return null;
          }),
          cancelButtonStyle: TextButton.styleFrom(foregroundColor: darkTextSecondary),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: accent,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: darkCardBg,
          hourMinuteColor: darkSurfaceSubtle,
          hourMinuteTextColor: darkTextPrimary,
          dayPeriodColor: darkSurfaceSubtle,
          dayPeriodTextColor: darkTextSecondary,
          dialHandColor: accent,
          dialBackgroundColor: darkSurfaceSubtle,
          dialTextColor: darkTextPrimary,
          entryModeIconColor: accent,
          cancelButtonStyle: TextButton.styleFrom(foregroundColor: darkTextSecondary),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: accent,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardThemeData(
          color: darkCardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: darkBorder, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurfaceSubtle,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: contrastText(accent),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1E293B),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          elevation: 8,
        ),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Segoe UI',
      primaryColor: accent,
      scaffoldBackgroundColor: slateBackground,
      colorScheme: ColorScheme.light(
        primary: accent,
        surface: white,
        surfaceTint: Colors.transparent,
        outline: slateBorder,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkNavy, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: darkNavy, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: darkNavy, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: slateDark),
        bodyMedium: TextStyle(color: slateMedium),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(color: darkNavy, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: slateDark, fontSize: 14),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: accent,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        headerHelpStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white70),
        dayStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return slateLight;
          return darkNavy;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.all(accent),
        todayBorder: BorderSide(color: accent, width: 1.5),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return darkNavy;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return null;
        }),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: slateMedium),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: white,
        hourMinuteColor: slateBackground,
        hourMinuteTextColor: darkNavy,
        dayPeriodColor: slateBackground,
        dayPeriodTextColor: slateMedium,
        dialHandColor: accent,
        dialBackgroundColor: slateBackground,
        dialTextColor: darkNavy,
        entryModeIconColor: accent,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: slateMedium),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: slateBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: slateBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: slateBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: contrastText(accent),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        elevation: 8,
      ),
    );
  }

  // Backward compatibility
  static ThemeData get lightTheme => getTheme(isDark: false);
}

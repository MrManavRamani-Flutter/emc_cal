import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:emb_cal/core/app_theme.dart';
import 'package:emb_cal/models/settings_model.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Theme and Color Settings Tests', () {
    test('AppTheme parseColor parses 6-digit, 8-digit, and hashtag hex colors', () {
      expect(AppTheme.parseColor('#0066FF'), const Color(0xFF0066FF));
      expect(AppTheme.parseColor('0066FF'), const Color(0xFF0066FF));
      expect(AppTheme.parseColor('#4F46E5'), const Color(0xFF4F46E5));
      expect(AppTheme.parseColor('#DC2626'), const Color(0xFFDC2626));
      expect(AppTheme.parseColor('#FF059669'), const Color(0xFF059669));
      // Fallback on invalid
      expect(AppTheme.parseColor('invalid_color'), AppTheme.primaryBlue);
      expect(AppTheme.parseColor(null), AppTheme.primaryBlue);
    });

    test('SettingsModel serialization preserves isDarkMode and themeColorHex', () {
      final defaultSettings = SettingsModel();
      expect(defaultSettings.isDarkMode, false);
      expect(defaultSettings.themeColorHex, '#0066FF');

      final custom = defaultSettings.copyWith(
        isDarkMode: true,
        themeColorHex: '#7C3AED',
      );
      expect(custom.isDarkMode, true);
      expect(custom.themeColorHex, '#7C3AED');

      final map = custom.toMap();
      expect(map['is_dark_mode'], 1);
      expect(map['theme_color_hex'], '#7C3AED');

      final restored = SettingsModel.fromMap(map);
      expect(restored.isDarkMode, true);
      expect(restored.themeColorHex, '#7C3AED');
    });

    test('ProductionProvider toggles dark mode and updates theme color', () async {
      final provider = ProductionProvider();
      while (provider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 20));
      }

      expect(provider.settings.isDarkMode, false);

      await provider.toggleDarkMode(true);
      expect(provider.settings.isDarkMode, true);

      await provider.toggleDarkMode();
      expect(provider.settings.isDarkMode, false);

      await provider.setThemeColorHex('#059669');
      expect(provider.settings.themeColorHex, '#059669');
    });

    test('AppTheme getTheme provides distinct muted hintStyle in both dark and light modes', () {
      final darkTheme = AppTheme.getTheme(isDark: true);
      expect(darkTheme.inputDecorationTheme.hintStyle?.color, const Color(0xFF64748B));

      final lightTheme = AppTheme.getTheme(isDark: false);
      expect(lightTheme.inputDecorationTheme.hintStyle?.color, const Color(0xFF94A3B8));
    });
  });
}

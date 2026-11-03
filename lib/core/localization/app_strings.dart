import 'package:flutter/material.dart';
import 'app_en.dart';
import 'app_guj.dart';
import 'app_hindi.dart';

export 'app_en.dart';
export 'app_guj.dart';
export 'app_hindi.dart';

/// Centralized, high-performance Localization & Multi-Language Dictionary
/// Sourced directly from app_en.dart, app_guj.dart, and app_hindi.dart
class AppStrings {
  AppStrings._();

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
  ];

  /// Get localized string from dedicated language dictionary by key
  static String get(String key, [String? langCode]) {
    final lang = langCode ?? 'en';
    switch (lang) {
      case 'gu':
        return appGuj[key] ?? appEn[key] ?? key;
      case 'hi':
        return appHindi[key] ?? appEn[key] ?? key;
      case 'en':
      default:
        return appEn[key] ?? key;
    }
  }

  /// High-performance inline localized string resolver
  static String t(String? langCode, {required String en, String? gu, String? hi}) {
    final lang = langCode ?? 'en';
    switch (lang) {
      case 'gu':
        return gu ?? en;
      case 'hi':
        return hi ?? en;
      case 'en':
      default:
        return en;
    }
  }

  /// Category name resolver translating Dhaga/Thread appropriately
  static String categoryName(String cat, [String? langCode]) {
    final lower = cat.trim().toLowerCase();
    if (lower == 'dhaga' || lower == 'daga' || lower == 'thread') {
      return t(langCode, en: 'Thread', gu: 'દોરા / ધાગા', hi: 'धागा');
    } else if (lower == 'beads') {
      return t(langCode, en: 'Beads', gu: 'મોતી (Beads)', hi: 'मोती');
    } else if (lower == 'sequence') {
      return t(langCode, en: 'Sequence', gu: 'સીક્વન્સ', hi: 'सीक्वेंस');
    }
    return cat;
  }
}

/// Extension for fast, type-safe access in any BuildContext
extension AppLocalizationExtension on BuildContext {
  String tr(String key, [String? langCode]) {
    return AppStrings.get(key, langCode ?? 'en');
  }
}

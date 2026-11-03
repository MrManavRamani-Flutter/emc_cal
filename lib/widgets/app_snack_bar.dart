import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../providers/production_provider.dart';

/// Ultra-luxurious, decorated SnackBar notifications for Om Mavtar Group.
/// Features glowing borders, dual-line typography (Title + Message), icon badges, and smooth animations.
class AppSnackBar {
  AppSnackBar._();

  static String _defaultTitle(BuildContext context, String type) {
    try {
      final provider = Provider.of<ProductionProvider>(context, listen: false);
      final lang = provider.settings.appLanguage;
      switch (type) {
        case 'success':
          return AppStrings.t(lang, en: 'Success', gu: 'સફળતા', hi: 'सफलता');
        case 'error':
          return AppStrings.t(lang, en: 'Error / Failed', gu: 'ભૂલ', hi: 'त्रुटि');
        case 'warning':
          return AppStrings.t(lang, en: 'Warning / Notice', gu: 'ધ્યાન આપો', hi: 'चेतावनी');
        case 'info':
        default:
          return AppStrings.t(lang, en: 'Information', gu: 'માહિતી', hi: 'जानकारी');
      }
    } catch (_) {
      switch (type) {
        case 'success':
          return 'Success';
        case 'error':
          return 'Error / Failed';
        case 'warning':
          return 'Warning / Notice';
        case 'info':
        default:
          return 'Information';
      }
    }
  }

  /// Displays an emerald-tinted success SnackBar.
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustom(
      context: context,
      title: title ?? _defaultTitle(context, 'success'),
      message: message,
      icon: Icons.check_circle_rounded,
      bgColor: const Color(0xFF064E3B),
      borderColor: const Color(0xFF10B981),
      iconColor: const Color(0xFF34D399),
      action: action,
      duration: duration,
    );
  }

  /// Displays a crimson-tinted error SnackBar.
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showCustom(
      context: context,
      title: title ?? _defaultTitle(context, 'error'),
      message: message,
      icon: Icons.error_rounded,
      bgColor: const Color(0xFF7F1D1D),
      borderColor: const Color(0xFFEF4444),
      iconColor: const Color(0xFFF87171),
      action: action,
      duration: duration,
    );
  }

  /// Displays an amber-tinted warning SnackBar.
  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showCustom(
      context: context,
      title: title ?? _defaultTitle(context, 'warning'),
      message: message,
      icon: Icons.warning_amber_rounded,
      bgColor: const Color(0xFF78350F),
      borderColor: const Color(0xFFF59E0B),
      iconColor: const Color(0xFFFBBF24),
      action: action,
      duration: duration,
    );
  }

  /// Displays an indigo-tinted info SnackBar.
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustom(
      context: context,
      title: title ?? _defaultTitle(context, 'info'),
      message: message,
      icon: Icons.info_outline_rounded,
      bgColor: const Color(0xFF1E1B4B),
      borderColor: const Color(0xFF6366F1),
      iconColor: const Color(0xFF818CF8),
      action: action,
      duration: duration,
    );
  }

  static void _showCustom({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    SnackBarAction? action,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Text Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),

            if (action != null) ...[
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  action.onPressed();
                },
                style: TextButton.styleFrom(
                  backgroundColor: borderColor.withValues(alpha: 0.25),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: Text(
                  action.label,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }
}

import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'app_button.dart';

/// Reusable, high-performance Empty State Widget for OM MAVTAR GROUP
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool? isDark;
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.isDark,
    this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? AppTheme.isDark(context);
    final theme = Theme.of(context);
    final effectiveAccent = accentColor ?? theme.primaryColor;
    final textPrimary = AppTheme.textPrimary(context);
    final textMuted = AppTheme.textSecondary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: effectiveAccent.withValues(alpha: dark ? 0.18 : 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: effectiveAccent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: textMuted,
                  height: 1.4,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              AppButton.primary(
                label: actionLabel!,
                icon: Icons.refresh_rounded,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

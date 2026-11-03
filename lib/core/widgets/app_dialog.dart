import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'app_button.dart';

/// Standard, high-contrast modal dialog shell for OM MAVTAR GROUP
class AppDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget content;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final bool isConfirmLoading;
  final bool isDanger;
  final double maxWidth;
  final List<Widget>? customActions;

  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.content,
    this.confirmLabel,
    this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.isConfirmLoading = false,
    this.isDanger = false,
    this.maxWidth = 600,
    this.customActions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppTheme.isDark(context);
    final cardBg = AppTheme.cardBg(context);
    final border = AppTheme.border(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final accent = theme.primaryColor;

    return Dialog(
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border, width: 1)),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (isDanger ? AppTheme.dangerRed : accent)
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isDanger ? AppTheme.dangerRed : accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    splashRadius: 18,
                    color: textSecondary,
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Dialog Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: content,
              ),
            ),

            // Dialog Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: border, width: 1)),
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: customActions ??
                    [
                      AppButton.outline(
                        label: cancelLabel,
                        onPressed: onCancel ?? () => Navigator.of(context).pop(),
                      ),
                      if (confirmLabel != null && onConfirm != null) ...[
                        const SizedBox(width: 10),
                        isDanger
                            ? AppButton.danger(
                                label: confirmLabel!,
                                onPressed: onConfirm,
                                isLoading: isConfirmLoading,
                              )
                            : AppButton.primary(
                                label: confirmLabel!,
                                onPressed: onConfirm,
                                isLoading: isConfirmLoading,
                              ),
                      ],
                    ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

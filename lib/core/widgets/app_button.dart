import 'package:flutter/material.dart';
import '../app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

/// High-contrast, theme-aware custom button for OM MAVTAR GROUP
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final String? tooltip;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.borderRadius = 8.0,
    this.tooltip,
    this.fontSize,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.borderRadius = 8.0,
    this.tooltip,
    this.fontSize,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.borderRadius = 8.0,
    this.tooltip,
    this.fontSize,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.borderRadius = 8.0,
    this.tooltip,
    this.fontSize,
  }) : variant = AppButtonVariant.outline;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.borderRadius = 8.0,
    this.tooltip,
    this.fontSize,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppTheme.isDark(context);
    final accent = theme.primaryColor;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = accent;
        fg = AppTheme.contrastText(accent);
        break;
      case AppButtonVariant.secondary:
        bg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        fg = isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B);
        borderSide = BorderSide(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        );
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B);
        borderSide = BorderSide(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.2,
        );
        break;
      case AppButtonVariant.danger:
        bg = AppTheme.dangerRed;
        fg = Colors.white;
        break;
    }

    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    // Ensure clean label without redundant leading '+' if an icon is already displayed
    final cleanLabel = (icon != null && label.trimLeft().startsWith('+'))
        ? label.trimLeft().replaceFirst(RegExp(r'^\+\s*'), '')
        : label;

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          cleanLabel,
          style: TextStyle(
            fontSize: fontSize ?? 13.5,
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );

    Widget button = Material(
      color: onPressed == null ? bg.withValues(alpha: 0.5) : bg,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
          ),
          child: content,
        ),
      ),
    );

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

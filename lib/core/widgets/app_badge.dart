import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Clean, theme-aware badge pill for Shift, Category, and Status tags
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.onTap,
  });

  const AppBadge.success({
    super.key,
    required this.label,
    this.icon = Icons.check_circle_outline_rounded,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.onTap,
  })  : color = const Color(0xFF059669),
        backgroundColor = null;

  const AppBadge.warning({
    super.key,
    required this.label,
    this.icon = Icons.warning_amber_rounded,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.onTap,
  })  : color = const Color(0xFFD97706),
        backgroundColor = null;

  const AppBadge.danger({
    super.key,
    required this.label,
    this.icon = Icons.error_outline_rounded,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.onTap,
  })  : color = const Color(0xFFDC2626),
        backgroundColor = null;

  const AppBadge.info({
    super.key,
    required this.label,
    this.icon = Icons.info_outline_rounded,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.onTap,
  })  : color = const Color(0xFF2563EB),
        backgroundColor = null;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bg = backgroundColor ??
        (isDark ? color.withValues(alpha: 0.22) : color.withValues(alpha: 0.12));
    final fg = isDark ? color.withValues(alpha: 0.95) : color;

    Widget badge = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: badge,
      );
    }
    return badge;
  }
}

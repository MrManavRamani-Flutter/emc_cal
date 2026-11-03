import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Custom, highly polished and fully responsive List Card widget designed as a modern,
/// robust replacement for Flutter's [ListTile].
///
/// Features:
/// - Zero dependence on ListTile constraints or hardcoded heights.
/// - Optional leading, title, subtitle, and trailing widgets.
/// - Optional [onTap] with interactive InkWell feedback.
/// - Custom background, border, selection highlight, and padding.
/// - Fully responsive with auto-wrapping or flexible layout to prevent any RenderFlex overflow.
class AppListCard extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final String? titleText;
  final Widget? subtitle;
  final String? subtitleText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? selectedColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool dense;
  final CrossAxisAlignment crossAxisAlignment;

  const AppListCard({
    super.key,
    this.leading,
    this.title,
    this.titleText,
    this.subtitle,
    this.subtitleText,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.selectedColor,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.margin,
    this.dense = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = selectedColor ?? AppTheme.primaryBlue;
    final rRadius = borderRadius ?? BorderRadius.circular(10);

    final effectiveBgColor = backgroundColor ??
        (isSelected
            ? accent.withValues(alpha: isDark ? 0.20 : 0.08)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)));

    final effectiveBorderColor = borderColor ??
        (isSelected
            ? accent.withValues(alpha: isDark ? 0.8 : 0.6)
            : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)));

    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);

    Widget? titleWidget = title;
    if (titleWidget == null && titleText != null) {
      titleWidget = Text(
        titleText!,
        style: TextStyle(
          fontSize: dense ? 13 : 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? accent : primaryText,
        ),
      );
    }

    Widget? subtitleWidget = subtitle;
    if (subtitleWidget == null && subtitleText != null) {
      subtitleWidget = Text(
        subtitleText!,
        style: TextStyle(
          fontSize: dense ? 11 : 12,
          fontWeight: FontWeight.normal,
          color: secondaryText,
        ),
      );
    }

    final cardContent = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (titleWidget != null) titleWidget,
                if (subtitleWidget != null) ...[
                  SizedBox(height: dense ? 2 : 4),
                  subtitleWidget,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );

    final decoratedBox = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: rRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: rRadius,
        child: onTap != null
            ? InkWell(
                borderRadius: rRadius,
                onTap: onTap,
                child: cardContent,
              )
            : cardContent,
      ),
    );

    return decoratedBox;
  }
}

/// Custom Switch Card widget that replaces [SwitchListTile] with a clean,
/// modern, responsive UI and fully configurable callback and tap behavior.
class AppSwitchCard extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final String? titleText;
  final Widget? subtitle;
  final String? subtitleText;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isDense;

  const AppSwitchCard({
    super.key,
    this.leading,
    this.title,
    this.titleText,
    this.subtitle,
    this.subtitleText,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppTheme.primaryBlue;

    return AppListCard(
      leading: leading,
      title: title,
      titleText: titleText,
      subtitle: subtitle,
      subtitleText: subtitleText,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      dense: isDense,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      trailing: Switch(
        value: value,
        activeThumbColor: effectiveActiveColor,
        onChanged: onChanged,
      ),
    );
  }
}

/// Custom Checkbox Card widget that replaces [CheckboxListTile] with a clean,
/// modern, responsive UI with leading or trailing checkbox control.
class AppCheckboxCard extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final String? titleText;
  final Widget? subtitle;
  final String? subtitleText;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool checkboxLeading;
  final bool isDense;

  const AppCheckboxCard({
    super.key,
    this.leading,
    this.title,
    this.titleText,
    this.subtitle,
    this.subtitleText,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.checkboxLeading = true,
    this.isDense = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppTheme.primaryBlue;

    final checkboxWidget = SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: value,
        activeColor: effectiveActiveColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        onChanged: onChanged,
      ),
    );

    Widget? titleWidget = title;
    if (titleWidget == null && titleText != null) {
      titleWidget = Text(
        titleText!,
        style: TextStyle(
          fontSize: isDense ? 13 : 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppTheme.textPrimary(context),
        ),
      );
    }

    return AppListCard(
      leading: checkboxLeading ? checkboxWidget : leading,
      title: titleWidget,
      subtitle: subtitle,
      subtitleText: subtitleText,
      trailing: !checkboxLeading ? checkboxWidget : null,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      backgroundColor: backgroundColor ?? Colors.transparent,
      borderColor: borderColor ?? Colors.transparent,
      dense: isDense,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
    );
  }
}

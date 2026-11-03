import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Standardized, theme-aware search bar for OM MAVTAR GROUP Desktop
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final IconData prefixIcon;
  final double? width;
  final bool autofocus;

  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search records...',
    this.onChanged,
    this.onClear,
    this.prefixIcon = Icons.search_rounded,
    this.width,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textPrimary = AppTheme.textPrimary(context);
    final border = AppTheme.border(context);
    final surface = AppTheme.isDark(context)
        ? const Color(0xFF0F172A)
        : const Color(0xFFFFFFFF);

    Widget field = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.isNotEmpty;

        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1),
          ),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 18,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      splashRadius: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                      onPressed: () {
                        controller.clear();
                        if (onChanged != null) onChanged!('');
                        if (onClear != null) onClear!();
                      },
                      tooltip: 'Clear search',
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        );
      },
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }
}

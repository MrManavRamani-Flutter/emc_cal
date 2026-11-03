import 'package:flutter/material.dart';

/// Reusable Inline Dropdown Pill for live in-place table cell value changes (e.g. Rate, Heads).
/// Extracts duplicate dropdown styling and avoids rebuilding surrounding rows.
class InlineDropdownPill<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String labelPrefix;
  final Color color;
  final bool isDark;
  final String Function(T)? itemLabelBuilder;

  const InlineDropdownPill({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelPrefix,
    required this.color,
    required this.isDark,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color.withValues(alpha: isDark ? 0.16 : 0.08);
    final borderColor = color.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
          isDense: true,
          icon: Icon(Icons.arrow_drop_down_rounded, size: 16, color: color),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          onChanged: (newVal) {
            if (newVal != null && newVal != value) {
              onChanged(newVal);
            }
          },
          items: items.map((item) {
            final text = itemLabelBuilder != null ? itemLabelBuilder!(item) : '$labelPrefix$item';
            return DropdownMenuItem<T>(
              value: item,
              child: Text(text),
            );
          }).toList(),
        ),
      ),
    );
  }
}

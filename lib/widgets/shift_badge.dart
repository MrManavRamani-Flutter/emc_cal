import 'package:flutter/material.dart';

/// Reusable, high-performance Shift Badge for Day/Night shifts.
/// Designed as a lightweight StatelessWidget to prevent unnecessary rebuilds.
class ShiftBadge extends StatelessWidget {
  final String shift;
  final bool isDark;
  final bool isCompact;

  const ShiftBadge({
    super.key,
    required this.shift,
    this.isDark = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDay = shift.trim().toLowerCase() == 'day';
    final badgeColor = isDay ? Colors.amber.shade700 : Colors.indigo.shade400;
    final bgColor = isDay
        ? Colors.amber.withValues(alpha: isDark ? 0.16 : 0.12)
        : Colors.indigo.withValues(alpha: isDark ? 0.18 : 0.12);
    final borderColor = isDay
        ? Colors.amber.withValues(alpha: 0.35)
        : Colors.indigo.withValues(alpha: 0.35);

    final icon = isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    final label = isDay ? 'Day' : 'Night';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: isCompact ? 11 : 13, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

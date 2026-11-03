import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';

/// Reusable, high-performance KPI Metric Item for dashboard and summary cards.
class KpiMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String? subtitle;
  final VoidCallback? onTap;

  const KpiMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : AppTheme.darkNavy;
    final textMuted = isDark ? const Color(0xFF94A3B8) : AppTheme.slateMedium;
    final iconBg = color.withValues(alpha: isDark ? 0.18 : 0.10);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: 0.2,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Reusable Shift Summary Badge displaying Batches, Stitches, and Revenue
class ShiftSummaryPill extends StatelessWidget {
  final String label;
  final int batches;
  final int stitches;
  final double amount;
  final String currency;
  final Color color;
  final bool isDark;

  const ShiftSummaryPill({
    super.key,
    required this.label,
    required this.batches,
    required this.stitches,
    required this.amount,
    required this.currency,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08);
    final borderColor = color.withValues(alpha: 0.30);
    final textDark = isDark ? Colors.white : AppTheme.darkNavy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            '$batches b | ${NumberFormat.compact().format(stitches)} st | $currency${NumberFormat('#,##,###').format(amount.round())}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }
}

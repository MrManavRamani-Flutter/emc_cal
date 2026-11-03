import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';

/// Reusable Account Progress Card used across Dashboard and Production Entry.
/// Renders account branding, revenue, stitches, batches count, and visual progress indicator.
class AccountProgressCard extends StatelessWidget {
  final String accountName;
  final String area;
  final Color color;
  final double totalRevenue;
  final int totalStitches;
  final int batchesCount;
  final String currency;
  final double progressPercent;
  final bool isDark;
  final bool isSelected;
  final bool isTopProducer;
  final VoidCallback? onTap;
  final double? width;

  const AccountProgressCard({
    super.key,
    required this.accountName,
    required this.area,
    required this.color,
    required this.totalRevenue,
    required this.totalStitches,
    required this.batchesCount,
    required this.currency,
    required this.progressPercent,
    required this.isDark,
    this.isSelected = false,
    this.isTopProducer = false,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isSelected
        ? color
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final textPrimary = isDark ? Colors.white : AppTheme.darkNavy;
    final textMuted = isDark ? const Color(0xFF94A3B8) : AppTheme.slateMedium;

    Widget card = Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: isSelected ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Account Name & Area Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        accountName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isTopProducer) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events_rounded, size: 11, color: Colors.white),
                          SizedBox(width: 3),
                          Text('Top #1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      area.isNotEmpty ? area : 'Khata',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Revenue & Stitches
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$currency${NumberFormat('#,##,###.00').format(totalRevenue)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF4ADE80) : AppTheme.successGreenDark,
                ),
              ),
              Text(
                '${NumberFormat('#,##,###').format(totalStitches)} st',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar (Percent of Total Stitches)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progressPercent / 100.0).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),

          // Footer: Batches Count & Share %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$batchesCount Batches',
                  style: TextStyle(fontSize: 11, color: textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${progressPercent.toStringAsFixed(1)}% factory share',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Reusable, lightweight Account/Khata Badge.
/// Displays the account category name with its thematic color and optional area tag.
class AccountBadge extends StatelessWidget {
  final String accountName;
  final Color? color;
  final String? colorHex;
  final String? area;
  final bool isDark;
  final bool isCompact;

  const AccountBadge({
    super.key,
    required this.accountName,
    this.color,
    this.colorHex,
    this.area,
    this.isDark = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ??
        (colorHex != null ? AppTheme.parseColor(colorHex!) : AppTheme.primaryBlue);
    final bgColor = badgeColor.withValues(alpha: isDark ? 0.16 : 0.10);
    final borderColor = badgeColor.withValues(alpha: 0.35);

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
          Container(
            width: isCompact ? 6 : 7,
            height: isCompact ? 6 : 7,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            accountName,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
              letterSpacing: 0.2,
            ),
          ),
          if (area != null && area!.trim().isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '(${area!.trim()})',
              style: TextStyle(
                fontSize: isCompact ? 9 : 10,
                color: badgeColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

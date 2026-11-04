import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Reusable, high-performance Table Pagination Bar.
/// Eliminates massive duplicated pagination code across Dashboard, Production Entry, and Account Tables.
class TablePaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onRowsPerPageChanged;
  final bool isDark;
  final Color? accentColor;

  const TablePaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.rowsPerPage,
    required this.onPageChanged,
    this.onRowsPerPageChanged,
    this.rowsPerPageOptions = const [10, 25, 50, -1],
    this.isDark = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppTheme.primaryBlue;
    final textMuted = isDark ? const Color(0xFF94A3B8) : AppTheme.slateMedium;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final isShowAll = rowsPerPage <= 0;
    final startItem = totalItems == 0 ? 0 : (isShowAll ? 1 : (currentPage - 1) * rowsPerPage + 1);
    final endItem = isShowAll ? totalItems : (currentPage * rowsPerPage).clamp(0, totalItems);

    final effectiveOptions = rowsPerPageOptions.contains(-1)
        ? rowsPerPageOptions
        : [...rowsPerPageOptions, -1];

    final effectiveTotalPages = isShowAll ? 1 : (totalPages == 0 ? 1 : totalPages);
    final effectiveCurrentPage = isShowAll ? 1 : currentPage;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Range indicator
          Text(
            totalItems == 0
                ? 'No records found'
                : 'Showing $startItem-$endItem of $totalItems entries',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(width: 24),

          // Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rows per page dropdown
              if (onRowsPerPageChanged != null) ...[
                Text('Rows per page: ', style: TextStyle(fontSize: 12, color: textMuted)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButton<int>(
                    value: effectiveOptions.contains(rowsPerPage) ? rowsPerPage : effectiveOptions.first,
                    isDense: true,
                    underline: const SizedBox(),
                    items: effectiveOptions.map((n) {
                      return DropdownMenuItem<int>(
                        value: n,
                        child: Text(
                          n <= 0 ? 'Show All' : '$n',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: n <= 0 ? FontWeight.bold : FontWeight.normal,
                            color: isDark ? Colors.white : AppTheme.darkNavy,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onRowsPerPageChanged!(val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Page indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Page $effectiveCurrentPage of $effectiveTotalPages',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: effectiveAccent),
                ),
              ),
              const SizedBox(width: 12),

              // First Page Button
              IconButton(
                icon: const Icon(Icons.first_page_rounded, size: 18),
                onPressed: (!isShowAll && effectiveCurrentPage > 1) ? () => onPageChanged(1) : null,
                tooltip: 'First Page',
                splashRadius: 18,
              ),

              // Prev Button
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: (!isShowAll && effectiveCurrentPage > 1) ? () => onPageChanged(effectiveCurrentPage - 1) : null,
                tooltip: 'Previous Page',
                splashRadius: 18,
              ),

              // Next Button
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: (!isShowAll && effectiveCurrentPage < effectiveTotalPages) ? () => onPageChanged(effectiveCurrentPage + 1) : null,
                tooltip: 'Next Page',
                splashRadius: 18,
              ),

              // Last Page Button
              IconButton(
                icon: const Icon(Icons.last_page_rounded, size: 18),
                onPressed: (!isShowAll && effectiveCurrentPage < effectiveTotalPages) ? () => onPageChanged(effectiveTotalPages) : null,
                tooltip: 'Last Page',
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

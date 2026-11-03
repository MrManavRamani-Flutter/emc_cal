import 'package:flutter/material.dart';
import '../app_theme.dart';

class AppTableColumn {
  final String label;
  final double? width;
  final TextAlign textAlign;
  final bool isNumeric;

  const AppTableColumn({
    required this.label,
    this.width,
    this.textAlign = TextAlign.left,
    this.isNumeric = false,
  });
}

/// Unified, high-contrast desktop data table for OM MAVTAR GROUP
class AppDataTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<List<Widget>> rows;
  final bool isLoading;
  final Widget? emptyState;
  final void Function(int index)? onRowTap;
  final double minWidth;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyState,
    this.onRowTap,
    this.minWidth = 750,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final cardBg = AppTheme.cardBg(context);
    final border = AppTheme.border(context);
    final headerBg = AppTheme.tableHeaderBg(context);
    final textSecondary = AppTheme.textSecondary(context);

    if (isLoading) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    if (rows.isEmpty && emptyState != null) {
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: emptyState!,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: effectiveWidth),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Container(
                color: headerBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: columns.map((col) {
                    final cell = Text(
                      col.label,
                      textAlign: col.textAlign,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                        letterSpacing: 0.3,
                      ),
                    );

                    if (col.width != null) {
                      return SizedBox(width: col.width, child: cell);
                    }
                    return Expanded(child: cell);
                  }).toList(),
                ),
              ),
              Divider(height: 1, color: border, thickness: 1),

              // Data Rows
              ...List.generate(rows.length, (rowIndex) {
                final rowData = rows[rowIndex];
                final isEven = rowIndex % 2 == 0;
                final rowBg = isEven
                    ? cardBg
                    : (isDark ? const Color(0xFF162032) : const Color(0xFFFBFDFF));

                return Material(
                  color: rowBg,
                  child: InkWell(
                    onTap: onRowTap != null ? () => onRowTap!(rowIndex) : null,
                    hoverColor: AppTheme.tableRowHover(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: border, width: 0.8)),
                      ),
                      child: Row(
                        children: List.generate(columns.length, (colIndex) {
                          final col = columns[colIndex];
                          final cell = colIndex < rowData.length
                              ? rowData[colIndex]
                              : const SizedBox.shrink();

                          if (col.width != null) {
                            return SizedBox(width: col.width, child: cell);
                          }
                          return Expanded(child: cell);
                        }),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
            ),
          );
        },
      ),
    );
  }
}

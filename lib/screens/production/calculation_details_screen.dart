import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/production_provider.dart';

class CalculationDetailsScreen extends StatelessWidget {
  const CalculationDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final record = provider.selectedRecord ??
        (provider.filteredRecords.isNotEmpty ? provider.filteredRecords.first : null);
    final currency = provider.settings.currencySymbol;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          width: 720,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.slateBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: record == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calculate_outlined, size: 48, color: AppTheme.slateMedium),
                    const SizedBox(height: 14),
                    const Text('No Production Record Selected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('Select any row in Production Entry or Dashboard to inspect its step-by-step math.', style: TextStyle(color: AppTheme.slateLight, fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => provider.setActiveNavIndex(1), // Go to Production Entry
                      child: const Text('Go to Production Entry'),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calculation Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.slateMedium),
                          onPressed: () => provider.setActiveNavIndex(1), // Back to table
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Info Chips: Design No | Machine No | Date
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.slateBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoItem('Design No.', record.designNo),
                          _infoItem('Machine No.', record.machineNo),
                          _infoItem('Date', record.formattedDate),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Step by Step Calculation
                    const Text(
                      'Step by Step Calculation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy),
                    ),
                    const SizedBox(height: 14),

                    _calcStep(1, 'Total Stitch', '= ${NumberFormat('#,##,###').format(record.totalStitch)}'),
                    _calcStep(2, 'Final Stitch', '= ${NumberFormat('#,##,###').format(record.totalStitch)} ÷ 1,000 = ${NumberFormat('#,##,###').format(record.finalStitch.toInt())}'),
                    _calcStep(3, 'Rate', '= $currency${record.rate.toStringAsFixed(2)} (Selected)'),
                    _calcStep(4, 'Amount', '= ${record.finalStitch.toInt()} × ${record.rate.toStringAsFixed(2)} = $currency${NumberFormat('#,##,###.00').format(record.amount)}'),
                    _calcStep(5, 'Heads', '= ${record.heads} (Selected)'),
                    _calcStep(6, 'Final Amount', '= ${NumberFormat('#,##,###.00').format(record.amount)} × ${record.heads} = $currency${NumberFormat('#,##,###.00').format(record.finalAmount)}'),

                    const SizedBox(height: 24),

                    // Final Amount Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Final Amount',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF166534)),
                          ),
                          Text(
                            '$currency${NumberFormat('#,##,###.00').format(record.finalAmount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.slateLight)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy)),
      ],
    );
  }

  Widget _calcStep(int stepNo, String title, String derivation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$stepNo. ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.darkNavy)),
          SizedBox(
            width: 100,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.darkNavy)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              derivation,
              style: const TextStyle(fontSize: 13, color: AppTheme.slateDark),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/production_record.dart';
import '../../providers/production_provider.dart';
import '../../core/app_theme.dart';
import '../../core/calculation_engine.dart';
import '../../widgets/app_svg_icon.dart';
import '../../widgets/app_snack_bar.dart';

class DailyBatchEntryMatrixDialog extends StatefulWidget {
  const DailyBatchEntryMatrixDialog({Key? key}) : super(key: key);

  @override
  State<DailyBatchEntryMatrixDialog> createState() => _DailyBatchEntryMatrixDialogState();
}

class _DailyBatchEntryMatrixDialogState extends State<DailyBatchEntryMatrixDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _selectedAccount = '250 Area';
  String _selectedShift = 'Day';

  final TextEditingController _globalDesignController = TextEditingController();
  final TextEditingController _globalRateController = TextEditingController(text: '0.5');

  // Per machine controllers
  final Map<String, TextEditingController> _designControllers = {};
  final Map<String, TextEditingController> _stitchControllers = {};
  final Map<String, TextEditingController> _rateControllers = {};
  final Map<String, TextEditingController> _headsControllers = {};
  final Map<String, bool> _breakdownFlags = {};
  final Map<String, FocusNode> _stitchFocusNodes = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductionProvider>();
    if (provider.accounts.isNotEmpty) {
      _selectedAccount = provider.accounts.first.name;
    }
    _globalRateController.text = provider.settings.defaultRate.toString();

    for (final machine in provider.machines) {
      _designControllers[machine.machineNo] = TextEditingController();
      _stitchControllers[machine.machineNo] = TextEditingController();
      _rateControllers[machine.machineNo] = TextEditingController(text: _globalRateController.text);
      _headsControllers[machine.machineNo] = TextEditingController(text: machine.headCapacity.toString());
      _breakdownFlags[machine.machineNo] = false;
      _stitchFocusNodes[machine.machineNo] = FocusNode();
    }
  }

  @override
  void dispose() {
    _globalDesignController.dispose();
    _globalRateController.dispose();
    for (var c in _designControllers.values) c.dispose();
    for (var c in _stitchControllers.values) c.dispose();
    for (var c in _rateControllers.values) c.dispose();
    for (var c in _headsControllers.values) c.dispose();
    for (var f in _stitchFocusNodes.values) f.dispose();
    super.dispose();
  }

  void _applyGlobalDesign(String val) {
    for (var machineNo in _designControllers.keys) {
      if (_designControllers[machineNo]!.text.isEmpty) {
        _designControllers[machineNo]!.text = val;
      }
    }
  }

  void _applyGlobalRate(String val) {
    for (var machineNo in _rateControllers.keys) {
      _rateControllers[machineNo]!.text = val;
    }
  }

  int get _totalStitches {
    int sum = 0;
    for (var machineNo in _stitchControllers.keys) {
      if (_breakdownFlags[machineNo] == true) continue;
      final text = _stitchControllers[machineNo]!.text.replaceAll(',', '').trim();
      sum += int.tryParse(text) ?? 0;
    }
    return sum;
  }

  double get _totalAmount {
    final provider = context.read<ProductionProvider>();
    double sum = 0;
    for (var machineNo in _stitchControllers.keys) {
      if (_breakdownFlags[machineNo] == true) continue;
      final text = _stitchControllers[machineNo]!.text.replaceAll(',', '').trim();
      final stitches = int.tryParse(text) ?? 0;
      final rate = double.tryParse(_rateControllers[machineNo]!.text) ?? 0.5;
      final heads = int.tryParse(_headsControllers[machineNo]!.text) ?? 32;
      final calc = CalculationEngine.calculate(
        totalStitch: stitches,
        rate: rate,
        heads: heads,
        stitchDivider: provider.settings.stitchDivider,
      );
      sum += calc.finalAmount;
    }
    return sum;
  }

  Future<void> _saveBatch() async {
    final provider = context.read<ProductionProvider>();
    final machines = provider.machines;
    if (machines.isEmpty) {
      AppSnackBar.showError(context, title: 'No Machines', message: 'Please add machines first.');
      return;
    }

    final List<ProductionRecord> recordsToSave = [];
    final combinedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
    );

    for (final machine in machines) {
      final machineNo = machine.machineNo;
      final isBreakdown = _breakdownFlags[machineNo] ?? false;
      final stitchText = _stitchControllers[machineNo]?.text.replaceAll(',', '').trim() ?? '';
      final stitches = int.tryParse(stitchText) ?? 0;

      if (!isBreakdown && stitches <= 0) continue; // Skip unentered machines

      String designNo = _designControllers[machineNo]?.text.trim() ?? '';
      if (designNo.isEmpty) {
        designNo = _globalDesignController.text.trim();
      }
      if (designNo.isEmpty) {
        designNo = 'GENERAL';
      }

      final rate = double.tryParse(_rateControllers[machineNo]?.text ?? '') ?? provider.settings.defaultRate;
      final heads = int.tryParse(_headsControllers[machineNo]?.text ?? '') ?? machine.headCapacity;
      final effectiveNotes = isBreakdown ? 'Machine Breakdown / Idle (0 Stitch)' : '';

      final calc = CalculationEngine.calculate(
        totalStitch: isBreakdown ? 0 : stitches,
        rate: rate,
        heads: heads,
        stitchDivider: provider.settings.stitchDivider,
      );

      recordsToSave.add(
        ProductionRecord(
          date: combinedDate,
          designNo: designNo.toUpperCase(),
          machineNo: machineNo,
          totalStitch: isBreakdown ? 0 : stitches,
          finalStitch: calc.finalStitch,
          rate: rate,
          amount: calc.amount,
          heads: heads,
          finalAmount: calc.finalAmount,
          notes: effectiveNotes,
          accountName: _selectedAccount,
          shift: _selectedShift,
        ),
      );
    }

    if (recordsToSave.isEmpty) {
      AppSnackBar.showError(context, title: 'No Entries', message: 'Please enter stitches for at least one machine.');
      return;
    }

    await provider.addBatchRecords(recordsToSave);

    if (!mounted) return;
    Navigator.of(context).pop();
    AppSnackBar.showSuccess(
      context,
      title: 'Batch Saved Successfully',
      message: '${recordsToSave.length} machine entries recorded for $_selectedShift Shift ($_selectedAccount)!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final machines = provider.machines;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.cardBg(context),
      child: Container(
        width: 950,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppSvgIcon.add(size: 24, color: accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ Fast Daily Shift Batch Entry Matrix (M-01 to M-08)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter design and stitches for all machines in one go. Press Enter to jump to next machine!',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),

            // Top Bar: Account, Date, Shift, Global Design & Rate
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Row(
                children: [
                  // Account
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Khata / Account', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: provider.accounts.any((a) => a.name == _selectedAccount) ? _selectedAccount : null,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: provider.accounts.map((a) => DropdownMenuItem(value: a.name, child: Text(a.name))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAccount = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Shift
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Shift', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedShift,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Day', child: Text('☀️ Day Shift')),
                            DropdownMenuItem(value: 'Night', child: Text('🌙 Night Shift')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedShift = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Global Design No
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Default Design # (Global)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _globalDesignController,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'e.g. D-101',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: _applyGlobalDesign,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Global Rate
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rate (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _globalRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: _applyGlobalRate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Machine No & Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Design #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 1, child: Text('Heads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 1, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Stitch Count *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 1, child: Text('Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Est. Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Machines ListView Matrix
            Expanded(
              child: ListView.builder(
                itemCount: machines.length,
                itemBuilder: (context, index) {
                  final machine = machines[index];
                  final machineNo = machine.machineNo;
                  final isBreakdown = _breakdownFlags[machineNo] ?? false;
                  final stitches = int.tryParse(_stitchControllers[machineNo]?.text.replaceAll(',', '') ?? '') ?? 0;
                  final rate = double.tryParse(_rateControllers[machineNo]?.text ?? '') ?? 0.5;
                  final heads = int.tryParse(_headsControllers[machineNo]?.text ?? '') ?? machine.headCapacity;

                  final calc = CalculationEngine.calculate(
                    totalStitch: isBreakdown ? 0 : stitches,
                    rate: rate,
                    heads: heads,
                    stitchDivider: provider.settings.stitchDivider,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isBreakdown
                          ? Colors.red.withValues(alpha: 0.05)
                          : (index.isEven ? AppTheme.cardBg(context) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      children: [
                        // Machine No & Name
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(machineNo, style: TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 14)),
                              Text(machine.name, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Design No
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _designControllers[machineNo],
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: _globalDesignController.text.isEmpty ? 'D-101' : _globalDesignController.text,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Heads
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _headsControllers[machineNo],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Rate
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _rateControllers[machineNo],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Stitch Count (with Enter key jumping to next machine)
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _stitchControllers[machineNo],
                            focusNode: _stitchFocusNodes[machineNo],
                            keyboardType: TextInputType.number,
                            enabled: !isBreakdown,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'e.g. 15000',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onChanged: (_) => setState(() {}),
                            onFieldSubmitted: (_) {
                              // Jump to next machine focus
                              if (index + 1 < machines.length) {
                                FocusScope.of(context).requestFocus(_stitchFocusNodes[machines[index + 1].machineNo]);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Breakdown toggle
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Checkbox(
                              value: isBreakdown,
                              activeColor: Colors.red,
                              onChanged: (val) {
                                setState(() {
                                  _breakdownFlags[machineNo] = val ?? false;
                                  if (_breakdownFlags[machineNo]!) {
                                    _stitchControllers[machineNo]!.text = '0';
                                  }
                                });
                              },
                            ),
                          ),
                        ),

                        // Est. Amount
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${NumberFormat('#,##,###.00').format(calc.finalAmount)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isBreakdown ? Colors.red : AppTheme.textPrimary(context)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24),

            // Footer Summary & Buttons
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Shift Stitches: ${NumberFormat('#,##,###').format(_totalStitches)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Total Shift Value: ₹${NumberFormat('#,##,###.00').format(_totalAmount)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: accent)),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saveBatch,
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  label: const Text('Save All Shift Entries', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

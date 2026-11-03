import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/machine_model.dart';
import '../../providers/production_provider.dart';
import '../../widgets/widgets.dart';

class MachinesScreen extends StatefulWidget {
  const MachinesScreen({super.key});

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchFilter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddEditMachineDialog([MachineModel? machine]) {
    final formKey = GlobalKey<FormState>();
    final noCtrl = TextEditingController(text: machine?.machineNo ?? '');
    final nameCtrl = TextEditingController(text: machine?.name ?? '');
    final headsCtrl = TextEditingController(
      text: machine != null ? machine.headCapacity.toString() : '12',
    );
    bool isActive = machine?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              machine == null ? 'Add Machine' : 'Edit Machine',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: noCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Machine No.',
                        hintText: 'e.g. M-01',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter machine number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Machine Name',
                        hintText: 'e.g. Tajima (12 Head)',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter machine brand or name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: headsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Heads',
                        hintText: 'e.g. 12',
                      ),
                      validator: ProductionProvider.validateHeads,
                    ),
                    const SizedBox(height: 14),
                    AppSwitchCard(
                      titleText: 'Active Status',
                      subtitleText: 'Enable or disable this machine in production entries',
                      value: isActive,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final provider = ctx.read<ProductionProvider>();
                  final machineNo = noCtrl.text.trim().toUpperCase();

                  final isDuplicate = provider.machines.any(
                    (m) => m.machineNo.toUpperCase() == machineNo && m.id != machine?.id,
                  );
                  if (isDuplicate) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Machine number "$machineNo" already exists!'),
                        backgroundColor: AppTheme.dangerRed,
                      ),
                    );
                    return;
                  }

                  final heads = int.parse(headsCtrl.text.trim());

                  try {
                    if (machine == null) {
                      await provider.addMachine(MachineModel(
                        machineNo: machineNo,
                        name: nameCtrl.text.trim(),
                        headCapacity: heads,
                        isActive: isActive,
                      ));
                    } else {
                      await provider.updateMachine(machine.copyWith(
                        machineNo: machineNo,
                        name: nameCtrl.text.trim(),
                        headCapacity: heads,
                        isActive: isActive,
                      ));
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Error saving machine: $e'),
                          backgroundColor: AppTheme.dangerRed,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save Machine'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    final machines = provider.machines.where((m) {
      if (_searchFilter.isEmpty) return true;
      return m.machineNo.toLowerCase().contains(_searchFilter) ||
          m.name.toLowerCase().contains(_searchFilter);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Machines Title + Search input + Add Machine button
            Row(
              children: [
                Text(
                  'Machines',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                ),
                const Spacer(),
                SizedBox(
                  width: 240,
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13),
                    onChanged: (val) => setState(() => _searchFilter = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search machine...',
                      hintStyle: TextStyle(color: AppTheme.textMuted(context), fontSize: 13),
                      prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.textMuted(context)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.border(context))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.border(context))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
                      suffixIcon: _searchFilter.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 14, color: AppTheme.textMuted(context)),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchFilter = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: () => _openAddEditMachineDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Machine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Machines Table
            Expanded(
              child: machines.isEmpty
                  ? AppEmptyState(
                      icon: Icons.precision_manufacturing_outlined,
                      title: 'No Machines Found',
                      message: 'Add an embroidery machine to begin tracking production.',
                      isDark: isDark,
                      accentColor: accent,
                      actionLabel: 'Register Machine',
                      onAction: () => _openAddEditMachineDialog(),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final dynamicSpacing = ((constraints.maxWidth - 460) / 6).clamp(16.0, 48.0);
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              columnSpacing: dynamicSpacing,
                              horizontalMargin: 16,
                          headingRowHeight: 46,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 48,
                          headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                          columns: [
                            DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                            DataColumn(label: Text('Machine No.', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                            DataColumn(label: Text('Machine Name', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                            DataColumn(label: Text('Total Heads', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy))),
                          ],
                          rows: List.generate(machines.length, (idx) {
                            final m = machines[idx];
                            return DataRow(
                              cells: [
                                DataCell(Text('${idx + 1}', style: TextStyle(color: AppTheme.textSecondary(context)))),
                                DataCell(Text(m.machineNo, style: TextStyle(fontWeight: FontWeight.bold, color: accent))),
                                DataCell(Text(m.name, style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary(context)))),
                                DataCell(Text('${m.headCapacity}', style: TextStyle(color: AppTheme.textPrimary(context)))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: m.isActive
                                          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                          : (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: m.isActive
                                            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                            : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, size: 18, color: accent),
                                        onPressed: () => _openAddEditMachineDialog(m),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.dangerRed),
                                        onPressed: () async {
                                          final tiedCount = provider.allRecords.where((r) => r.machineNo == m.machineNo).length;
                                          final confirm = await ConfirmDeleteDialog.show(
                                            context: context,
                                            title: 'Move ${m.machineNo} to Recycle Bin',
                                            message: tiedCount > 0
                                                ? '${m.name} has $tiedCount recorded production batches.\n\nMoving it to the Recycle Bin will remove it from future entries, but all history is preserved and you can restore it anytime.\n\nProceed with removal?'
                                                : 'Are you sure you want to remove ${m.name}?\n\nIt will be moved to ${AppStrings.get("recycleBin", provider.settings.appLanguage)} and can be restored anytime.',
                                            confirmLabel: 'Move to Recycle Bin',
                                          );
                                          if (confirm == true && m.id != null) {
                                            await provider.deleteMachine(m.id!);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${m.machineNo} moved to ${AppStrings.get("recycleBin", provider.settings.appLanguage)}. You can restore anytime.'),
                                                  backgroundColor: AppTheme.successGreenDark,
                                                  action: SnackBarAction(
                                                    label: 'Open Bin',
                                                    textColor: Colors.amberAccent,
                                                    onPressed: () => provider.setActiveNavIndex(11),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }
}

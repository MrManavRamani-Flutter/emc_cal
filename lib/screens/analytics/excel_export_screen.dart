import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/excel_exporter.dart';
import '../../providers/production_provider.dart';
import '../../widgets/app_list_card.dart';

class ExcelExportScreen extends StatefulWidget {
  const ExcelExportScreen({super.key});

  @override
  State<ExcelExportScreen> createState() => _ExcelExportScreenState();
}

class _ExcelExportScreenState extends State<ExcelExportScreen> {
  String _reportType = 'Daily Report';
  String _selectedMachine = 'All Machines';
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  // Column toggles
  bool _incNo = true;
  bool _incDate = true;
  bool _incDesign = true;
  bool _incMachine = true;
  bool _incTotalStitch = true;
  bool _incFinalStitch = true;
  bool _incRate = true;
  bool _incAmount = true;
  bool _incHeads = true;
  bool _incFinalAmount = true;

  bool _isExporting = false;
  String? _exportSuccessPath;

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
          if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
        }
      });
    }
  }

  Future<void> _runExport() async {
    final provider = context.read<ProductionProvider>();
    var list = provider.allRecords;

    if (_selectedMachine != 'All Machines') {
      list = list.where((r) => r.machineNo == _selectedMachine).toList();
    }

    list = list.where((r) {
      final start = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
      final end = DateTime(_toDate.year, _toDate.month, _toDate.day, 23, 59, 59);
      return !r.date.isBefore(start) && !r.date.isAfter(end);
    }).toList();

    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No records match the selected date range and machine filter.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _exportSuccessPath = null;
    });

    try {
      final filename = 'Production_Report_${DateFormat('yyyyMMdd').format(_fromDate)}';
      final excelBytes = ExcelExporter.generateProductionExcel(
        records: list,
        title: '${provider.settings.companyName} - $_reportType',
        dateRangeInfo: 'Filtered by: $_selectedMachine • Range: ${DateFormat('dd-MM-yyyy').format(_fromDate)} to ${DateFormat('dd-MM-yyyy').format(_toDate)}',
        currencySymbol: provider.settings.currencySymbol,
        selectedColumns: {
          'No.': _incNo,
          'Date': _incDate,
          'Design No.': _incDesign,
          'Machine No.': _incMachine,
          'Total Stitch': _incTotalStitch,
          'Final Stitch': _incFinalStitch,
          'Rate': _incRate,
          'Amount': _incAmount,
          'Heads': _incHeads,
          'Final Amount': _incFinalAmount,
        },
      );

      if (excelBytes == null) throw Exception('Excel encoding failed');

      String? targetPath;
      try {
        final uri = await FilePicker.saveFile(
          fileName: '$filename.xlsx',
          bytes: Uint8List.fromList(excelBytes),
          dialogTitle: 'Save Excel Report',
        );
        if (uri != null) {
          targetPath = uri.toFilePath();
        }
      } catch (_) {
        final docs = await getApplicationDocumentsDirectory();
        targetPath = '${docs.path}/$filename.xlsx';
        final file = File(targetPath);
        await file.writeAsBytes(excelBytes);
      }

      targetPath ??= '${(await getApplicationDocumentsDirectory()).path}/$filename.xlsx';

      setState(() {
        _exportSuccessPath = targetPath;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    final dropdownBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : AppTheme.slateBorder;
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy;
    final labelTextColor = isDark ? const Color(0xFFE2E8F0) : AppTheme.textSecondary(context);

    InputDecoration inputDecor() => InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
        );

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Production Report',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Generate professional spreadsheets and inspect system format specifications',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),

              ],
            ),
            const SizedBox(height: 20),

            // Report Type
            Text('Report Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _reportType,
              dropdownColor: dropdownBg,
              style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
              decoration: inputDecor(),
              items: [
                DropdownMenuItem(value: 'Daily Report', child: Text('Daily Report', style: TextStyle(color: primaryTextColor))),
                DropdownMenuItem(value: 'Monthly Report', child: Text('Monthly Report', style: TextStyle(color: primaryTextColor))),
                DropdownMenuItem(value: 'Machine-wise Report', child: Text('Machine-wise Report', style: TextStyle(color: primaryTextColor))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _reportType = val);
              },
            ),
            const SizedBox(height: 16),

            // Date Range & Machine Row
            Row(
              children: [
                // Date Range
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: inputFill,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('dd-MM-yyyy').format(_fromDate),
                                  style: TextStyle(fontWeight: FontWeight.w600, color: primaryTextColor),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('to', style: TextStyle(color: AppTheme.textMuted(context))),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: inputFill,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('dd-MM-yyyy').format(_toDate),
                                  style: TextStyle(fontWeight: FontWeight.w600, color: primaryTextColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Machine Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Machine No.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: labelTextColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMachine,
                        dropdownColor: dropdownBg,
                        style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                        decoration: inputDecor(),
                        items: [
                          DropdownMenuItem(value: 'All Machines', child: Text('All Machines', style: TextStyle(color: primaryTextColor))),
                          ...provider.machines.map((m) => DropdownMenuItem(value: m.machineNo, child: Text(m.machineNo, style: TextStyle(color: primaryTextColor)))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMachine = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Include Columns Checkboxes
            Text(
              'Include Columns',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTextColor),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Column 1
                Expanded(
                  child: Column(
                    children: [
                      _checkItem('No.', _incNo, (v) => setState(() => _incNo = v ?? true), primaryTextColor, accent),
                      _checkItem('Date', _incDate, (v) => setState(() => _incDate = v ?? true), primaryTextColor, accent),
                      _checkItem('Design No.', _incDesign, (v) => setState(() => _incDesign = v ?? true), primaryTextColor, accent),
                      _checkItem('Machine No.', _incMachine, (v) => setState(() => _incMachine = v ?? true), primaryTextColor, accent),
                      _checkItem('Total Stitch', _incTotalStitch, (v) => setState(() => _incTotalStitch = v ?? true), primaryTextColor, accent),
                      _checkItem('Final Stitch', _incFinalStitch, (v) => setState(() => _incFinalStitch = v ?? true), primaryTextColor, accent),
                    ],
                  ),
                ),
                // Column 2
                Expanded(
                  child: Column(
                    children: [
                      _checkItem('Rate', _incRate, (v) => setState(() => _incRate = v ?? true), primaryTextColor, accent),
                      _checkItem('Amount', _incAmount, (v) => setState(() => _incAmount = v ?? true), primaryTextColor, accent),
                      _checkItem('Heads', _incHeads, (v) => setState(() => _incHeads = v ?? true), primaryTextColor, accent),
                      _checkItem('Final Amount', _incFinalAmount, (v) => setState(() => _incFinalAmount = v ?? true), primaryTextColor, accent),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Export Button (Bottom Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _isExporting ? null : _runExport,
                  icon: _isExporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.file_download_rounded, size: 18),
                  label: Text(_isExporting ? 'Exporting...' : 'Export to Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),

            if (_exportSuccessPath != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : AppTheme.successGreenLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF059669) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.successGreenDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saved: $_exportSuccessPath',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF34D399) : AppTheme.successGreenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _checkItem(String title, bool value, ValueChanged<bool?> onChanged, Color textColor, Color activeColor) {
    return AppCheckboxCard(
      titleText: title,
      value: value,
      textColor: textColor,
      activeColor: activeColor,
      checkboxLeading: true,
      isDense: true,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onChanged: onChanged,
    );
  }
}

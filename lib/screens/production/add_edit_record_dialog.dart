import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/calculation_engine.dart';
import '../../core/localization/app_strings.dart';
import '../../models/production_record.dart';
import '../../providers/production_provider.dart';
import '../../widgets/app_svg_icon.dart';
import '../../widgets/app_snack_bar.dart';

class AddEditRecordDialog extends StatefulWidget {
  final ProductionRecord? existingRecord;
  final String? initialAccountName;

  const AddEditRecordDialog({super.key, this.existingRecord, this.initialAccountName});

  @override
  State<AddEditRecordDialog> createState() => _AddEditRecordDialogState();
}

class _AddEditRecordDialogState extends State<AddEditRecordDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _designController;
  late TextEditingController _stitchController;
  late TextEditingController _rateController;
  late TextEditingController _headsController;

  final FocusNode _stitchFocus = FocusNode();
  final FocusNode _designFocus = FocusNode();
  final FocusNode _machineFocus = FocusNode();
  final FocusNode _rateFocus = FocusNode();
  final FocusNode _headsFocus = FocusNode();

  String? _selectedMachine;
  late String _selectedAccount;
  late String _selectedShift;
  bool _isBreakdown = false;

  @override
  void initState() {
    super.initState();
    final rec = widget.existingRecord;
    final provider = context.read<ProductionProvider>();
    final now = DateTime.now();

    // Default to current date and current time for new entries
    _selectedDate = rec?.date ?? now;
    _selectedTime = rec != null ? TimeOfDay(hour: rec.date.hour, minute: rec.date.minute) : TimeOfDay.now();

    _designController = TextEditingController(text: rec?.designNo ?? '');
    _isBreakdown = (rec != null && rec.totalStitch == 0);
    _stitchController = TextEditingController(
      text: rec != null ? rec.totalStitch.toString() : '',
    );
    _rateController = TextEditingController(
      text: rec != null ? CalculationEngine.formatRate(rec.rate) : CalculationEngine.formatRate(provider.settings.defaultRate),
    );
    _headsController = TextEditingController(
      text: rec != null ? rec.heads.toString() : provider.settings.defaultHeads.toString(),
    );

    // Select Machine
    if (rec != null) {
      _selectedMachine = rec.machineNo;
    } else if (provider.machines.isNotEmpty) {
      _selectedMachine = provider.machines.first.machineNo;
    } else {
      _selectedMachine = 'M-01';
    }

    // Select Account (Category / Khata)
    if (rec != null) {
      _selectedAccount = rec.accountName;
      _selectedShift = rec.shift;
    } else if (widget.initialAccountName != null && widget.initialAccountName!.isNotEmpty) {
      _selectedAccount = widget.initialAccountName!;
      _selectedShift = 'Day';
    } else if (provider.accounts.isNotEmpty) {
      _selectedAccount = provider.accounts.first.name;
      _selectedShift = 'Day';
    } else {
      _selectedAccount = '250 Area';
      _selectedShift = 'Day';
    }

    _stitchController.addListener(() => setState(() {}));
    _rateController.addListener(() => setState(() {}));
    _headsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _designController.dispose();
    _stitchController.dispose();
    _rateController.dispose();
    _headsController.dispose();

    _stitchFocus.dispose();
    _designFocus.dispose();
    _machineFocus.dispose();
    _rateFocus.dispose();
    _headsFocus.dispose();
    super.dispose();
  }

  Future<void> _submitForm({bool addNext = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMachine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or register a machine first')),
      );
      return;
    }

    final provider = context.read<ProductionProvider>();
    final isEdit = widget.existingRecord != null;

    final combinedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final effectiveNotes = _parsedStitch == 0
        ? 'Machine Breakdown / Idle (0 Stitch)'
        : '';

    if (isEdit) {
      await provider.updateRecord(
        id: widget.existingRecord!.id!,
        date: combinedDate,
        designNo: _designController.text,
        machineNo: _selectedMachine!,
        totalStitch: _parsedStitch,
        rate: _parsedRate,
        heads: _parsedHeads,
        notes: effectiveNotes,
        accountName: _selectedAccount,
        shift: _selectedShift,
      );
    } else {
      await provider.addRecord(
        date: combinedDate,
        designNo: _designController.text,
        machineNo: _selectedMachine!,
        totalStitch: _parsedStitch,
        rate: _parsedRate,
        heads: _parsedHeads,
        notes: effectiveNotes,
        accountName: _selectedAccount,
        shift: _selectedShift,
      );
    }

    if (!mounted) return;

    if (addNext && !isEdit) {
      final currentMachine = _selectedMachine!;
      final machines = provider.machines;
      String nextMachine = currentMachine;
      if (machines.isNotEmpty) {
        final currentIdx = machines.indexWhere((m) => m.machineNo == currentMachine);
        final nextIdx = (currentIdx >= 0 && currentIdx + 1 < machines.length) ? currentIdx + 1 : 0;
        nextMachine = machines[nextIdx].machineNo;
      }

      setState(() {
        _selectedMachine = nextMachine;
        _stitchController.clear();
        _isBreakdown = false;
      });

      final lang = provider.settings.appLanguage;
      FocusScope.of(context).requestFocus(_stitchFocus);

      AppSnackBar.showSuccess(
        context,
        title: AppStrings.t(lang, en: '$currentMachine Saved', gu: '$currentMachine સેવ થયો', hi: '$currentMachine सहेजा गया'),
        message: AppStrings.t(lang,
          en: '$currentMachine saved! Ready for $nextMachine.',
          gu: '$currentMachine સેવ થઈ ગયું! હવે $nextMachine માટે તૈયાર.',
          hi: '$currentMachine सहेजा गया! अब $nextMachine के लिए तैयार।',
        ),
      );
    } else {
      final lang = provider.settings.appLanguage;
      Navigator.of(context).pop();
      AppSnackBar.showSuccess(
        context,
        title: isEdit
            ? AppStrings.t(lang, en: 'Changes Saved', gu: 'સુધારો સેવ થયો', hi: 'बदलाव सहेजे गए')
            : AppStrings.t(lang, en: 'Record Saved', gu: 'રેકોર્ડ સેવ થયો', hi: 'रिकॉर्ड सहेजा गया'),
        message: isEdit
            ? AppStrings.t(lang, en: 'Production record updated successfully!', gu: 'પ્રોડક્શન રેકોર્ડ સફળતાપૂર્વક અપડેટ થયો!', hi: 'उत्पादन रिकॉर्ड सफलतापूर्वक अपडेट किया गया!')
            : AppStrings.t(lang, en: 'New production record added successfully!', gu: 'નવો પ્રોડક્શન રેકોર્ડ સફળતાપૂર્વક ઉમેરાયો!', hi: 'नया उत्पादन रिकॉर्ड सफलतापूर्वक जोड़ा गया!'),
      );
    }
  }

  int get _parsedStitch {
    final cleaned = _stitchController.text.replaceAll(',', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  double get _parsedRate {
    final cleaned = _rateController.text.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  int get _parsedHeads {
    final cleaned = _headsController.text.replaceAll(',', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final currency = provider.settings.currencySymbol;
    final isEdit = widget.existingRecord != null;
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final inputFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : AppTheme.slateBorder;

    final calc = CalculationEngine.calculate(
      totalStitch: _parsedStitch,
      rate: _parsedRate,
      heads: _parsedHeads,
      stitchDivider: provider.settings.stitchDivider,
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop();
        },
        const SingleActivator(LogicalKeyboardKey.enter, shift: true): () {
          if (!isEdit) _submitForm(addNext: true);
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          _submitForm();
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          _submitForm();
        },
      },
      child: FocusScope(
        child: Dialog(
          backgroundColor: AppTheme.cardBg(context),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 1),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Container(
            width: 780,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: isEdit
                                  ? AppSvgIcon.edit(color: accent, size: 20)
                                  : AppSvgIcon.add(color: accent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isEdit
                                          ? AppStrings.t(provider.settings.appLanguage, en: 'Edit Production Record', gu: 'પ્રોડક્શન રેકોર્ડ સુધારો', hi: 'उत्पादन रिकॉर्ड संपादित करें')
                                          : AppStrings.t(provider.settings.appLanguage, en: 'Add Production Record', gu: 'પ્રોડક્શન રેકોર્ડ ઉમેરો', hi: 'उत्पादन प्रविष्टि'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                    ),
                                    if (isEdit && widget.existingRecord?.id != null) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          'ID: #PR-${widget.existingRecord!.id}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'Select Category/Khata and Machine, then enter stitch & rate data',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // SECTION 1: MASTER SELECTION (Category / Khata & Machine No.)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category / Khata Dropdown
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.category_rounded, size: 14, color: accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.t(provider.settings.appLanguage, en: 'Category / Khata *', gu: 'ખાતું / કેટેગરી *', hi: 'खाता / श्रेणी *'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: provider.accounts.any((a) => a.name == _selectedAccount)
                                    ? _selectedAccount
                                    : (provider.accounts.isNotEmpty ? provider.accounts.first.name : '250 Area'),
                                dropdownColor: AppTheme.cardBg(context),
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  filled: true,
                                  fillColor: inputFill,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
                                ),
                                items: () {
                                  final list = provider.accounts.map((a) {
                                    final color = AppTheme.parseColor(a.colorHex);
                                    return DropdownMenuItem(
                                      value: a.name,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(a.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary(context))),
                                          if (a.area.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                a.area,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList();
                                  if (!provider.accounts.any((a) => a.name == _selectedAccount)) {
                                    list.add(DropdownMenuItem(
                                      value: _selectedAccount,
                                      child: Row(
                                        children: [
                                          Text(_selectedAccount, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.dangerRed)),
                                          const SizedBox(width: 6),
                                          const Text('(Archived/Deleted)', style: TextStyle(fontSize: 10, color: AppTheme.dangerRed)),
                                        ],
                                      ),
                                    ));
                                  }
                                  return list;
                                }(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedAccount = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Machine No. Dropdown
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.precision_manufacturing_rounded, size: 14, color: accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.t(provider.settings.appLanguage, en: 'Machine No. *', gu: 'મશીન નંબર *', hi: 'मशीन नंबर *'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: provider.machines.any((m) => m.machineNo == _selectedMachine)
                                    ? _selectedMachine
                                    : (provider.machines.isNotEmpty ? provider.machines.first.machineNo : null),
                                dropdownColor: AppTheme.cardBg(context),
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  filled: true,
                                  fillColor: inputFill,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
                                ),
                                items: () {
                                  final list = provider.machines.map((m) {
                                    return DropdownMenuItem(
                                      value: m.machineNo,
                                      child: Row(
                                        children: [
                                          Text(m.machineNo, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                                          const SizedBox(width: 6),
                                          Text('(${m.name})', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context))),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                  if (_selectedMachine != null && !provider.machines.any((m) => m.machineNo == _selectedMachine)) {
                                    list.add(DropdownMenuItem(
                                      value: _selectedMachine,
                                      child: Row(
                                        children: [
                                          Text(_selectedMachine!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                                          const SizedBox(width: 6),
                                          const Text('(Archived/Deleted)', style: TextStyle(fontSize: 11.5, color: AppTheme.dangerRed)),
                                        ],
                                      ),
                                    ));
                                  }
                                  return list;
                                }(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedMachine = val);
                                },
                                validator: (val) => val == null ? 'Select machine' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 2: DATE, TIME & SHIFT
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Picker (Current date by default)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.t(provider.settings.appLanguage, en: 'Date *', gu: 'તારીખ *', hi: 'तारीख *'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(8),
                                    color: inputFill,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd-MM-yyyy').format(_selectedDate),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                      Icon(Icons.calendar_today_rounded, size: 16, color: accent),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Time Picker (Current time by default)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.t(provider.settings.appLanguage, en: 'Time', gu: 'સમય', hi: 'समय'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(8),
                                    color: inputFill,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedTime.format(context),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                      Icon(Icons.access_time_rounded, size: 16, color: accent),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Shift Toggle (Day / Night)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.t(provider.settings.appLanguage, en: 'Shift', gu: 'શિફ્ટ', hi: 'पाली (Shift)'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: inputFill,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    // Day button
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _selectedShift = 'Day'),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _selectedShift == 'Day'
                                                ? (isDark ? const Color(0xFF334155) : Colors.white)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: _selectedShift == 'Day'
                                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1))]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.wb_sunny_rounded, size: 15, color: _selectedShift == 'Day' ? Colors.amber.shade600 : AppTheme.textMuted(context)),
                                              const SizedBox(width: 5),
                                              Text(
                                                AppStrings.t(provider.settings.appLanguage, en: 'Day', gu: 'દિવસ', hi: 'दिन'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: _selectedShift == 'Day' ? FontWeight.bold : FontWeight.w500,
                                                  color: _selectedShift == 'Day' ? AppTheme.textPrimary(context) : AppTheme.textMuted(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Night button
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _selectedShift = 'Night'),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _selectedShift == 'Night'
                                                ? (isDark ? const Color(0xFF334155) : Colors.white)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: _selectedShift == 'Night'
                                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1))]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.nightlight_round, size: 14, color: _selectedShift == 'Night' ? Colors.indigo.shade300 : AppTheme.textMuted(context)),
                                              const SizedBox(width: 5),
                                              Text(
                                                AppStrings.t(provider.settings.appLanguage, en: 'Night', gu: 'રાત', hi: 'रात'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: _selectedShift == 'Night' ? FontWeight.bold : FontWeight.w500,
                                                  color: _selectedShift == 'Night' ? AppTheme.textPrimary(context) : AppTheme.textMuted(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 3: STITCH & RATE
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Stitch
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Stitch *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isBreakdown = !_isBreakdown;
                                        if (_isBreakdown) {
                                          _stitchController.text = '0';
                                        } else {
                                          if (_stitchController.text == '0') {
                                            _stitchController.text = '';
                                          }
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _isBreakdown
                                            ? AppTheme.dangerRed.withValues(alpha: 0.15)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _isBreakdown ? AppTheme.dangerRed : Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isBreakdown ? Icons.build_circle_rounded : Icons.build_circle_outlined,
                                            size: 12,
                                            color: _isBreakdown ? AppTheme.dangerRed : AppTheme.textMuted(context),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Breakdown (0)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _isBreakdown ? AppTheme.dangerRed : AppTheme.textMuted(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _stitchController,
                                focusNode: _stitchFocus,
                                autofocus: !isEdit,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Ex: 3,00,000',
                                  hintStyle: TextStyle(color: AppTheme.textMuted(context), fontSize: 13),
                                  filled: true,
                                  fillColor: inputFill,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
                                ),
                                validator: (val) => ProductionProvider.validateTotalStitch(val, allowZero: _isBreakdown),
                                onChanged: (val) {
                                  final clean = val.replaceAll(',', '').trim();
                                  if (clean == '0' && !_isBreakdown) {
                                    setState(() => _isBreakdown = true);
                                  } else if (clean.isNotEmpty && clean != '0' && _isBreakdown) {
                                    setState(() => _isBreakdown = false);
                                  }
                                },
                                onFieldSubmitted: (_) => _submitForm(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Final Stitch (Auto-calculated / Disabled appearance)
                        Expanded(
                          child: _buildDisabledField(
                            context: context,
                            label: 'Final Stitch',
                            badgeText: 'Auto: ÷ 1,000',
                            value: calc.finalStitch > 0 ? NumberFormat('#,##,###').format(calc.finalStitch.toInt()) : '0',
                            tooltip: 'Formula: Total Stitch ÷ 1,000',
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Rate
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rate ($currency) *',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _rateController,
                                focusNode: _rateFocus,
                                textInputAction: TextInputAction.next,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Ex: 1.25',
                                  hintStyle: TextStyle(color: AppTheme.textMuted(context), fontSize: 13),
                                  prefixText: '$currency ',
                                  prefixStyle: TextStyle(color: accent, fontWeight: FontWeight.bold),
                                  filled: true,
                                  fillColor: inputFill,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
                                ),
                                validator: ProductionProvider.validateRate,
                                onFieldSubmitted: (_) => _submitForm(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 4: DESIGN NO, HEADS & FINAL AMOUNT
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Design No
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.t(provider.settings.appLanguage, en: 'Design No. *', gu: 'ડિઝાઇન નંબર *', hi: 'डिजाइन नं. *'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _designController,
                                focusNode: _designFocus,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.characters,
                                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Ex: D012',
                                  hintStyle: TextStyle(color: AppTheme.textMuted(context), fontSize: 13),
                                  filled: true,
                                  fillColor: inputFill,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
                                ),
                                validator: ProductionProvider.validateDesignNo,
                                onFieldSubmitted: (_) => _submitForm(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Heads
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.t(provider.settings.appLanguage, en: 'Heads *', gu: 'હેડ્સ *', hi: 'हेड्स *'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _headsController,
                                focusNode: _headsFocus,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Ex: 12',
                                  hintStyle: TextStyle(color: AppTheme.textMuted(context), fontSize: 13),
                                  filled: true,
                                  fillColor: inputFill,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 2)),
                                ),
                                validator: ProductionProvider.validateHeads,
                                onFieldSubmitted: (_) => _submitForm(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Final Amount (Auto-calculated / Disabled appearance)
                        Expanded(
                          child: _buildDisabledField(
                            context: context,
                            label: 'Final Amount ($currency)',
                            badgeText: 'Auto Calc',
                            value: '$currency${NumberFormat('#,##,###.00').format(calc.finalAmount)}',
                            tooltip: 'Formula: (Total Stitch ÷ 1000) × Rate × Heads',
                            isSuccess: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // FOOTER BUTTONS: Cancel & Save
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Cancel (Esc)', style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
                        ),
                        if (!isEdit && provider.machines.length > 1) ...[
                          OutlinedButton.icon(
                            onPressed: () => _submitForm(addNext: true),
                            icon: const Icon(Icons.skip_next_rounded, size: 18),
                            label: const Text(
                              'Save & Next Machine (Shift+Enter)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accent,
                              side: BorderSide(color: accent, width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        ElevatedButton.icon(
                          onPressed: _submitForm,
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text(isEdit ? 'Update Record (Enter)' : 'Save Record (Enter)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledField({
    required BuildContext context,
    required String label,
    required String badgeText,
    required String value,
    required String tooltip,
    bool isSuccess = false,
  }) {
    final isDark = AppTheme.isDark(context);
    final bgColor = isSuccess
        ? (isDark ? const Color(0xFF052E16).withValues(alpha: 0.6) : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9));
    final borderColor = isSuccess
        ? (isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC))
        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));
    final textColor = isSuccess
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF334155));
    final iconColor = isSuccess
        ? (isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8));
    final badgeBg = isSuccess
        ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final badgeTextCol = isSuccess
        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isSuccess
                      ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                      : AppTheme.textPrimary(context),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
                border: isSuccess ? Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 9.5, color: iconColor),
                  const SizedBox(width: 3),
                  Text(
                    badgeText,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeTextCol),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: Tooltip(
            message: '$tooltip (Auto-calculated, read-only)',
            child: Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 1.2),
                borderRadius: BorderRadius.circular(8),
                color: bgColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: isSuccess ? FontWeight.w900 : FontWeight.bold,
                      fontSize: isSuccess ? 16 : 14,
                      color: textColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

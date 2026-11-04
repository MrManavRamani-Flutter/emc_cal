import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../providers/production_provider.dart';
import '../../widgets/app_snack_bar.dart';

class BackupRestoreScreen extends StatefulWidget {
  final bool isEmbedded;
  const BackupRestoreScreen({super.key, this.isEmbedded = false});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  String _lastBackupInfo = 'No backup created yet in this session';
  String _selectedRestoreFileName = 'No file selected';
  String? _selectedRestoreContent;
  Map<String, dynamic>? _restorePreviewData;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final provider = context.read<ProductionProvider>();
      final jsonString = await provider.exportBackupJson();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFilename = 'OM_MAVTAR_Backup_$timestamp.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      String? targetPath;
      bool userCanceled = false;

      try {
        final uri = await FilePicker.saveFile(
          fileName: defaultFilename,
          bytes: bytes,
          dialogTitle: 'Save Database Backup (OM MAVTAR GROUP)',
        );
        if (uri != null) {
          targetPath = uri.toFilePath();
          // Verify file was written
          final savedFile = File(targetPath);
          if (!await savedFile.exists() || await savedFile.length() == 0) {
            await savedFile.writeAsBytes(bytes);
          }
        } else {
          userCanceled = true;
        }
      } catch (pickerErr) {
        // Fallback to Documents/EmbroideryProductionCalculator/Backups/
        final appDocDir = await getApplicationDocumentsDirectory();
        final backupDir = Directory('${appDocDir.path}/EmbroideryProductionCalculator/Backups');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        targetPath = '${backupDir.path}/$defaultFilename';
        final file = File(targetPath);
        await file.writeAsBytes(bytes);
      }

      if (userCanceled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup cancelled: No destination selected.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final timeDisplay = DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now());
      setState(() {
        _lastBackupInfo = '$timeDisplay ($defaultFilename)\nSaved: $targetPath';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created successfully!\nFile: $defaultFilename'),
            backgroundColor: AppTheme.successGreenDark,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _chooseRestoreFile() async {
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Select Backup File (.json or .db)',
        type: FileType.custom,
        allowedExtensions: ['json', 'db', 'txt'],
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final content = utf8.decode(bytes);

        if (content.trim().isEmpty) {
          throw Exception('The selected file is empty.');
        }

        // Validate JSON
        final decoded = jsonDecode(content);
        if (decoded is! Map && decoded is! List) {
          throw Exception('Invalid backup format: root must be a JSON object or array.');
        }

        final Map<String, dynamic> previewData;
        if (decoded is List) {
          if (decoded.isNotEmpty &&
              decoded.first is Map &&
              ((decoded.first as Map).containsKey('challan_no') ||
                  (decoded.first as Map).containsKey('challanNo') ||
                  (decoded.first as Map).containsKey('item_type') ||
                  (decoded.first as Map).containsKey('itemType'))) {
            previewData = {'material_items': decoded};
          } else {
            previewData = {'production_records': decoded};
          }
        } else {
          previewData = Map<String, dynamic>.from(decoded as Map);
        }

        setState(() {
          _selectedRestoreFileName = picked.name;
          _selectedRestoreContent = content;
          _restorePreviewData = previewData;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup file "${picked.name}" loaded and verified.'),
              backgroundColor: AppTheme.successGreenDark,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _selectedRestoreFileName = 'Invalid file selected';
        _selectedRestoreContent = null;
        _restorePreviewData = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid backup file: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _restoreDatabase() async {
    if (_selectedRestoreContent == null || _restorePreviewData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid backup file first')),
      );
      return;
    }

    final data = _restorePreviewData!;
    final prodCount = (data['production_records'] as List?)?.length ??
        (data['records'] as List?)?.length ??
        (data['ProductionRecords'] as List?)?.length ??
        (data['productionRecords'] as List?)?.length ??
        0;
    final matCount = (data['material_items'] as List?)?.length ??
        (data['materials'] as List?)?.length ??
        (data['MaterialItems'] as List?)?.length ??
        (data['materialItems'] as List?)?.length ??
        0;
    final machineCount = (data['machines'] as List?)?.length ??
        (data['Machines'] as List?)?.length ??
        0;
    final accCount = (data['accounts'] as List?)?.length ??
        (data['Accounts'] as List?)?.length ??
        0;
    final exportedAt = data['exported_at'] as String? ??
        (data['backup_timestamp'] as String? ?? 'Previous version backup');

    final provider = context.read<ProductionProvider>();
    final bool isSystemEmpty = provider.allRecords.isEmpty &&
        provider.materials.isEmpty &&
        provider.employeeUpads.isEmpty;
    final lang = provider.settings.appLanguage;

    final restoreChoice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(lang, en: 'Choose Restore Method', gu: 'રીસ્ટોર પદ્ધતિ પસંદ કરો', hi: 'रीस्टोर विधि चुनें')),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t(
                  lang,
                  en: 'Backup Summary: $prodCount production records, $matCount materials, $machineCount machines, $accCount accounts ($exportedAt).',
                  gu: 'બેકઅપ સારાંશ: $prodCount પ્રોડક્શન રેકોર્ડ્સ, $matCount મટિરિયલ્સ ($exportedAt).',
                  hi: 'बैकअप सारांश: $prodCount उत्पादन रिकॉर्ड, $matCount सामग्री ($exportedAt)।',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Option A: Smart Merge or Direct Full Restore if empty
              InkWell(
                onTap: () => Navigator.pop(ctx, 'merge'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.merge_type_rounded, color: Color(0xFF10B981), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSystemEmpty
                                  ? AppStrings.t(
                                      lang,
                                      en: 'A) Direct Full Restore (Clean / Set All Data)',
                                      gu: 'A) ડાયરેક્ટ સંપૂર્ણ પુનઃસ્થાપિત (બધો ડેટા સેટ કરો)',
                                      hi: 'A) डायरेक्ट फुल रीस्टोर (पूरा डेटा सेट करें)',
                                    )
                                  : AppStrings.t(
                                      lang,
                                      en: 'A) Smart Merge (Safe / Preserves Current Data)',
                                      gu: 'A) સ્માર્ટ મર્જ (સુરક્ષિત / વર્તમાન ડેટા સચવાય)',
                                      hi: 'A) स्मार्ट मर्ज (सुरक्षित / वर्तमान डेटा सुरक्षित)',
                                    ),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isSystemEmpty
                                  ? AppStrings.t(
                                      lang,
                                      en: 'System is currently empty. Directly sets all $prodCount records, $matCount materials, machines, khatas & settings from backup.',
                                      gu: 'સિસ્ટમમાં હાલ કોઈ ડેટા નથી. બેકઅપમાંથી તમામ $prodCount રેકોર્ડ્સ, $matCount મટિરિયલ્સ, ખાતાઓ અને મશીનો સીધા જ સેટ થશે.',
                                      hi: 'सिस्टम में अभी कोई डेटा नहीं है। बैकअप से सभी $prodCount रिकॉर्ड्स, $matCount सामग्री, खाते और मशीनें सीधे सेट हो जाएंगी।',
                                    )
                                  : AppStrings.t(
                                      lang,
                                      en: 'Adds new records from backup and updates matching ones. All current records are 100% preserved without deletion or overwrite.',
                                      gu: 'બેકઅપમાંથી નવા રેકોર્ડ્સ ઉમેરે છે અને મેચ થતાં રેકોર્ડ્સ અપડેટ કરે છે. વર્તમાન ડેટા ડિલીટ કે ઓવરરાઈટ થયા વગર ૧૦૦% સુરક્ષિત રહે છે.',
                                      hi: 'बैकअप से नए रिकॉर्ड जोड़ता है और मेल खाने वाले अपडेट करता है। वर्तमान डेटा बिना हटे या ओवरराइट हुए 100% सुरक्षित रहता है।',
                                    ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option B: Full Overwrite
              InkWell(
                onTap: () => Navigator.pop(ctx, 'overwrite'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.t(lang, en: 'B) Full Overwrite (Replace All)', gu: 'B) ફુલ ઓવરરાઇટ (બધું બદલો)', hi: 'B) फुल ओवरराइट (सभी बदलें)'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRed, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AppStrings.t(
                                lang,
                                en: 'Replaces current records with backup. Auto-saves safety backup (AutoBackup_BeforeRestore) first.',
                                gu: 'વર્તમાન રેકોર્ડ્સને બદલે છે. પહેલા આપોઆપ AutoBackup_BeforeRestore સેફટી બેકઅપ સાચવે છે.',
                                hi: 'वर्तमान रिकॉर्ड्स को बदलता है। पहले स्वतः AutoBackup_BeforeRestore सुरक्षा बैकअप सहेजता है।',
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
          ),
        ],
      ),
    );

    if (restoreChoice != null && mounted) {
      final bool isMerge = restoreChoice == 'merge';
      setState(() => _isRestoring = true);
      try {
        final provider = context.read<ProductionProvider>();

        // If Overwrite, automatic safety backup of current data before overwriting
        if (!isMerge) {
          try {
            final safetyJson = await provider.exportBackupJson();
            final appDocDir = await getApplicationDocumentsDirectory();
            final safetyDir = Directory('${appDocDir.path}/EmbroideryProductionCalculator/AutoSafetyBackups');
            if (!await safetyDir.exists()) {
              await safetyDir.create(recursive: true);
            }
            final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
            final safetyFile = File('${safetyDir.path}/AutoBackup_BeforeRestore_$timestamp.json');
            await safetyFile.writeAsString(safetyJson);
          } catch (_) {}
        }

        await provider.restoreFromJson(_selectedRestoreContent!, merge: isMerge);
        if (mounted) {
          AppSnackBar.showSuccess(
            context,
            title: AppStrings.t(lang, en: 'Restore Successful', gu: 'રીસ્ટોર સફળ', hi: 'पुनर्स्थापना सफल'),
            message: AppStrings.t(
              lang,
              en: isSystemEmpty
                  ? '$prodCount records, $matCount materials directly restored & set successfully!'
                  : (isMerge
                      ? '$prodCount records, $matCount materials merged successfully!'
                      : '$prodCount records, $matCount materials loaded.\n(AutoBackup_BeforeRestore saved safely)'),
              gu: isSystemEmpty
                  ? '$prodCount રેકોર્ડ્સ, $matCount મટિરિયલ્સ સીધા જ સફળતાપૂર્વક સેટ થયા!'
                  : (isMerge
                      ? '$prodCount રેકોર્ડ્સ, $matCount મટિરિયલ્સ સફળતાપૂર્વક મર્જ થયા!'
                      : '$prodCount રેકોર્ડ્સ, $matCount મટિરિયલ્સ લોડ થયા.\n(AutoBackup_BeforeRestore સુરક્ષિત સેવ થયો છે)'),
              hi: isSystemEmpty
                  ? '$prodCount रिकॉर्ड्स, $matCount सामग्री सीधे सफलतापूर्वक सेट हो गई!'
                  : (isMerge
                      ? '$prodCount रिकॉर्ड्स, $matCount सामग्री सफलतापूर्वक मर्ज की गई!'
                      : '$prodCount रिकॉर्ड्स, $matCount सामग्री लोड हुई।\n(AutoBackup_BeforeRestore सुरक्षित सहेजा गया)'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            title: AppStrings.t(lang, en: 'Restore Failed', gu: 'રીસ્ટોર નિષ્ફળ', hi: 'पुनर्स्थापना विफल'),
            message: '${AppStrings.t(lang, en: 'Error while restoring database:', gu: 'ડેટાબેઝ રીસ્ટોર કરતી વખતે ભૂલ આવી:', hi: 'डेटाबेस पुनर्स्थापित करते समय त्रुटि आई:')} $e',
          );
        }
      } finally {
        if (mounted) setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _confirmPurgeDummyData(ProductionProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Dummy / Demo Data?'),
        content: const Text(
          'This will remove all demo/dummy production records and demo material bills from the database.\n\nYour actual machines, accounts, master products, and real entries will remain completely intact.\n\nAre you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear Dummy Data Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await provider.clearAllDummyData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All dummy records removed successfully! Database is now clean.'),
            backgroundColor: AppTheme.successGreenDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final isDark = provider.settings.isDarkMode;
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);
    final lang = provider.settings.appLanguage;

    final borderColor = isDark ? const Color(0xFF334155) : AppTheme.slateBorder;
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : AppTheme.darkNavy;
    final labelTextColor = isDark ? const Color(0xFFE2E8F0) : AppTheme.textSecondary(context);

    String formatStatLabel(String en, String gu, String hi) {
      return AppStrings.t(lang, en: en, gu: gu, hi: hi);
    }

    final leftPanel = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get('dbBackupRestore', lang),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.get('offlineDataProtection', lang),
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _confirmPurgeDummyData(provider),
                    icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: AppTheme.dangerRed),
                    label: Text(AppStrings.get('cleanDummyData', lang)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerRed,
                      side: const BorderSide(color: AppTheme.dangerRed),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Create Backup Section
          Text(
            AppStrings.get('createBackupStep', lang),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            lang == 'gu'
                ? 'બધા પ્રોડક્શન રેકોર્ડ્સ, મટિરિયલ્સ, મશીનો, ખાતાઓ, માસ્ટર કેટલોગ અને કચરાના રેકોર્ડ્સ સુરક્ષિત JSON ફાઈલમાં નિકાસ કરો.'
                : (lang == 'hi'
                    ? 'सभी उत्पादन रिकॉर्ड्स, सामग्री, मशीनें, खाते, मास्टर कैटलॉग और रीसायकल बिन आइटम्स सुरक्षित JSON फाइल में निर्यात करें।'
                    : 'Exports all Production Records, Materials, Machines, Khatas, Master Catalog, and Recycle Bin items into a secure JSON backup file.'),
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isBackingUp ? null : _createBackup,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 16),
                label: Text(_isBackingUp
                    ? (lang == 'gu' ? 'બેકઅપ બને છે...' : (lang == 'hi' ? 'बैकअप बन रहा है...' : 'Creating Backup...'))
                    : AppStrings.get('createBackup', lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  '${lang == "gu" ? "છેલ્લો બેકઅપ" : (lang == "hi" ? "अंतिम बैकअप" : "Last Backup")}:\n$_lastBackupInfo',
                  style: TextStyle(fontSize: 11, color: labelTextColor, height: 1.3),
                ),
              ),
            ],
          ),
          Divider(height: 36, color: borderColor),

          // 2. Restore Database Section
          Text(
            AppStrings.get('restoreDatabaseStep', lang),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            lang == 'gu'
                ? 'બધા રેકોર્ડ્સ પુનઃસ્થાપિત કરવા માટે અસ્તિત્વમાં રહેલી બેકઅપ ફાઈલ (.json અથવા .db) પસંદ કરો.'
                : (lang == 'hi'
                    ? 'सभी रिकॉर्ड्स पुनर्स्थापित करने के लिए मौजूदा बैकअप फाइल (.json या .db) चुनें।'
                    : 'Select an existing OM MAVTAR GROUP backup file (.json or .db) to restore all records.'),
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _chooseRestoreFile,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text(AppStrings.get('chooseFile', lang)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              Text(
                _selectedRestoreFileName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _selectedRestoreContent != null ? FontWeight.bold : FontWeight.normal,
                  color: _selectedRestoreContent != null ? AppTheme.successGreenDark : labelTextColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // Preview Info Card if a valid backup is selected
          if (_restorePreviewData != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successGreenDark.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successGreenDark.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.successGreenDark, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        lang == 'gu' ? 'માન્ય બેકઅપ ફાઈલ પ્રમાણિત:' : (lang == 'hi' ? 'वैध बैकअप फाइल सत्यापित:' : 'Valid Backup File Verified:'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.darkNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        '• ${formatStatLabel("Production", "પ્રોડક્શન", "उत्पादन")}: ${(_restorePreviewData!['production_records'] as List?)?.length ?? (_restorePreviewData!['records'] as List?)?.length ?? (_restorePreviewData!['ProductionRecords'] as List?)?.length ?? 0}',
                        style: TextStyle(fontSize: 11, color: labelTextColor),
                      ),
                      Text(
                        '• ${formatStatLabel("Materials", "મટિરિયલ્સ", "सामग्री")}: ${(_restorePreviewData!['material_items'] as List?)?.length ?? (_restorePreviewData!['materials'] as List?)?.length ?? (_restorePreviewData!['MaterialItems'] as List?)?.length ?? 0}',
                        style: TextStyle(fontSize: 11, color: labelTextColor),
                      ),
                      Text(
                        '• ${formatStatLabel("Machines", "મશીનો", "मशीनें")}: ${(_restorePreviewData!['machines'] as List?)?.length ?? (_restorePreviewData!['Machines'] as List?)?.length ?? 0}',
                        style: TextStyle(fontSize: 11, color: labelTextColor),
                      ),
                      Text(
                        '• ${formatStatLabel("Accounts", "ખાતાઓ", "खाते")}: ${(_restorePreviewData!['accounts'] as List?)?.length ?? (_restorePreviewData!['Accounts'] as List?)?.length ?? 0}',
                        style: TextStyle(fontSize: 11, color: labelTextColor),
                      ),
                      Text(
                        '• Exported: ${_restorePreviewData!['exported_at'] ?? _restorePreviewData!['backup_timestamp'] ?? "Backup File"}',
                        style: TextStyle(fontSize: 11, color: labelTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: (_selectedRestoreContent == null || _isRestoring) ? null : _restoreDatabase,
            icon: _isRestoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.restore_page_rounded, size: 16),
            label: Text(_isRestoring
                ? (lang == 'gu' ? 'ડેટાબેઝ પુનઃસ્થાપિત થાય છે...' : (lang == 'hi' ? 'डेटाबेस पुनर्स्थापित हो रहा है...' : 'Restoring Database...'))
                : AppStrings.get('restoreDatabase', lang)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 24),

          // Footnote
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppStrings.get('tipBackupNotice', lang),
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final rightPanel = Column(
      children: [
        // Live DB Stats
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get('liveDbStatus', lang),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
              const SizedBox(height: 14),
              _dbStatRow(formatStatLabel('Production Records', 'પ્રોડક્શન રેકોર્ડ્સ', 'उत्पादन रिकॉर्ड्स'), '${provider.allRecords.length}', Icons.precision_manufacturing_rounded, context),
              _dbStatRow(formatStatLabel('Material Items', 'મટિરિયલ આઈટમ્સ', 'सामग्री आइटम्स'), '${provider.materials.length}', Icons.receipt_long_rounded, context),
              _dbStatRow(formatStatLabel('Machines', 'મશીનો', 'मशीनें'), '${provider.machines.length}', Icons.settings_suggest_rounded, context),
              _dbStatRow(formatStatLabel('Accounts', 'ખાતાઓ', 'खाते'), '${provider.accounts.length}', Icons.account_balance_wallet_rounded, context),
              _dbStatRow(formatStatLabel('Master Products', 'પ્રોડક્ટ્સ', 'उत्पाद'), '${provider.materialProducts.length}', Icons.category_rounded, context),
              _dbStatRow(formatStatLabel('Suppliers', 'વેપારીઓ', 'व्यापारी'), '${provider.suppliers.length}', Icons.store_rounded, context),
              _dbStatRow(formatStatLabel('Employees', 'કર્મચારીઓ', 'कर्मचारी'), '${provider.employees.length}', Icons.badge_rounded, context),
              _dbStatRow(formatStatLabel('Salary Advances', 'કર્મચારી ઉપાડ', 'कर्मचारी अग्रिम'), '${provider.employeeUpads.length}', Icons.payments_rounded, context),
              _dbStatRow(formatStatLabel('Recycle Bin', 'રીસાયકલ બિન', 'रीसायकल बिन'), '${provider.deletedRecords.length}', Icons.auto_delete_rounded, context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Application Info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                'OM MAVTAR GROUP',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text('Embroidery Production Calculator', style: TextStyle(fontSize: 11, color: labelTextColor)),
              const SizedBox(height: 4),
              Text('100% Offline SQLite Architecture', style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 950;

        Widget content;
        if (isNarrow) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftPanel,
              const SizedBox(height: 20),
              rightPanel,
            ],
          );
        } else {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: leftPanel),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: rightPanel),
            ],
          );
        }

        if (widget.isEmbedded) {
          return SingleChildScrollView(child: content);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: content,
        );
      },
    );
  }

  Widget _dbStatRow(String label, String value, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
          ),
        ],
      ),
    );
  }
}

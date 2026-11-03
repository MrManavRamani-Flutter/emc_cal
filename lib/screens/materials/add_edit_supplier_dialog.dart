import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../models/supplier.dart';
import '../../providers/production_provider.dart';
import '../../widgets/app_svg_icon.dart';

class AddEditSupplierDialog extends StatefulWidget {
  final Supplier? initialSupplier;
  final bool asScreen;
  final VoidCallback? onBack;
  final ValueChanged<Supplier>? onSaved;

  const AddEditSupplierDialog({
    super.key,
    this.initialSupplier,
    this.asScreen = false,
    this.onBack,
    this.onSaved,
  });

  @override
  State<AddEditSupplierDialog> createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSupplier;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductionProvider>();

    final supplier = Supplier(
      id: widget.initialSupplier?.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      city: widget.initialSupplier?.city ?? '',
      gstNo: widget.initialSupplier?.gstNo ?? '',
      notes: widget.initialSupplier?.notes ?? '',
      isActive: _isActive,
      createdAt: widget.initialSupplier?.createdAt ?? DateTime.now(),
    );

    if (widget.initialSupplier == null) {
      await provider.insertSupplier(supplier);
    } else {
      await provider.updateSupplier(supplier);
    }

    if (mounted) {
      if (widget.onSaved != null) {
        widget.onSaved!(supplier);
      } else if (widget.onBack != null) {
        widget.onBack!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(supplier);
      }
      final lang = provider.settings.appLanguage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialSupplier == null
                ? AppStrings.t(lang,
                    en: 'Supplier added successfully!',
                    gu: 'સપ્લાયર સફળતાપૂર્વક ઉમેરાઈ ગયો!',
                    hi: 'आपूर्तिकर्ता सफलतापूर्वक जोड़ा गया!')
                : AppStrings.t(lang,
                    en: 'Supplier updated successfully!',
                    gu: 'સપ્લાયર અપડેટ થઈ ગયો!',
                    hi: 'आपूर्तिकर्ता अपडेट हो गया!'),
          ),
          backgroundColor: AppTheme.successGreenDark,
        ),
      );
    }
  }

  void _handleCancel() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isEditing = widget.initialSupplier != null;
    final hintColor = AppTheme.hintColor(context);
    final lang = context.watch<ProductionProvider>().settings.appLanguage;

    if (widget.asScreen) {
      return Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                children: [
                  Tooltip(
                    message: AppStrings.get('back', lang),
                    child: InkWell(
                      onTap: _handleCancel,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: AppSvgIcon.back(size: 20, color: AppTheme.textPrimary(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: isDark ? 0.3 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 24, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isEditing
                                    ? AppStrings.t(lang, en: 'Edit Supplier', gu: 'સપ્લાયર વિગત એડિટ કરો', hi: 'आपूर्तिकर्ता संपादित करें')
                                    : AppStrings.t(lang, en: 'New Supplier Master', gu: 'નવો સપ્લાયર માસ્ટર', hi: 'नया आपूर्तिकर्ता मास्टर'),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary(context),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (isEditing && widget.initialSupplier?.id != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  '#ID: ${widget.initialSupplier!.id}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.t(lang,
                              en: 'Party / Trader directory master for instant 1-click selection during Material entry',
                              gu: 'મટિરિયલ એન્ટ્રીમાં ત્વરિત પસંદગી માટે પાર્ટી / વેપારી ડિરેક્ટરી માસ્ટર',
                              hi: 'सामग्री प्रविष्टि के दौरान त्वरित चयन के लिए पार्टी / व्यापारी निर्देशिका मास्टर'),
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textMuted(context),
                      side: BorderSide(color: AppTheme.border(context)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(isEditing
                        ? AppStrings.t(lang, en: 'Update Supplier', gu: 'સપ્લાયર અપડેટ કરો', hi: 'आपूर्तिकर्ता अपडेट करें')
                        : AppStrings.t(lang, en: 'Save Supplier', gu: 'સપ્લાયર સાચવો', hi: 'आपूर्तिकर्ता सहेजें')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Form Container Card
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: _buildFormBody(context, hintColor, isEditing, lang),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.cardBg(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront_rounded, size: 24, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? AppStrings.t(lang, en: 'Edit Supplier', gu: 'સપ્લાયર એડિટ કરો', hi: 'आपूर्तिकर्ता संपादित करें')
                                  : AppStrings.t(lang, en: 'New Supplier Master', gu: 'નવો સપ્લાયર ઉમેરો', hi: 'नया आपूर्तिकर्ता जोड़ें'),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                            Text(
                              AppStrings.t(lang,
                                  en: 'Enter party / supplier details to reuse in material entries',
                                  gu: 'મટિરિયલ એન્ટ્રીઓમાં વાપરવા માટે પાર્ટી / સપ્લાયર વિગતો દાખલ કરો',
                                  hi: 'सामग्री प्रविष्टियों में उपयोग के लिए पार्टी / आपूर्तिकर्ता विवरण दर्ज करें'),
                              style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: _handleCancel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),

                  _buildFormBody(context, hintColor, isEditing, lang),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormBody(BuildContext context, Color hintColor, bool isEditing, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Supplier Name
        Text(
          '${AppStrings.t(lang, en: 'Supplier / Party Name', gu: 'સપ્લાયર / પાર્ટી નું નામ', hi: 'आपूर्तिकर्ता / पार्टी का नाम')} *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameCtrl,
          autofocus: true,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return AppStrings.t(lang,
                  en: 'Supplier name required',
                  gu: 'સપ્લાયર નું નામ જરૂરી છે',
                  hi: 'आपूर्तिकर्ता का नाम आवश्यक है');
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'e.g. Jay Ambe Thread, Radha Raman, SN TEX',
            hintStyle: TextStyle(color: hintColor, fontSize: 12.5, fontWeight: FontWeight.normal),
            prefixIcon: const Icon(Icons.business_rounded, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),

        // Phone
        Text(
          AppStrings.t(lang, en: 'Mobile / Phone', gu: 'મોબાઇલ / ફોન', hi: 'मोबाइल / फ़ोन'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phoneCtrl,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'e.g. 9825100000',
            hintStyle: TextStyle(color: hintColor, fontSize: 12.5, fontWeight: FontWeight.normal),
            prefixIcon: const Icon(Icons.phone_outlined, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),

        // Active status toggle (if editing)
        if (isEditing)
          Row(
            children: [
              Switch(
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                activeThumbColor: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                _isActive
                    ? AppStrings.t(lang, en: 'Active Supplier', gu: 'સક્રિય સપ્લાયર', hi: 'सक्रिय आपूर्तिकर्ता')
                    : AppStrings.t(lang, en: 'Inactive / Archived', gu: 'નિષ્ક્રિય / આર્કાઇવ', hi: 'निष्क्रिय / संग्रहीत'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isActive ? AppTheme.successGreenDark : AppTheme.textMuted(context),
                ),
              ),
            ],
          ),

        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _handleCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                side: BorderSide(color: AppTheme.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें'),
                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(
                isEditing
                    ? AppStrings.t(lang, en: 'Update Supplier', gu: 'સપ્લાયર અપડેટ કરો', hi: 'आपूर्तिकर्ता अपडेट करें')
                    : AppStrings.t(lang, en: 'Save Supplier', gu: 'સપ્લાયર સાચવો', hi: 'आपूर्तिकर्ता सहेजें'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

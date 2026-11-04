import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../core/whatsapp_service.dart';
import '../../models/whatsapp_log_model.dart';
import '../../providers/production_provider.dart';

/// Dialog to view, search, inspect, and resend historical WhatsApp messages
/// sent to employees (Upad receipts, Khata statements, etc.).
class WhatsAppHistoryDialog extends StatefulWidget {
  final int? initialEmployeeId;

  const WhatsAppHistoryDialog({
    super.key,
    this.initialEmployeeId,
  });

  @override
  State<WhatsAppHistoryDialog> createState() => _WhatsAppHistoryDialogState();
}

class _WhatsAppHistoryDialogState extends State<WhatsAppHistoryDialog> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedEmployeeId;
  String _selectedType = 'All'; // 'All', 'upad_receipt', 'statement'

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.initialEmployeeId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final theme = Theme.of(context);
    final isDark = AppTheme.isDark(context);
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');
    final lang = provider.settings.appLanguage;

    // Filter logs in memory
    final searchQuery = _searchController.text.trim().toLowerCase();
    final allLogs = provider.whatsappLogs;

    final filteredLogs = allLogs.where((log) {
      if (_selectedEmployeeId != null && log.employeeId != _selectedEmployeeId) {
        return false;
      }
      if (_selectedType != 'All' && log.messageType != _selectedType) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final empMatch = log.employeeName.toLowerCase().contains(searchQuery);
        final recPhoneMatch = log.recipientPhone.contains(searchQuery);
        final sendPhoneMatch = log.senderPhone.contains(searchQuery);
        final msgMatch = log.message.toLowerCase().contains(searchQuery);
        if (!empMatch && !recPhoneMatch && !sendPhoneMatch && !msgMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    // Summary KPIs
    final totalCount = filteredLogs.length;
    final totalUpad = filteredLogs.fold<double>(0.0, (sum, l) => sum + (l.amount));
    final distinctEmployees = filteredLogs.map((l) => l.employeeName).toSet().length;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 760,
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context, theme, allLogs.length, isDark, lang),

            // Top Stat Cards
            _buildSummaryRow(totalCount, totalUpad, distinctEmployees, currencyFmt, isDark, lang),

            // Filter Bar
            _buildFilterBar(provider, isDark, lang),

            Divider(height: 1, thickness: 1, color: borderColor),

            // Content List
            Expanded(
              child: filteredLogs.isEmpty
                  ? _buildEmptyState(isDark, lang)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: filteredLogs.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final log = filteredLogs[index];
                        return _buildLogCard(log, provider, currencyFmt, isDark, lang);
                      },
                    ),
            ),

            Divider(height: 1, thickness: 1, color: borderColor),

            // Footer
            _buildFooter(context, provider, allLogs.length, isDark, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, int totalCount, bool isDark, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFF25D366).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppStrings.t(lang,
                          en: 'Sent WhatsApp Message Records',
                          gu: 'મોકલેલા WhatsApp મેસેજ રેકોર્ડ',
                          hi: 'भेजे गए WhatsApp संदेश रिकॉर्ड'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF059669).withValues(alpha: 0.3)
                            : const Color(0xFF25D366).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalCount ${AppStrings.t(lang, en: 'Messages', gu: 'મેસેજ', hi: 'संदेश')}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.t(lang,
                      en: 'Full audit record of sent WhatsApp messages to employees',
                      gu: 'કર્મચારીને ક્યારે, ક્યા નંબરેથી અને શું મેસેજ મોકલ્યો તેનો સંપૂર્ણ ઓડિટ રેકોર્ડ',
                      hi: 'कर्मचारियों को भेजे गए WhatsApp संदेशों का पूर्ण ऑडिट रिकॉर्ड'),
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: isDark ? AppTheme.darkTextMuted : Colors.grey),
            tooltip: AppStrings.t(lang, en: 'Close', gu: 'બંધ કરો', hi: 'बंद करें'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    int totalCount,
    double totalUpad,
    int distinctEmployees,
    NumberFormat currencyFmt,
    bool isDark,
    String lang,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: AppStrings.t(lang,
                  en: 'Total Messages Sent',
                  gu: 'કુલ મોકલેલા મેસેજ',
                  hi: 'कुल भेजे गए संदेश'),
              value: '$totalCount',
              icon: Icons.mark_email_read_rounded,
              color: const Color(0xFF2563EB),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricTile(
              label: AppStrings.t(lang,
                  en: 'Total Advance',
                  gu: 'કુલ ઉપાડ રકમ',
                  hi: 'कुल अग्रिम राशि'),
              value: '₹${currencyFmt.format(totalUpad)}',
              icon: Icons.currency_rupee_rounded,
              color: const Color(0xFF16A34A),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricTile(
              label: AppStrings.t(lang,
                  en: 'Total Employees',
                  gu: 'કુલ કર્મચારીઓ',
                  hi: 'कुल कर्मचारी'),
              value: '$distinctEmployees ${AppStrings.t(lang, en: 'Persons', gu: 'વ્યક્તિ', hi: 'व्यक्ति')}',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF7C3AED),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: isDark ? 0.25 : 0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ProductionProvider provider, bool isDark, String lang) {
    final surfaceSubtle = isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search box
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13, color: textPrimary),
              decoration: InputDecoration(
                hintText: AppStrings.t(lang,
                    en: 'Search (name, number, message)...',
                    gu: 'શોધો (નામ, નંબર, મેસેજ)...',
                    hi: 'खोजें (नाम, नंबर, संदेश)...'),
                hintStyle: TextStyle(fontSize: 13, color: textMuted),
                prefixIcon: Icon(Icons.search, size: 20, color: textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18, color: textMuted),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: surfaceSubtle,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Employee Dropdown Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: surfaceSubtle,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                dropdownColor: isDark ? AppTheme.darkCardBg : Colors.white,
                value: _selectedEmployeeId,
                hint: Text(
                  AppStrings.t(lang, en: 'All Employees', gu: 'તમામ કર્મચારીઓ', hi: 'सभी कर्मचारी'),
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      AppStrings.t(lang, en: 'All Employees', gu: 'તમામ કર્મચારીઓ', hi: 'सभी कर्मचारी'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  ),
                  ...provider.employees.map((emp) => DropdownMenuItem<int?>(
                        value: emp.id,
                        child: Text('${emp.name} (${emp.role.trim().toUpperCase()})', style: TextStyle(fontSize: 13, color: textPrimary)),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedEmployeeId = val;
                  });
                },
              ),
            ),
          ),

          // Message Type Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: surfaceSubtle,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: isDark ? AppTheme.darkCardBg : Colors.white,
                value: _selectedType,
                items: [
                  DropdownMenuItem(
                    value: 'All',
                    child: Text(
                      AppStrings.t(lang, en: 'All Messages', gu: 'બધા મેસેજ', hi: 'सभी संदेश'),
                      style: TextStyle(fontSize: 13, color: textPrimary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'upad_receipt',
                    child: Text(
                      AppStrings.t(lang, en: 'Advance Receipts', gu: 'ઉપાડ રસીદ', hi: 'अग्रिम (उपाड) रसीदें'),
                      style: TextStyle(fontSize: 13, color: textPrimary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'statement',
                    child: Text(
                      AppStrings.t(lang, en: 'Khata Statements', gu: 'ખાતાવહી સ્ટેટમેન્ટ', hi: 'खाताबही विवरण'),
                      style: TextStyle(fontSize: 13, color: textPrimary),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFF25D366)),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.t(lang,
                  en: 'No WhatsApp messages sent yet',
                  gu: 'હજુ સુધી કોઈ WhatsApp મેસેજ મોકલેલા નથી',
                  hi: 'अभी तक कोई WhatsApp संदेश नहीं भेजा गया'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.t(lang,
                  en: 'When you send an advance receipt or khata statement to an employee,\ncomplete details will be saved here.',
                  gu: 'જ્યારે તમે કર્મચારીને ઉપાડ રસીદ અથવા ખાતાવહી સ્ટેટમેન્ટ મોકલશો,\nત્યારે તેની સંપૂર્ણ વિગતો અહીં સેવ થશે.',
                  hi: 'जब आप कर्मचारी को अग्रिम रसीद या खाताबही विवरण भेजेंगे,\nतब उसका पूरा विवरण यहाँ सुरक्षित होगा।'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(
    WhatsAppLogModel log,
    ProductionProvider provider,
    NumberFormat currencyFmt,
    bool isDark,
    String lang,
  ) {
    final isUpad = log.messageType == 'upad_receipt';
    final dateStr = DateFormat('dd/MM/yyyy • hh:mm a').format(log.createdAt);
    final cardBg = isDark ? AppTheme.darkSurfaceSubtle : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569);
    final textMuted = isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B);
    final innerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final innerBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Employee Name + Badges + Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isUpad
                    ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                    : const Color(0xFF7C3AED).withValues(alpha: 0.15),
                child: Icon(
                  isUpad ? Icons.receipt_long_rounded : Icons.account_balance_wallet_rounded,
                  size: 20,
                  color: isUpad ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          log.employeeName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUpad
                                ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFF2563EB).withValues(alpha: 0.1))
                                : (isDark ? const Color(0xFF4C1D95).withValues(alpha: 0.4) : const Color(0xFF7C3AED).withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isUpad
                                ? AppStrings.t(lang, en: 'Advance Receipt', gu: 'ઉપાડ રસીદ', hi: 'अग्रिम रसीद')
                                : AppStrings.t(lang, en: 'Khata Statement', gu: 'ખાતાવહી સ્ટેટમેન્ટ', hi: 'खाताबही विवरण'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isUpad ? const Color(0xFF60A5FA) : const Color(0xFFA78BFA),
                            ),
                          ),
                        ),
                        if (log.amount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${currencyFmt.format(log.amount)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),

              // Action buttons (View Full, Resend, Delete)
              Wrap(
                spacing: 6,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(Icons.remove_red_eye_outlined, size: 16, color: textSecondary),
                    label: Text(
                      AppStrings.t(lang, en: 'View Message', gu: 'સંપૂર્ણ મેસેજ', hi: 'पूरा संदेश'),
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    onPressed: () => _viewFullMessage(log, isDark, lang),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF25D366)),
                    tooltip: AppStrings.t(lang, en: 'Resend via WhatsApp', gu: 'WhatsApp પર ફરી મોકલો', hi: 'WhatsApp पर पुनः भेजें'),
                    onPressed: () => _resendWhatsApp(log, lang),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: AppStrings.t(lang, en: 'Delete Record', gu: 'રેકોર્ડ ડિલીટ કરો', hi: 'रिकॉर्ड हटाएं'),
                    onPressed: () => _confirmDeleteLog(log, provider, isDark, lang),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Phone numbers (Recipient & Sender)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: innerBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.phone_android, size: 15, color: textMuted),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.t(lang, en: 'Recipient: ', gu: 'મેળવનાર: ', hi: 'प्राप्तकर्ता: '),
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      Text(
                        log.recipientPhone,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.business_center, size: 15, color: textMuted),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.t(lang, en: 'Sender: ', gu: 'મોકલનાર: ', hi: 'प्रेषक: '),
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      Text(
                        log.senderPhone.isNotEmpty
                            ? log.senderPhone
                            : AppStrings.t(lang, en: '(Office)', gu: '(ઓફિસ)', hi: '(कार्यालय)'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Row 3: Message preview snippet
          InkWell(
            onTap: () => _viewFullMessage(log, isDark, lang),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
              ),
              child: Text(
                log.message.replaceAll('\n\n', '\n'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF334155),
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewFullMessage(WhatsAppLogModel log, bool isDark, String lang) {
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppTheme.darkTextMuted : Colors.grey;
    final surface = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log.employeeName} - ${AppStrings.t(lang, en: 'Sent Message', gu: 'મોકલેલ મેસેજ', hi: 'भेजा गया संदेश')}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    Text(
                      '${AppStrings.t(lang, en: 'Recipient', gu: 'મેળવનાર', hi: 'प्राप्तकर्ता')}: ${log.recipientPhone} | ${AppStrings.t(lang, en: 'Sender', gu: 'મોકલનાર', hi: 'प्रेषक')}: ${log.senderPhone}',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            width: 580,
            constraints: const BoxConstraints(maxHeight: 460),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                log.message,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B),
                  height: 1.45,
                ),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: Text(AppStrings.t(lang, en: 'Copy Message', gu: 'મેસેજ કોપી કરો', hi: 'संदेश कॉपी करें')),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: log.message));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.t(lang,
                        en: 'Message copied to clipboard',
                        gu: 'મેસેજ ક્લિપબોર્ડ પર કોપી થઈ ગયો છે',
                        hi: 'संदेश क्लिपबोर्ड पर कॉपी हो गया है')),
                    backgroundColor: const Color(0xFF16A34A),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(AppStrings.t(lang, en: 'Resend via WhatsApp', gu: 'WhatsApp પર ફરી મોકલો', hi: 'WhatsApp पर पुनः भेजें')),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              onPressed: () {
                Navigator.of(ctx).pop();
                _resendWhatsApp(log, lang);
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.t(lang, en: 'Close', gu: 'બંધ કરો', hi: 'बंद करें'),
                style: TextStyle(color: textMuted),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resendWhatsApp(WhatsAppLogModel log, String lang) async {
    final launched = await WhatsAppService.launchWhatsAppUrl(
      recipientPhone: log.recipientPhone,
      message: log.message,
    );
    if (mounted && !launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t(lang,
              en: 'Could not open WhatsApp',
              gu: 'WhatsApp ખોલી શકાયું નથી',
              hi: 'WhatsApp नहीं खोला जा सका')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  void _confirmDeleteLog(WhatsAppLogModel log, ProductionProvider provider, bool isDark, String lang) {
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.t(lang, en: 'Delete Message Record?', gu: 'મેસેજ રેકોર્ડ ડિલીટ કરવો છે?', hi: 'संदेश रिकॉर्ड हटाएं?'),
          style: TextStyle(color: textPrimary),
        ),
        content: Text(
          AppStrings.t(lang,
              en: 'Are you sure you want to delete this message record for "${log.employeeName}"?',
              gu: 'શું તમે ખરેખર "${log.employeeName}" નો આ મેસેજ રેકોર્ડ ડિલીટ કરવા માંગો છો?',
              hi: 'क्या आप वाकई "${log.employeeName}" का यह संदेश रिकॉर्ड हटाना चाहते हैं?'),
          style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें'),
              style: TextStyle(color: textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (log.id != null) {
                await provider.deleteWhatsAppLog(log.id!);
              }
            },
            child: Text(AppStrings.t(lang, en: 'Delete', gu: 'ડિલીટ કરો', hi: 'हटाएं')),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ProductionProvider provider, int totalCount, bool isDark, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (totalCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 18),
              label: Text(
                AppStrings.t(lang, en: 'Clear All Records', gu: 'બધા રેકોર્ડ સાફ કરો', hi: 'सभी रिकॉर्ड साफ करें'),
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              onPressed: () => _confirmClearAll(context, provider, isDark, lang),
            )
          else
            const SizedBox.shrink(),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.t(lang, en: 'Close', gu: 'બંધ કરો', hi: 'बंद करें')),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, ProductionProvider provider, bool isDark, String lang) {
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.t(lang, en: 'Clear All Message Records?', gu: 'બધા મેસેજ રેકોર્ડ સાફ કરવા છે?', hi: 'सभी संदेश रिकॉर्ड साफ करें?'),
          style: TextStyle(color: textPrimary),
        ),
        content: Text(
          AppStrings.t(lang,
              en: 'This action will permanently delete all sent WhatsApp message history. Do you wish to continue?',
              gu: 'આ ક્રિયાથી તમામ મોકલેલા WhatsApp મેસેજનો હિસ્ટ્રી કાયમ માટે ડિલીટ થઈ જશે. શું તમે આગળ વધવા માંગો છો?',
              hi: 'यह कार्रवाई भेजे गए सभी WhatsApp संदेशों का इतिहास स्थायी रूप से हटा देगी। क्या आप आगे बढ़ना चाहते हैं?'),
          style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें'),
              style: TextStyle(color: textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.clearAllWhatsAppLogs();
            },
            child: Text(AppStrings.t(lang, en: 'Yes, Clear All', gu: 'હા, બધા સાફ કરો', hi: 'हाँ, सभी साफ करें')),
          ),
        ],
      ),
    );
  }
}

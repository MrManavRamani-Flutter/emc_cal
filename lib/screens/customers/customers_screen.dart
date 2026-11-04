import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../core/utils/safe_range_utils.dart';
import '../../models/customer_model.dart';
import '../../models/customer_bill_model.dart';
import '../../models/customer_payment_model.dart';
import '../../providers/production_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Bills tab filter
  String _billStatusFilter = 'ALL'; // 'ALL', 'Unpaid', 'Partial', 'Paid'

  // Table sorting
  String _sortColumn = 'date';
  bool _sortAscending = false;

  // Pagination for bills
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCustomerDialog([CustomerModel? existing]) {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = existing != null;

    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    final gstinController = TextEditingController(text: existing?.gstin ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                color: const Color(0xFF6366F1),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit
                  ? AppStrings.t(lang, en: 'Edit Customer / Party', gu: 'ગ્રાહક વિગત સુધારો', hi: 'ग्राहक विवरण संपादित करें')
                  : AppStrings.t(lang, en: 'Add New Customer / Party', gu: 'નવો ગ્રાહક / પાર્ટી ઉમેરો', hi: 'नया ग्राहक / पार्टी जोड़ें'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: !isEdit,
                    style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: '${AppStrings.t(lang, en: 'Party / Customer Name', gu: 'પાર્ટી / ગ્રાહકનું નામ', hi: 'पार्टी / ग्राहक का नाम')} *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter party name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: AppStrings.t(lang, en: 'Phone Number', gu: 'ફોન નંબર', hi: 'फ़ोन नंबर'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: gstinController,
                          style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: 'GSTIN (Optional)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: AppStrings.t(lang, en: 'City / Address', gu: 'સરનામું / શહેર', hi: 'पता / शहर'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: AppStrings.t(lang, en: 'Notes / Details', gu: 'ખાસ નોંધ', hi: 'विशेष नोट'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final address = addressController.text.trim();
              final gstin = gstinController.text.trim();
              final notes = notesController.text.trim();

              Navigator.of(ctx).pop();

              final cust = CustomerModel(
                id: existing?.id,
                name: name,
                phone: phone,
                address: address,
                gstin: gstin,
                notes: notes,
              );

              if (isEdit) {
                await provider.updateCustomer(cust);
              } else {
                await provider.addCustomer(cust);
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit ? 'Customer "$name" updated!' : 'Customer "$name" added successfully!',
                    ),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isEdit
                  ? AppStrings.t(lang, en: 'Save Changes', gu: 'સાચવો', hi: 'सहेजें')
                  : AppStrings.t(lang, en: 'Add Customer', gu: 'ગ્રાહક ઉમેરો', hi: 'ग्राहक जोड़ें'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateCustomerBillDialog([CustomerModel? preselectedCustomer]) {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customers = provider.customers;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one customer first.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      _openAddCustomerDialog();
      return;
    }

    CustomerModel selectedCustomer = preselectedCustomer ?? customers.first;
    final billNoController = TextEditingController(text: 'INV-${DateFormat("yyMMdd-HHmm").format(DateTime.now())}');
    final amountController = TextEditingController();
    final initialPaidController = TextEditingController(text: '0');
    final descController = TextEditingController();
    DateTime billDate = DateTime.now();

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_rounded, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.t(lang, en: 'New Customer Bill / Invoice', gu: 'નવું ગ્રાહક બિલ બનાવો', hi: 'नया ग्राहक बिल बनाएं'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Customer Dropdown
                      DropdownButtonFormField<CustomerModel>(
                        initialValue: selectedCustomer,
                        decoration: InputDecoration(
                          labelText: '${AppStrings.t(lang, en: 'Select Customer / Party', gu: 'ગ્રાહક / પાર્ટી પસંદ કરો', hi: 'ग्राहक / पार्टी चुनें')} *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: customers.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} ${c.phone.isNotEmpty ? "(${c.phone})" : ""}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCustomer = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Bill No & Bill Date in Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: billNoController,
                              style: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                labelText: '${AppStrings.t(lang, en: 'Bill / Invoice No', gu: 'બિલ નંબર', hi: 'बिल नंबर')} *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter bill no';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: billDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setDialogState(() => billDate = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_today_rounded, size: 15),
                              label: Text(DateFormat('dd-MM-yyyy').format(billDate)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Total Amount & Initial Advance / Paid in Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                labelText: '${AppStrings.t(lang, en: 'Total Bill Amount (₹)', gu: 'કુલ બિલ રકમ (₹)', hi: 'कुल बिल राशि (₹)')} *',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter amount';
                                final num = double.tryParse(val.trim());
                                if (num == null || num <= 0) return 'Invalid amount';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: initialPaidController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                              decoration: InputDecoration(
                                labelText: AppStrings.t(lang, en: 'Initial Payment / Advance (₹)', gu: 'શરૂઆતી ચૂકવણી / એડવાન્સ (₹)', hi: 'प्रारंभिक भुगतान / अग्रिम (₹)'),
                                prefixText: '₹ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description / Jobwork details
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: AppStrings.t(lang, en: 'Description / Jobwork Details / Notes', gu: 'કામ / ડિઝાઇન વિગત', hi: 'काम / डिज़ाइन विवरण'),
                          hintText: 'e.g. 500 pcs Saree embroidery, D-101 design work...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'રદ્દ करें')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) return;
                  final billNo = billNoController.text.trim();
                  final totalAmt = double.tryParse(amountController.text.trim()) ?? 0.0;
                  final initialPaid = double.tryParse(initialPaidController.text.trim()) ?? 0.0;
                  final desc = descController.text.trim();

                  Navigator.of(ctx).pop();

                  final bill = CustomerBillModel(
                    billNo: billNo,
                    customerId: selectedCustomer.id!,
                    customerName: selectedCustomer.name,
                    date: billDate,
                    totalAmount: totalAmt,
                    paidAmount: initialPaid.clamp(0.0, totalAmt),
                    notes: desc,
                  );

                  await provider.addCustomerBill(bill);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Customer Bill "$billNo" for ₹${totalAmt.toStringAsFixed(2)} created!'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  AppStrings.t(lang, en: 'Create Bill', gu: 'બિલ બનાવો', hi: 'बिल बनाएं'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openRecordCustomerPaymentDialog(CustomerBillModel bill) {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final remaining = bill.remainingAmount;
    final payAmountController = TextEditingController(
      text: remaining > 0 ? remaining.toStringAsFixed(2) : bill.totalAmount.toStringAsFixed(2),
    );
    final refController = TextEditingController();
    String selectedMode = 'Bank / UPI';
    DateTime payDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final enteredVal = double.tryParse(payAmountController.text.trim()) ?? 0.0;
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(lang, en: 'Record Payment from Customer', gu: 'ગ્રાહક પાસેથી રકમ જમા કરો', hi: 'ग्राहक से भुगतान दर्ज करें'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Bill #${bill.billNo} • Party: ${bill.customerName}',
                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount breakdown header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Bill', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B))),
                            Text('₹${NumberFormat('#,##,###.00').format(bill.totalAmount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Received', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                            Text('₹${NumberFormat('#,##,###.00').format(bill.paidAmount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Remaining Due', style: TextStyle(fontSize: 11, color: remaining > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                            Text('₹${NumberFormat('#,##,###.00').format(remaining)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: remaining > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick presets
                  Wrap(
                    spacing: 8,
                    children: [
                      if (remaining > 0)
                        ActionChip(
                          avatar: const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF10B981)),
                          label: Text('Full Due: ₹${remaining.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setDialogState(() {
                              payAmountController.text = remaining.toStringAsFixed(2);
                            });
                          },
                        ),
                      if (remaining > 0)
                        ActionChip(
                          avatar: const Icon(Icons.pie_chart_outline_rounded, size: 14, color: Color(0xFF3B82F6)),
                          label: Text('50% Half: ₹${(remaining / 2).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setDialogState(() {
                              payAmountController.text = (remaining / 2).toStringAsFixed(2);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Payment Amount input
                  TextField(
                    controller: payAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: AppStrings.t(lang, en: 'Payment Amount to Collect (₹)', gu: 'જમા કરવાની રકમ (₹)', hi: 'जमा करने की राशि (₹)'),
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Mode & Date
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedMode,
                          decoration: InputDecoration(
                            labelText: AppStrings.t(lang, en: 'Payment Mode', gu: 'ચૂકવણી રીત', hi: 'भुगतान माध्यम'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: ['Bank / UPI', 'Cash', 'Cheque', 'RTGS / NEFT']
                              .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedMode = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: payDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() => payDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 14),
                        label: Text(DateFormat('dd-MM-yyyy').format(payDate), style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Reference / Notes
                  TextField(
                    controller: refController,
                    style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: AppStrings.t(lang, en: 'Reference / Cheque No / Notes', gu: 'સંદર્ભ / ચેક નંબર / નોંધ', hi: 'संदर्भ / चेक नंबर / नोट'),
                      hintText: 'e.g. UPI Ref #123456 or Cheque #8910',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final payVal = double.tryParse(payAmountController.text.trim()) ?? 0.0;
                  if (payVal <= 0) return;

                  Navigator.of(ctx).pop();

                  final payment = CustomerPaymentModel(
                    billId: bill.id,
                    customerId: bill.customerId,
                    customerName: bill.customerName,
                    amount: payVal,
                    date: payDate,
                    paymentMode: selectedMode,
                    notes: refController.text.trim(),
                  );

                  await provider.recordCustomerPayment(payment);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment of ₹${payVal.toStringAsFixed(2)} collected from ${bill.customerName}!'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  enteredVal >= remaining && remaining > 0
                      ? AppStrings.t(lang, en: 'Full Payment Done', gu: 'સંપૂર્ણ ચૂકતે જમા', hi: 'पूर्ण भुगतान जमा')
                      : AppStrings.t(lang, en: 'Record Payment', gu: 'ચૂકવણી જમા કરો', hi: 'भुगतान जमा करें'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCustomer(CustomerModel cust) async {
    final provider = context.read<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(AppStrings.t(lang, en: 'Delete Customer?', gu: 'ગ્રાહક કાઢી નાખવો?', hi: 'ग्राहक हटाएं?')),
          ],
        ),
        content: Text('Are you sure you want to delete customer "${cust.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.t(lang, en: 'Delete', gu: 'કાઢી નાખો', hi: 'हटाएं')),
          ),
        ],
      ),
    );

    if (confirm == true && cust.id != null) {
      await provider.deleteCustomer(cust.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer "${cust.name}" deleted.'),
            backgroundColor: const Color(0xFF334155),
          ),
        );
      }
    }
  }

  void _confirmDeleteBill(CustomerBillModel bill) async {
    final provider = context.read<ProductionProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Delete Bill?'),
          ],
        ),
        content: Text('Are you sure you want to delete Bill #${bill.billNo} (₹${bill.totalAmount.toStringAsFixed(2)})?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && bill.id != null) {
      await provider.deleteCustomerBill(bill.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill #${bill.billNo} deleted.'),
            backgroundColor: const Color(0xFF334155),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final lang = provider.settings.appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customers = provider.customers;
    final bills = provider.customerBills;
    final payments = provider.customerPayments;

    final totalBilled = provider.totalCustomerBilled;
    final totalReceived = provider.totalCustomerReceived;
    final totalDue = provider.totalCustomerDue;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkScaffoldBg : const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: Color(0xFF6366F1), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.t(lang,
                            en: 'Customers & Parties (Jobwork Ledger)',
                            gu: 'ગ્રાહક અને પાર્ટી ખાતાવહી (જોબવર્ક બિલિંગ)',
                            hi: 'ग्राहक एवं पार्टी बहीखाता (जॉबवर्क बिलिंग)'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.t(lang,
                            en: 'Customer directory, invoices, jobwork billings and partial / full payment collections',
                            gu: 'ગ્રાહક વિગત, ચલણ બિલ, અંશતઃ કે પૂરી રકમ જમા અને બાકી ઉઘરાણી હિસાબ',
                            hi: 'ग्राहक सूची, बिल, आंशिक अथवा पूर्ण भुगतान और बकाया वसूली हिसाब'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openAddCustomerDialog(),
                      icon: const Icon(Icons.person_add_rounded, size: 16, color: Color(0xFF6366F1)),
                      label: Text(
                        AppStrings.t(lang, en: 'Add Customer', gu: 'ગ્રાહક ઉમેરો', hi: 'ग्राहक जोड़ें'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openCreateCustomerBillDialog(),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: Text(
                        AppStrings.t(lang, en: 'New Bill / Invoice', gu: 'નવું બિલ', hi: 'नया बिल'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4 KPI Summary Cards
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      final kpi1 = _buildKpiCard(
                        title: AppStrings.t(lang, en: 'Total Billed (Revenue)', gu: 'કુલ બિલ રકમ (આવક)', hi: 'कुल बिल राशि (आय)'),
                        value: '₹${NumberFormat('#,##,###.00').format(totalBilled)}',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF3B82F6),
                        bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                        isDark: isDark,
                      );
                      final kpi2 = _buildKpiCard(
                        title: AppStrings.t(lang, en: 'Total Received / Paid', gu: 'કુલ જમા મળેલ રકમ', hi: 'कुल प्राप्त भुगतान'),
                        value: '₹${NumberFormat('#,##,###.00').format(totalReceived)}',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                        isDark: isDark,
                      );
                      final kpi3 = _buildKpiCard(
                        title: AppStrings.t(lang, en: 'Total Remaining Due', gu: 'કુલ બાકી ઉઘરાણી', hi: 'कुल बकाया बाकी'),
                        value: '₹${NumberFormat('#,##,###.00').format(totalDue)}',
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFEF4444),
                        bgColor: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
                        isDark: isDark,
                      );
                      final kpi4 = _buildKpiCard(
                        title: AppStrings.t(lang, en: 'Active Customers', gu: 'કુલ ગ્રાહકો / પાર્ટીઓ', hi: 'सक्रिय ग्राहक'),
                        value: '${customers.length} Parties',
                        icon: Icons.store_rounded,
                        color: const Color(0xFF8B5CF6),
                        bgColor: isDark ? const Color(0xFF4C1D95).withValues(alpha: 0.3) : const Color(0xFFF5F3FF),
                        isDark: isDark,
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: kpi1),
                            const SizedBox(width: 14),
                            Expanded(child: kpi2),
                            const SizedBox(width: 14),
                            Expanded(child: kpi3),
                            const SizedBox(width: 14),
                            Expanded(child: kpi4),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            Row(children: [Expanded(child: kpi1), const SizedBox(width: 14), Expanded(child: kpi2)]),
                            const SizedBox(height: 14),
                            Row(children: [Expanded(child: kpi3), const SizedBox(width: 14), Expanded(child: kpi4)]),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Tab Navigation
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.people_alt_rounded, size: 16),
                          text: '${AppStrings.t(lang, en: 'Party Directory', gu: 'ગ્રાહક ડિરેક્ટરી', hi: 'पार्टी सूची')} (${customers.length})',
                        ),
                        Tab(
                          icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          text: '${AppStrings.t(lang, en: 'Invoices & Bills Register', gu: 'બિલ રજિસ્ટર', hi: 'बिल रजिस्टर')} (${bills.length})',
                        ),
                        Tab(
                          icon: const Icon(Icons.history_rounded, size: 16),
                          text: '${AppStrings.t(lang, en: 'Payment Receipts Log', gu: 'જમા રકમ ઇતિહાસ', hi: 'भुगतान रसीदें')} (${payments.length})',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Active Tab Content
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (ctx, _) {
                      switch (_tabController.index) {
                        case 0:
                          return _buildCustomersTab(customers, bills, isDark, lang);
                        case 1:
                          return _buildBillsTab(bills, isDark, lang);
                        case 2:
                        default:
                          return _buildPaymentsTab(payments, bills, isDark, lang);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: Customer Directory View
  Widget _buildCustomersTab(List<CustomerModel> customers, List<CustomerBillModel> bills, bool isDark, String lang) {
    if (customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_outline_rounded, size: 48, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Text('No customers registered yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Add your customer / party to start managing jobwork orders and invoices.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openAddCustomerDialog(),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Add First Customer'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 220,
          ),
          itemCount: customers.length,
          itemBuilder: (ctx, idx) {
            final cust = customers[idx];
            final custBills = bills.where((b) => b.customerId == cust.id).toList();
            final totalBilled = custBills.fold<double>(0.0, (s, b) => s + b.totalAmount);
            final totalPaid = custBills.fold<double>(0.0, (s, b) => s + b.paidAmount);
            final pendingDue = (totalBilled - totalPaid).clamp(0.0, double.infinity);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        child: Text(
                          cust.name.isNotEmpty ? cust.name[0].toUpperCase() : 'C',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1), fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cust.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              cust.phone.isNotEmpty ? cust.phone : (cust.address.isNotEmpty ? cust.address : 'No contact info'),
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        onPressed: () => _openAddCustomerDialog(cust),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        onPressed: () => _confirmDeleteCustomer(cust),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  const Divider(height: 18),

                  // Ledger summary row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Invoiced', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B))),
                          Text('₹${NumberFormat('#,##,###.00').format(totalBilled)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Received', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                          Text('₹${NumberFormat('#,##,###.00').format(totalPaid)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Pending Due', style: TextStyle(fontSize: 11, color: pendingDue > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                          Text('₹${NumberFormat('#,##,###.00').format(pendingDue)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: pendingDue > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Quick Action button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openCreateCustomerBillDialog(cust),
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: Text('+ ${AppStrings.t(lang, en: 'Create Bill', gu: 'બિલ બનાવો', hi: 'बिल बनाएं')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // TAB 2: Customer Bills & Invoices Register View
  Widget _buildBillsTab(List<CustomerBillModel> allBills, bool isDark, String lang) {
    // Filter
    final query = _searchController.text.trim().toLowerCase();
    List<CustomerBillModel> filtered = allBills.where((b) {
      if (_billStatusFilter != 'ALL' && b.paymentStatus != _billStatusFilter) return false;
      if (query.isNotEmpty) {
        final matchBill = b.billNo.toLowerCase().contains(query);
        final matchCust = b.customerName.toLowerCase().contains(query);
        final matchNotes = b.notes.toLowerCase().contains(query);
        if (!matchBill && !matchCust && !matchNotes) return false;
      }
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case 'billNo':
          cmp = a.billNo.compareTo(b.billNo);
          break;
        case 'customerName':
          cmp = a.customerName.compareTo(b.customerName);
          break;
        case 'totalAmount':
          cmp = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 'remainingAmount':
          cmp = a.remainingAmount.compareTo(b.remainingAmount);
          break;
        case 'date':
        default:
          cmp = a.date.compareTo(b.date);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    final totalFilteredAmt = filtered.fold<double>(0.0, (s, b) => s + b.totalAmount);
    final totalFilteredDue = filtered.fold<double>(0.0, (s, b) => s + b.remainingAmount);

    // Safe Pagination
    final totalRecords = filtered.length;
    final totalPages = _showAll ? 1 : (totalRecords <= 0 ? 1 : ((totalRecords - 1) ~/ _pageSize) + 1);
    final safeCurrentPage = SafeRangeUtils.safePage(_currentPage, totalPages);
    final pageItems = _showAll
        ? filtered
        : SafeRangeUtils.safePageSlice(filtered, safeCurrentPage, _pageSize);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Toolbar
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Search by bill number, customer name, notes...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() => _currentPage = 1),
                  ),
                ),
                const SizedBox(width: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ALL', label: Text('All Bills')),
                    ButtonSegment(value: 'Unpaid', label: Text('Unpaid')),
                    ButtonSegment(value: 'Partial', label: Text('Partial')),
                    ButtonSegment(value: 'Paid', label: Text('Fully Paid')),
                  ],
                  selected: {_billStatusFilter},
                  onSelectionChanged: (val) {
                    setState(() {
                      _billStatusFilter = val.first;
                      _currentPage = 1;
                    });
                  },
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                bottom: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                _buildSortHeader('#', '', flex: 1),
                _buildSortHeader('Date', 'date', flex: 2),
                _buildSortHeader('Bill No', 'billNo', flex: 3),
                _buildSortHeader('Customer / Party', 'customerName', flex: 4),
                _buildSortHeader('Total Bill (₹)', 'totalAmount', flex: 2),
                _buildSortHeader('Paid (₹)', '', flex: 2),
                _buildSortHeader('Due (₹)', 'remainingAmount', flex: 2),
                _buildSortHeader('Status', '', flex: 2),
                const SizedBox(width: 90, child: Text('Actions', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // Table Body
          if (pageItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text('No bills found matching filters', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B))),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageItems.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppTheme.darkBorder.withValues(alpha: 0.5) : const Color(0xFFF1F5F9)),
              itemBuilder: (ctx, idx) {
                final bill = pageItems[idx];
                final rowIdx = _showAll ? idx + 1 : ((safeCurrentPage - 1) * _pageSize) + idx + 1;

                Color badgeBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
                Color badgeColor = const Color(0xFFEF4444);
                if (bill.isPaid) {
                  badgeBg = const Color(0xFF10B981).withValues(alpha: 0.14);
                  badgeColor = const Color(0xFF10B981);
                } else if (bill.isPartiallyPaid) {
                  badgeBg = Colors.amber.withValues(alpha: 0.14);
                  badgeColor = Colors.amber[800]!;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text('$rowIdx', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)))),
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormat('dd-MM-yyyy').format(bill.date),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B)),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          bill.billNo,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF0284C7)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.customerName,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (bill.notes.isNotEmpty)
                              Text(bill.notes, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${NumberFormat('#,##,###.00').format(bill.totalAmount)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${NumberFormat('#,##,###.00').format(bill.paidAmount)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${NumberFormat('#,##,###.00').format(bill.remainingAmount)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: bill.remainingAmount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            bill.paymentStatus.toUpperCase(),
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!bill.isPaid)
                              IconButton(
                                icon: const Icon(Icons.add_card_rounded, size: 17, color: Color(0xFF10B981)),
                                onPressed: () => _openRecordCustomerPaymentDialog(bill),
                                tooltip: 'Collect Payment',
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                              onPressed: () => _confirmDeleteBill(bill),
                              tooltip: 'Delete Bill',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${pageItems.length} of $totalRecords bills (Total: ₹${NumberFormat('#,##,###.00').format(totalFilteredAmt)} • Due: ₹${NumberFormat('#,##,###.00').format(totalFilteredDue)})',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                ),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _showAll,
                          onChanged: (val) {
                            setState(() {
                              _showAll = val ?? false;
                              _currentPage = 1;
                            });
                          },
                        ),
                        const Text('Show All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(width: 14),
                    if (!_showAll) ...[
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: safeCurrentPage > 1 ? () => setState(() => _currentPage = safeCurrentPage - 1) : null,
                      ),
                      Text('$safeCurrentPage / $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        onPressed: safeCurrentPage < totalPages ? () => setState(() => _currentPage = safeCurrentPage + 1) : null,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Payment Receipts Log View
  Widget _buildPaymentsTab(List<CustomerPaymentModel> payments, List<CustomerBillModel> bills, bool isDark, String lang) {
    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 40, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              Text('No customer payment receipts recorded yet', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }

    final totalCollected = payments.fold<double>(0.0, (s, p) => s + p.amount);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                _buildSortHeader('#', '', flex: 1),
                _buildSortHeader('Receipt Date', '', flex: 2),
                _buildSortHeader('Customer / Party', '', flex: 4),
                _buildSortHeader('Bill Reference', '', flex: 3),
                _buildSortHeader('Amount Received (₹)', '', flex: 3),
                _buildSortHeader('Payment Mode', '', flex: 2),
                _buildSortHeader('Notes / Ref', '', flex: 3),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppTheme.darkBorder.withValues(alpha: 0.5) : const Color(0xFFF1F5F9)),
            itemBuilder: (ctx, idx) {
              final p = payments[idx];
              CustomerBillModel? bill;
              try {
                bill = bills.firstWhere((b) => b.id == p.billId);
              } catch (_) {}

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text('${idx + 1}', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)))),
                    Expanded(flex: 2, child: Text(DateFormat('dd-MM-yyyy').format(p.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 4, child: Text(bill?.customerName ?? 'Party #${p.customerId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                    Expanded(flex: 3, child: Text(bill != null ? 'Bill #${bill.billNo}' : 'Bill ID #${p.billId}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF0284C7)))),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '₹${NumberFormat('#,##,###.00').format(p.amount)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ),
                    Expanded(flex: 2, child: Text(p.paymentMode, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)))),
                    Expanded(flex: 3, child: Text(p.notes.isNotEmpty ? p.notes : '-', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)))),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceSubtle : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Payments Recorded: ${payments.length}', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B))),
                Text('Total Collected: ₹${NumberFormat('#,##,###.00').format(totalCollected)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortHeader(String title, String colKey, {required int flex}) {
    final isSelected = _sortColumn == colKey && colKey.isNotEmpty;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: colKey.isEmpty
            ? null
            : () {
                setState(() {
                  if (_sortColumn == colKey) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumn = colKey;
                    _sortAscending = true;
                  }
                });
              },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF6366F1) : null),
            ),
            if (colKey.isNotEmpty) ...[
              const SizedBox(width: 4),
              Icon(
                isSelected ? (_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded) : Icons.unfold_more_rounded,
                size: 13,
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

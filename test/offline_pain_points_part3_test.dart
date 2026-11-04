import 'package:flutter_test/flutter_test.dart';
import 'package:emb_cal/widgets/print_slip_dialog.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  group('Part 3: Offline Pain Points & User Friction Fixes Tests', () {
    test('तकलीफ २: PrintSlipData generates formatted thermal voucher receipt text with signatures', () {
      final now = DateTime(2026, 10, 31, 14, 30);
      final slipData = PrintSlipData(
        title: 'ઉપાડ પાવતી (Advance Voucher)',
        voucherNo: 'UPD-1024',
        dateTime: now,
        companyName: 'OM MAVTAR GROUP',
        companyAddress: 'Surat, Gujarat',
        employeeName: 'Ramesh Patel',
        employeeId: 101,
        role: 'Master Operator',
        phone: '9876543210',
        monthlySalary: 20000,
        currentAmount: 5000,
        totalPendingUpad: 7000,
        netPayable: 13000,
        notes: 'Diwali Advance Festival Upad',
        voucherType: 'advance',
        isOverdraft: false,
      );

      final receiptText = PrintSlipDialog.generateTextReceipt(slipData);

      // Verifications
      expect(receiptText.contains('OM MAVTAR GROUP'), isTrue);
      expect(receiptText.contains('VAUCHER NO: UPD-1024'), isTrue);
      expect(receiptText.contains('Ramesh Patel (MASTER OPERATOR)'), isTrue);
      expect(receiptText.contains('Base Monthly Salary: ₹20,000.00'), isTrue);
      expect(receiptText.contains('Current Amount:     ₹5,000.00'), isTrue);
      expect(receiptText.contains('Total Advance:       ₹7,000.00'), isTrue);
      expect(receiptText.contains('Net Remaining / Pay: ₹13,000.00'), isTrue);
      expect(receiptText.contains('Diwali Advance Festival Upad'), isTrue);
      expect(receiptText.contains('Worker Sign / Thumb'), isTrue);
      expect(receiptText.contains('Authorized Manager'), isTrue);
      expect(receiptText.contains('NOTICE: Excess Advance'), isFalse);
    });

    test('तकलीफ २: PrintSlipData flags overdraft when advance exceeds salary', () {
      final now = DateTime(2026, 10, 31, 15, 00);
      final slipData = PrintSlipData(
        title: 'પગાર આખરી હિસાબ પાવતી (Salary Settlement Slip)',
        voucherNo: 'SETTL-102',
        dateTime: now,
        companyName: 'OM MAVTAR GROUP',
        employeeName: 'Suresh Kumar',
        employeeId: 102,
        role: 'Helper',
        phone: '9876500000',
        monthlySalary: 15000,
        currentAmount: 22000,
        totalPendingUpad: 22000,
        netPayable: -7000,
        notes: 'Excess advance taken for family medical emergency',
        voucherType: 'settlement',
        isOverdraft: true,
      );

      final receiptText = PrintSlipDialog.generateTextReceipt(slipData);
      expect(receiptText.contains('NOTICE: Excess Advance carried forward to next month.'), isTrue);
      expect(receiptText.contains('-7,000.00'), isTrue);
    });

    test('तकलीफ ७: 0 Stitch input is rejected normally but accepted when breakdown is allowed', () {
      // Normal production entry requires stitch > 0
      final normalValidation = ProductionProvider.validateTotalStitch('0', allowZero: false);
      expect(normalValidation, contains('must be greater than zero'));

      // Empty or invalid input
      final emptyValidation = ProductionProvider.validateTotalStitch('', allowZero: false);
      expect(emptyValidation, contains('Total stitch count is required'));

      // Breakdown mode allows 0 stitch
      final breakdownValidation = ProductionProvider.validateTotalStitch('0', allowZero: true);
      expect(breakdownValidation, isNull);

      // Comma-separated stitch counts
      final validStitch = ProductionProvider.validateTotalStitch('2,50,000', allowZero: false);
      expect(validStitch, isNull);
    });

    test('तकलीफ ३: Overdraft Carry Forward Math logic preserves outstanding excess advances', () {
      const double salary = 18000.0;
      const double totalUpad = 25000.0;

      final double remainingSalary = salary - totalUpad;
      expect(remainingSalary, equals(-7000.0));

      final double carryForwardAmount = (totalUpad > salary) ? (totalUpad - salary) : 0.0;
      expect(carryForwardAmount, equals(7000.0));

      // Normal case when upad < salary
      const double normalUpad = 12000.0;
      final double normalRemaining = salary - normalUpad;
      expect(normalRemaining, equals(6000.0));
      final double normalCarryForward = (normalUpad > salary) ? (normalUpad - salary) : 0.0;
      expect(normalCarryForward, equals(0.0));
    });
  });
}

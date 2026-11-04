import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/models/models.dart';
import 'package:emb_cal/core/utils/safe_range_utils.dart';
import 'package:emb_cal/providers/production_provider.dart';
import 'package:emb_cal/data/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SafeRangeUtils & Boundary Protection Tests', () {
    test('SafeRangeUtils prevents RangeError on out of bounds indexing and empty lists', () {
      final list = [1, 2, 3, 4, 5];
      expect(SafeRangeUtils.safeGet(list, 0), 1);
      expect(SafeRangeUtils.safeGet(list, 4), 5);
      expect(SafeRangeUtils.safeGet(list, 5, fallback: -1), -1);
      expect(SafeRangeUtils.safeGet(list, -1, fallback: 99), 99);
      expect(SafeRangeUtils.safeGet(<int>[], 0), isNull);

      // Safe Sublist
      expect(SafeRangeUtils.safeSublist(list, 0, 3), [1, 2, 3]);
      expect(SafeRangeUtils.safeSublist(list, 3, 10), [4, 5]);
      expect(SafeRangeUtils.safeSublist(list, -5, 2), [1, 2]);
      expect(SafeRangeUtils.safeSublist(list, 5, 2), isEmpty);
      expect(SafeRangeUtils.safeSublist(<int>[], 0, 5), isEmpty);

      // Safe Page Slice
      expect(SafeRangeUtils.safePageSlice(list, 1, 2), [1, 2]);
      expect(SafeRangeUtils.safePageSlice(list, 2, 2), [3, 4]);
      expect(SafeRangeUtils.safePageSlice(list, 3, 2), [5]);
      expect(SafeRangeUtils.safePageSlice(list, 99, 2), [5]); // Clamps to last valid page
      expect(SafeRangeUtils.safePageSlice(<int>[], 1, 10), isEmpty);

      // Safe Page Number
      expect(SafeRangeUtils.safePage(1, 5), 1);
      expect(SafeRangeUtils.safePage(10, 5), 5);
      expect(SafeRangeUtils.safePage(-2, 5), 1);
      expect(SafeRangeUtils.safePage(1, 0), 1);
    });
  });

  group('Customer & Billing Model Status Calculations', () {
    test('CustomerBillModel accurately computes Unpaid, Partial, and Paid states', () {
      final unpaidBill = CustomerBillModel(
        billNo: 'INV-101',
        customerName: 'Shree Radhe Fashion',
        date: DateTime.now(),
        totalAmount: 10000.0,
        paidAmount: 0.0,
      );
      expect(unpaidBill.remainingAmount, 10000.0);
      expect(unpaidBill.isUnpaid, isTrue);
      expect(unpaidBill.isPartial, isFalse);
      expect(unpaidBill.isPaid, isFalse);
      expect(unpaidBill.paymentStatus, 'Unpaid');

      final partialBill = CustomerBillModel(
        billNo: 'INV-102',
        customerName: 'Shree Radhe Fashion',
        date: DateTime.now(),
        totalAmount: 10000.0,
        paidAmount: 4000.0,
      );
      expect(partialBill.remainingAmount, 6000.0);
      expect(partialBill.isUnpaid, isFalse);
      expect(partialBill.isPartial, isTrue);
      expect(partialBill.isPartiallyPaid, isTrue);
      expect(partialBill.isPaid, isFalse);
      expect(partialBill.paymentStatus, 'Partial');

      final fullyPaidBill = CustomerBillModel(
        billNo: 'INV-103',
        customerName: 'Shree Radhe Fashion',
        date: DateTime.now(),
        totalAmount: 10000.0,
        paidAmount: 10000.0,
      );
      expect(fullyPaidBill.remainingAmount, 0.0);
      expect(fullyPaidBill.isUnpaid, isFalse);
      expect(fullyPaidBill.isPartial, isFalse);
      expect(fullyPaidBill.isPaid, isTrue);
      expect(fullyPaidBill.paymentStatus, 'Paid');
    });

    test('MaterialItem accurately tracks partial vs full payments', () {
      final item = MaterialItem(
        challanNo: 'CH-901',
        supplierName: 'ABC Sequins',
        date: DateTime.now(),
        category: 'Sequence',
        productName: '9mm Multi',
        itemType: 'piece',
        qty: 100.0,
        rate: 50.0,
        paidAmount: 2500.0, // Exactly half
      );
      expect(item.amount, 5000.0);
      expect(item.paidAmount, 2500.0);
      expect(item.remainingAmount, 2500.0);
      expect(item.isPartiallyPaid, isTrue);
      expect(item.isPaid, isFalse);
      expect(item.paymentStatus, 'Partial');

      final fullyPaid = item.copyWith(paidAmount: 5000.0, paymentStatus: 'Paid');
      expect(fullyPaid.isPaid, isTrue);
      expect(fullyPaid.remainingAmount, 0.0);
    });
  });

  group('ProductionProvider Customer, Bill, Payment & Expense Integration', () {
    test('Provider adds customer, bill, records partial payment and calculates net financial health', () async {
      await DatabaseHelper.instance.database;
      final provider = ProductionProvider();
      await provider.init();

      // 1. Add Customer
      final cust = CustomerModel(
        name: 'Omkar Exports',
        phone: '9876543210',
        city: 'Surat',
        notes: 'VIP Client',
      );
      await provider.addCustomer(cust);
      expect(provider.customers.any((c) => c.name == 'Omkar Exports'), isTrue);
      final createdCust = provider.customers.firstWhere((c) => c.name == 'Omkar Exports');

      // 2. Add Bill for 25,000
      final bill = CustomerBillModel(
        billNo: 'BILL-001',
        customerId: createdCust.id,
        customerName: createdCust.name,
        date: DateTime.now(),
        totalAmount: 25000.0,
        paidAmount: 0.0,
      );
      await provider.addCustomerBill(bill);
      expect(provider.customerBills.any((b) => b.billNo == 'BILL-001'), isTrue);
      expect(provider.totalCustomerBilled, 25000.0);
      expect(provider.totalCustomerReceived, 0.0);
      expect(provider.totalCustomerDue, 25000.0);

      // 3. Record Partial Customer Payment of 10,000 (40%)
      final createdBill = provider.customerBills.firstWhere((b) => b.billNo == 'BILL-001');
      final payment = CustomerPaymentModel(
        billId: createdBill.id,
        customerId: createdCust.id,
        customerName: createdCust.name,
        amount: 10000.0,
        date: DateTime.now(),
        paymentMode: 'Bank / UPI',
        notes: 'Partial advance',
      );
      await provider.recordCustomerPayment(payment);

      expect(provider.totalCustomerReceived, 10000.0);
      expect(provider.totalCustomerDue, 15000.0);
      final updatedBill = provider.customerBills.firstWhere((b) => b.billNo == 'BILL-001');
      expect(updatedBill.paidAmount, 10000.0);
      expect(updatedBill.isPartiallyPaid, isTrue);
      expect(updatedBill.paymentStatus, 'Partial');

      // 4. Record Factory Expense of 2,500 (Electricity)
      final exp = ExpenseModel(
        category: 'ELECTRICITY',
        amount: 2500.0,
        date: DateTime.now(),
        title: 'Factory Light Bill',
        paymentMode: 'Cash',
      );
      await provider.addExpense(exp);
      expect(provider.expenses.any((e) => e.title == 'Factory Light Bill'), isTrue);
      expect(provider.totalExpensesAmount, 2500.0);

      // 5. Verify Net Cash Flow Balance
      expect(provider.netCashFlowBalance, 10000.0 - 2500.0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:emb_cal/core/whatsapp_service.dart';
import 'package:emb_cal/models/employee_model.dart';
import 'package:emb_cal/models/settings_model.dart';
import 'package:emb_cal/models/whatsapp_log_model.dart';

void main() {
  group('WhatsApp Service - Phone Formatting & Validation', () {
    test('cleans and formats standard 10-digit Indian numbers with 91 prefix', () {
      expect(WhatsAppService.cleanPhoneNumber('9876543210'), '919876543210');
      expect(WhatsAppService.cleanPhoneNumber('98765 43210'), '919876543210');
      expect(WhatsAppService.cleanPhoneNumber('+91 98765-43210'), '919876543210');
      expect(WhatsAppService.cleanPhoneNumber('(98765) 43210'), '919876543210');
    });

    test('handles 11-digit numbers starting with 0', () {
      expect(WhatsAppService.cleanPhoneNumber('09876543210'), '919876543210');
    });

    test('preserves 12-digit numbers already containing country code 91', () {
      expect(WhatsAppService.cleanPhoneNumber('919876543210'), '919876543210');
    });

    test('validates phone numbers correctly', () {
      expect(WhatsAppService.isValidPhone('9876543210'), isTrue);
      expect(WhatsAppService.isValidPhone('+919876543210'), isTrue);
      expect(WhatsAppService.isValidPhone('12345'), isFalse);
      expect(WhatsAppService.isValidPhone(''), isFalse);
      expect(WhatsAppService.isValidPhone(null), isFalse);
    });
  });

  group('WhatsApp Service - Respectful Honorific Salutations (मानवाचक शब्द)', () {
    test('generates respectful Hindi salutation with name and "जी"', () {
      final maleSalutation = WhatsAppService.getHindiSalutation('Male', 'Ramesh Patel');
      expect(maleSalutation, 'Ramesh Patel जी');

      final femaleSalutation = WhatsAppService.getHindiSalutation('Female', 'Geeta Ben');
      expect(femaleSalutation, 'Geeta Ben जी');
    });

    test('generates polite English salutation with name and "ji"', () {
      final maleSalutation = WhatsAppService.getEnglishSalutation('Male', 'Ramesh Patel');
      expect(maleSalutation, 'Ramesh Patel ji');

      final femaleSalutation = WhatsAppService.getEnglishSalutation('Female', 'Geeta Ben');
      expect(femaleSalutation, 'Geeta Ben ji');
    });
  });

  group('WhatsApp Service - Message Generation & Company Name Verification', () {
    const company = 'OM MAVTAR GROUP';
    const empName = 'Ramesh Patel';
    const role = 'Operator';
    const gender = 'Male';
    const upadAmount = 2500.0;
    const date = '28/10/2026';
    const notes = 'Family Festival Advance';
    const monthlySalary = 20000.0;
    const totalPendingUpad = 4500.0;
    const remainingSalary = 15500.0;
    const senderPhone = '9876543210';

    test('builds comprehensive Hindi receipt message with OM MAVTAR GROUP and respectful honorific', () {
      final msg = WhatsAppService.generateUpadMessage(
        language: 'Hindi',
        companyName: company,
        employeeName: empName,
        role: role,
        gender: gender,
        upadAmount: upadAmount,
        date: date,
        notes: notes,
        monthlySalary: monthlySalary,
        totalPendingUpad: totalPendingUpad,
        remainingSalary: remainingSalary,
        senderPhone: senderPhone,
      );

      expect(msg, contains('OM MAVTAR GROUP'));
      expect(msg, contains('नमस्ते Ramesh Patel जी,'));
      expect(msg, contains('2,500.00'));
      expect(msg, contains('20,000.00'));
      expect(msg, contains('4,500.00'));
      expect(msg, contains('15,500.00'));
      expect(msg, contains('Family Festival Advance'));
      expect(msg, contains(senderPhone));
    });

    test('defaults company name to OM MAVTAR GROUP if empty', () {
      final msg = WhatsAppService.generateUpadMessage(
        language: 'Hindi',
        companyName: '',
        employeeName: empName,
        role: role,
        gender: gender,
        upadAmount: upadAmount,
        date: date,
        notes: notes,
        monthlySalary: monthlySalary,
        totalPendingUpad: totalPendingUpad,
        remainingSalary: remainingSalary,
        senderPhone: senderPhone,
      );

      expect(msg, contains('OM MAVTAR GROUP'));
    });

    test('builds comprehensive English receipt message with OM MAVTAR GROUP and Dear [Name] ji', () {
      final msg = WhatsAppService.generateUpadMessage(
        language: 'English',
        companyName: company,
        employeeName: 'Geeta Ben',
        role: 'Checker',
        gender: 'Female',
        upadAmount: upadAmount,
        date: date,
        notes: notes,
        monthlySalary: monthlySalary,
        totalPendingUpad: totalPendingUpad,
        remainingSalary: remainingSalary,
        senderPhone: senderPhone,
      );

      expect(msg, contains('OM MAVTAR GROUP'));
      expect(msg, contains('Dear Geeta Ben ji,'));
      expect(msg, contains('2,500.00'));
      expect(msg, contains('20,000.00'));
      expect(msg, contains('4,500.00'));
      expect(msg, contains('15,500.00'));
      expect(msg, contains('Family Festival Advance'));
      expect(msg, contains(senderPhone));
    });

    test('builds bilingual message containing both Hindi and English sections with OM MAVTAR GROUP', () {
      final msg = WhatsAppService.generateUpadMessage(
        language: 'Both',
        companyName: company,
        employeeName: empName,
        role: role,
        gender: gender,
        upadAmount: upadAmount,
        date: date,
        notes: notes,
        monthlySalary: monthlySalary,
        totalPendingUpad: totalPendingUpad,
        remainingSalary: remainingSalary,
        senderPhone: senderPhone,
      );

      expect(msg, contains('अग्रिम वेतन पावती'));
      expect(msg, contains('Salary Advance Receipt'));
      expect(msg, contains('नमस्ते Ramesh Patel जी,'));
      expect(msg, contains('Dear Ramesh Patel ji,'));
      expect(msg, contains('OM MAVTAR GROUP'));
      expect(msg, contains('2,500.00'));
      expect(msg, contains(senderPhone));
    });
  });

  group('Settings Model - WhatsApp Defaults & Configuration', () {
    test('guarantees WhatsApp Auto-Send defaults to OFF (false)', () {
      final defaultSettings = SettingsModel();
      expect(defaultSettings.whatsappAutoSend, isFalse,
          reason: 'User requirement: auto-send MUST default to OFF unless explicitly toggled ON by user');
      expect(defaultSettings.whatsappMessageLanguage, 'English');
      expect(defaultSettings.senderPhone, '');
    });

    test('toMap and fromMap serialize and deserialize WhatsApp fields correctly', () {
      final settings = SettingsModel(
        senderPhone: '9825012345',
        whatsappAutoSend: true,
        whatsappMessageLanguage: 'Hindi',
      );

      final map = settings.toMap();
      expect(map['sender_phone'], '9825012345');
      expect(map['whatsapp_auto_send'], 1);
      expect(map['whatsapp_message_language'], 'Hindi');

      final deserialized = SettingsModel.fromMap(map);
      expect(deserialized.senderPhone, '9825012345');
      expect(deserialized.whatsappAutoSend, isTrue);
      expect(deserialized.whatsappMessageLanguage, 'Hindi');
    });

    test('copyWith updates WhatsApp preferences seamlessly', () {
      final s = SettingsModel();
      final updated = s.copyWith(
        senderPhone: '9998887776',
        whatsappAutoSend: true,
        whatsappMessageLanguage: 'English',
      );

      expect(updated.senderPhone, '9998887776');
      expect(updated.whatsappAutoSend, isTrue);
      expect(updated.whatsappMessageLanguage, 'English');
    });
  });

  group('Employee Model - Gender Field Support', () {
    test('defaults to Male and serializes gender in toMap/fromMap', () {
      final emp = EmployeeModel(
        name: 'Suresh Bhai',
        monthlySalary: 18000,
        joiningDate: DateTime(2025, 1, 1),
      );

      expect(emp.gender, 'Male');

      final map = emp.toMap();
      expect(map['gender'], 'Male');

      final fromMap = EmployeeModel.fromMap(map);
      expect(fromMap.gender, 'Male');
    });

    test('supports Female gender and copyWith', () {
      final emp = EmployeeModel(
        name: 'Rekha Ben',
        gender: 'Female',
        monthlySalary: 15000,
        joiningDate: DateTime(2025, 2, 1),
      );

      expect(emp.gender, 'Female');
      final updated = emp.copyWith(monthlySalary: 16000);
      expect(updated.gender, 'Female');
      expect(updated.monthlySalary, 16000);
    });
  });

  group('WhatsApp Message Log Model & Audit Trail', () {
    test('serializes and deserializes WhatsAppLogModel with full audit details', () {
      final now = DateTime(2026, 10, 28, 15, 30);
      final log = WhatsAppLogModel(
        id: 1,
        employeeId: 42,
        employeeName: 'Kishore Bhai',
        recipientPhone: '919825012345',
        senderPhone: '919876543210',
        message: '💐 OM MAVTAR GROUP - Upad Receipt ₹2,000.00',
        messageType: 'upad_receipt',
        amount: 2000.0,
        createdAt: now,
        status: 'Sent',
      );

      final map = log.toMap();
      expect(map['id'], 1);
      expect(map['employee_id'], 42);
      expect(map['employee_name'], 'Kishore Bhai');
      expect(map['recipient_phone'], '919825012345');
      expect(map['sender_phone'], '919876543210');
      expect(map['message_type'], 'upad_receipt');
      expect(map['amount'], 2000.0);
      expect(map['created_at'], now.toIso8601String());
      expect(map['status'], 'Sent');

      final reconstructed = WhatsAppLogModel.fromMap(map);
      expect(reconstructed.id, 1);
      expect(reconstructed.employeeId, 42);
      expect(reconstructed.employeeName, 'Kishore Bhai');
      expect(reconstructed.recipientPhone, '919825012345');
      expect(reconstructed.senderPhone, '919876543210');
      expect(reconstructed.messageType, 'upad_receipt');
      expect(reconstructed.amount, 2000.0);
      expect(reconstructed.createdAt.year, 2026);
      expect(reconstructed.status, 'Sent');
    });

    test('copyWith updates fields properly', () {
      final log = WhatsAppLogModel(
        employeeName: 'Mohan Lal',
        recipientPhone: '919825011111',
        senderPhone: '919876543210',
        message: 'Statement',
      );

      final updated = log.copyWith(id: 105, status: 'Resent');
      expect(updated.id, 105);
      expect(updated.status, 'Resent');
      expect(updated.employeeName, 'Mohan Lal');
    });
  });
}

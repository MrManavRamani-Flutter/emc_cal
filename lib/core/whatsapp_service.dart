import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/employee_model.dart';
import '../providers/production_provider.dart';
import 'localization/app_strings.dart';

/// WhatsApp Notification Service for Om Mavtar Group.
///
/// Handles WhatsApp message generation, salutations based on gender (Dear Sir/Madam, आदरणीय श्री/आदरणीया मैडम),
/// multi-language support (Hindi, English, Both), phone number formatting, and URL launching.
class WhatsAppService {
  /// Standard icon representation for WhatsApp in UI.
  static Widget icon({double size = 20, Color color = const Color(0xFF25D366)}) {
    return Icon(Icons.chat_bubble_rounded, size: size, color: color);
  }
  /// Cleans and formats a phone number for international WhatsApp link (e.g. 919876543210).
  ///
  /// - Strips non-digit characters.
  /// - Strips leading zero if 11 digits.
  /// - Prepends India country code '91' for 10-digit Indian numbers.
  static String cleanPhoneNumber(String? phone) {
    if (phone == null) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    if (digits.length == 10) {
      return '91$digits';
    } else if (digits.length == 11 && digits.startsWith('0')) {
      return '91${digits.substring(1)}';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    } else if (digits.length > 10) {
      return digits;
    }
    return digits;
  }

  /// Checks if the provided phone string contains at least a valid 10-digit number.
  static bool isValidPhone(String? phone) {
    final cleaned = cleanPhoneNumber(phone);
    return cleaned.length >= 10;
  }

  /// Returns respectful salutation in Hindi using employee's name followed by honorific "जी" (मानवाचक शब्द).
  static String getHindiSalutation(String? gender, String employeeName) {
    final cleanName = employeeName.trim();
    return '$cleanName जी';
  }

  /// Returns respectful salutation in English using employee's name followed by polite honorific "ji".
  static String getEnglishSalutation(String? gender, String employeeName) {
    final cleanName = employeeName.trim();
    return '$cleanName ji';
  }

  /// Builds a formatted Upad (Advance Salary) receipt message in Hindi.
  static String buildHindiUpadMessage({
    required String companyName,
    required String employeeName,
    required String role,
    required String gender,
    required double upadAmount,
    required String date,
    required String notes,
    required double monthlySalary,
    required double totalPendingUpad,
    required double remainingSalary,
    required String senderPhone,
  }) {
    final company = companyName.trim().isNotEmpty ? companyName.trim() : 'OM MAVTAR GROUP';
    final salutation = getHindiSalutation(gender, employeeName);
    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
    final formattedUpad = currencyFormat.format(upadAmount);
    final formattedSalary = currencyFormat.format(monthlySalary);
    final formattedPending = currencyFormat.format(totalPendingUpad);
    final formattedRemaining = currencyFormat.format(remainingSalary);
    final notesText = notes.trim().isNotEmpty ? notes.trim() : 'व्यक्तिगत आवश्यकता';
    final senderDisplay = senderPhone.trim().isNotEmpty ? senderPhone.trim() : 'व्यवस्थापक कार्यालय';

    return '''
💐 *$company - अग्रिम वेतन पावती* 💐
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*नमस्ते $salutation,*

आपके खाते में आज अग्रिम वेतन की प्रविष्टि सफलतापूर्वक दर्ज कर दी गई है। विवरण नीचे दिया गया है:

📋 *अग्रिम विवरण:*
• *कर्मचारी:* $employeeName ($role)
• *अग्रिम राशि:* ₹$formattedUpad
• *दिनांक:* $date
• *उद्देश्य / नोट:* $notesText

💰 *वेतन खाता विवरण:*
• *मासिक वेतन:* ₹$formattedSalary
• *वेतन से कटौती योग्य कुल अग्रिम:* ₹$formattedPending
• *हाथ में देय अनुमानित शेष वेतन:* ₹$formattedRemaining

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 *महत्वपूर्ण नोट:* यह अग्रिम राशि आपके इस माह के वेतन से स्वतः काटी जाएगी। इसे अलग से वापस नहीं करना है।
📞 *व्यवस्थापक संपर्क:* $senderDisplay
🏢 *$company - कढ़ाई उत्पादन प्रबंधन*
'''.trim();
  }

  /// Builds a formatted Upad (Advance Salary) receipt message in Gujarati.
  static String buildGujaratiUpadMessage({
    required String companyName,
    required String employeeName,
    required String role,
    required String gender,
    required double upadAmount,
    required String date,
    required String notes,
    required double monthlySalary,
    required double totalPendingUpad,
    required double remainingSalary,
    required String senderPhone,
  }) {
    final company = companyName.trim().isNotEmpty ? companyName.trim() : 'OM MAVTAR GROUP';
    final salutation = getHindiSalutation(gender, employeeName);
    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
    final formattedUpad = currencyFormat.format(upadAmount);
    final formattedSalary = currencyFormat.format(monthlySalary);
    final formattedPending = currencyFormat.format(totalPendingUpad);
    final formattedRemaining = currencyFormat.format(remainingSalary);
    final notesText = notes.trim().isNotEmpty ? notes.trim() : 'અંગત જરૂરિયાત';
    final senderDisplay = senderPhone.trim().isNotEmpty ? senderPhone.trim() : 'ઓફિસ મેનેજમેન્ટ';

    return '''
💐 *$company - ઉપાડ પાવતી* 💐
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*નમસ્તે $salutation,*

તમારા ખાતામાં આજે ઉપાડની એન્ટ્રી સફળતાપૂર્વક નોંધવામાં આવી છે. વિગત નીચે મુજબ છે:

📋 *ઉપાડ વિગત:*
• *કર્મચારી:* $employeeName ($role)
• *ઉપાડ રકમ:* ₹$formattedUpad
• *તારીખ:* $date
• *કારણ / નોંધ:* $notesText

💰 *પગાર ખાતાની સ્થિતિ:*
• *માસિક મૂળ પગાર:* ₹$formattedSalary
• *કુલ બાકી ઉપાડ:* ₹$formattedPending
• *ચોખ્ખો બાકી પગાર:* ₹$formattedRemaining

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 *મહત્વપૂર્ણ નોંધ:* આ ઉપાડની રકમ તમારા આ મહિનાના પગારમાંથી આપોઆપ કાપવામાં આવશે.
📞 *સંપર્ક:* $senderDisplay
🏢 *$company - એમ્બ્રોઇડરી પ્રોડક્શન મેનેજમેન્ટ*
'''.trim();
  }

  /// Builds a formatted Upad (Advance Salary) receipt message in English.
  static String buildEnglishUpadMessage({
    required String companyName,
    required String employeeName,
    required String role,
    required String gender,
    required double upadAmount,
    required String date,
    required String notes,
    required double monthlySalary,
    required double totalPendingUpad,
    required double remainingSalary,
    required String senderPhone,
  }) {
    final company = companyName.trim().isNotEmpty ? companyName.trim() : 'OM MAVTAR GROUP';
    final salutation = getEnglishSalutation(gender, employeeName);
    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
    final formattedUpad = currencyFormat.format(upadAmount);
    final formattedSalary = currencyFormat.format(monthlySalary);
    final formattedPending = currencyFormat.format(totalPendingUpad);
    final formattedRemaining = currencyFormat.format(remainingSalary);
    final notesText = notes.trim().isNotEmpty ? notes.trim() : 'Personal / Advance';
    final senderDisplay = senderPhone.trim().isNotEmpty ? senderPhone.trim() : 'Management Office';

    return '''
💐 *$company - Salary Advance Receipt* 💐
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*Dear $salutation,*

Your salary advance entry has been successfully recorded in the system. Please find the details below:

📋 *Advance Details:*
• *Employee:* $employeeName ($role)
• *Advance Amount:* ₹$formattedUpad
• *Date:* $date
• *Reason / Note:* $notesText

💰 *Current Salary Account Status:*
• *Monthly Base Salary:* ₹$formattedSalary
• *Advance Deducted from Salary:* ₹$formattedPending
• *Estimated Net Payout to Hand:* ₹$formattedRemaining

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 *Important Note:* This advance will be automatically deducted from your upcoming monthly salary payout. It is not to be repaid separately.
📞 *Manager Contact:* $senderDisplay
🏢 *$company - Embroidery Production Management*
'''.trim();
  }

  /// Builds combined bilingual message (Both: English & Hindi).
  static String buildBothUpadMessage({
    required String companyName,
    required String employeeName,
    required String role,
    required String gender,
    required double upadAmount,
    required String date,
    required String notes,
    required double monthlySalary,
    required double totalPendingUpad,
    required double remainingSalary,
    required String senderPhone,
  }) {
    final hindiPart = buildHindiUpadMessage(
      companyName: companyName,
      employeeName: employeeName,
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

    final englishPart = buildEnglishUpadMessage(
      companyName: companyName,
      employeeName: employeeName,
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

    return '''
$hindiPart

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 *ENGLISH RECEIPT SUMMARY*
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$englishPart
'''.trim();
  }

  /// Generates the message according to requested language ('Hindi', 'English', or 'Both').
  static String generateUpadMessage({
    required String language,
    required String companyName,
    required String employeeName,
    required String role,
    required String gender,
    required double upadAmount,
    required String date,
    required String notes,
    required double monthlySalary,
    required double totalPendingUpad,
    required double remainingSalary,
    required String senderPhone,
  }) {
    final lang = language.trim().toLowerCase();
    if (lang == 'hindi' || lang == 'hi') {
      return buildHindiUpadMessage(
        companyName: companyName,
        employeeName: employeeName,
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
    } else if (lang == 'gujarati' || lang == 'gu') {
      return buildGujaratiUpadMessage(
        companyName: companyName,
        employeeName: employeeName,
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
    } else if (lang == 'both') {
      return buildBothUpadMessage(
        companyName: companyName,
        employeeName: employeeName,
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
    } else {
      return buildEnglishUpadMessage(
        companyName: companyName,
        employeeName: employeeName,
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
    }
  }

  /// Launches WhatsApp web/desktop link to send the message to [recipientPhone].
  /// Automatically copies [message] to clipboard as an offline fallback.
  static Future<bool> launchWhatsAppUrl({
    required String recipientPhone,
    required String message,
  }) async {
    // 1. Copy message to clipboard automatically as offline fallback
    try {
      await Clipboard.setData(ClipboardData(text: message));
    } catch (_) {}

    final cleanPhone = cleanPhoneNumber(recipientPhone);
    if (cleanPhone.isEmpty) return false;

    final encodedMessage = Uri.encodeComponent(message);
    final urlString = 'https://wa.me/$cleanPhone?text=$encodedMessage';
    final uri = Uri.parse(urlString);

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  /// Dialog to prompt user for manager/sender phone if it's missing in Settings.
  /// Updates SettingsModel and persists to database if provided.
  static Future<String?> ensureSenderPhone(
    BuildContext context,
    ProductionProvider provider,
  ) async {
    final currentSender = provider.settings.senderPhone.trim();
    if (currentSender.isNotEmpty) {
      return currentSender;
    }

    final lang = provider.settings.appLanguage;
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.t(
                        lang,
                        en: 'Sender Phone Required',
                        gu: 'મોકલનારનો ફોન નંબર જરૂરી છે',
                        hi: 'व्यवस्थापक फ़ोन नंबर आवश्यक है',
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(
                        lang,
                        en: 'To send advance receipts or statements on WhatsApp, the sender/manager phone number is required.',
                        gu: 'WhatsApp પર ઉપાડ પાવતી અથવા ખાતાવહી મોકલવા માટે મેનેજરનો મોબાઇલ નંબર હોવો જરૂરી છે.',
                        hi: 'कर्मचारी को WhatsApp पर उपाड़ पावती या खाताबही भेजने के लिए व्यवस्थापक का फ़ोन नंबर होना आवश्यक है।',
                      ),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.t(
                        lang,
                        en: 'This number will be saved in Settings for future use.',
                        gu: 'આ નંબર સેટિંગ્સમાં સેવ થશે અને આગળ પણ ઉપયોગમાં લેવાશે.',
                        hi: 'यह नंबर सेटिंग्स में सहेजा जाएगा और भविष्य में उपयोग किया जाएगा।',
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.t(
                          lang,
                          en: 'Your / Manager Mobile Number *',
                          gu: 'તમારો / મેનેજરનો મોબાઇલ નંબર *',
                          hi: 'आपका / व्यवस्थापक का मोबाइल नंबर *',
                        ),
                        hintText: AppStrings.t(
                          lang,
                          en: 'e.g. 9876543210',
                          gu: 'દા.ત. 9876543210',
                          hi: 'उदा. 9876543210',
                        ),
                        prefixIcon: const Icon(Icons.phone),
                        errorText: errorText,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(AppStrings.t(lang, en: 'Save & Continue', gu: 'સેવ કરો અને આગળ વધો', hi: 'सहेजें और आगे बढ़ें')),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    final entered = controller.text.trim();
                    if (entered.isEmpty || entered.replaceAll(RegExp(r'\D'), '').length < 10) {
                      setDialogState(() {
                        errorText = AppStrings.t(
                          lang,
                          en: 'Please enter a valid 10-digit mobile number',
                          gu: 'કૃપા કરીને માન્ય 10 અંકનો મોબાઇલ નંબર દાખલ કરો',
                          hi: 'कृपया मान्य 10 अंकों का मोबाइल नंबर दर्ज करें',
                        );
                      });
                      return;
                    }
                    Navigator.of(ctx).pop(entered);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final updatedSettings = provider.settings.copyWith(senderPhone: result);
      await provider.saveSettings(updatedSettings);
      return result;
    }
    return null;
  }

  /// Dialog to prompt or confirm employee phone if it's missing.
  static Future<String?> ensureEmployeePhone(
    BuildContext context,
    EmployeeModel employee,
    ProductionProvider provider,
  ) async {
    final currentPhone = employee.phone.trim();
    if (currentPhone.isNotEmpty) {
      return currentPhone;
    }

    final lang = provider.settings.appLanguage;
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_android, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.t(
                        lang,
                        en: 'Add Phone for ${employee.name}',
                        gu: '${employee.name} નો ફોન નંબર ઉમેરો',
                        hi: '${employee.name} का फ़ोन नंबर जोड़ें',
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(
                        lang,
                        en: 'Employee "${employee.name}" does not have a phone number in profile. Phone is required for WhatsApp.',
                        gu: 'કર્મચારી "${employee.name}" ના પ્રોફાઇલમાં ફોન નંબર નથી. WhatsApp મેસેજ માટે નંબર જરૂરી છે.',
                        hi: 'कर्मचारी "${employee.name}" के प्रोफ़ाइल में फ़ोन नंबर नहीं जुड़ा है। WhatsApp संदेश भेजने के लिए नंबर आवश्यक है।',
                      ),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.t(
                          lang,
                          en: 'Employee Mobile Number *',
                          gu: 'કર્મચારીનો મોબાઇલ નંબર *',
                          hi: 'कर्मचारी का मोबाइल नंबर *',
                        ),
                        hintText: AppStrings.t(
                          lang,
                          en: 'e.g. 9825012345',
                          gu: 'દા.ત. 9825012345',
                          hi: 'उदा. 9825012345',
                        ),
                        prefixIcon: const Icon(Icons.phone),
                        errorText: errorText,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(AppStrings.t(lang, en: 'Cancel', gu: 'રદ કરો', hi: 'रद्द करें')),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  label: Text(AppStrings.t(lang, en: 'Save Phone', gu: 'નંબર સેવ કરો', hi: 'फ़ोन सहेजें')),
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange[800]),
                  onPressed: () async {
                    final entered = controller.text.trim();
                    if (entered.isEmpty || entered.replaceAll(RegExp(r'\D'), '').length < 10) {
                      setDialogState(() {
                        errorText = AppStrings.t(
                          lang,
                          en: 'Please enter a valid 10-digit mobile number',
                          gu: 'કૃપા કરીને માન્ય 10 અંકનો મોબાઇલ નંબર દાખલ કરો',
                          hi: 'कृपया मान्य 10 अंकों का मोबाइल नंबर दर्ज करें',
                        );
                      });
                      return;
                    }
                    Navigator.of(ctx).pop(entered);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final updatedEmployee = employee.copyWith(phone: result);
      await provider.updateEmployee(updatedEmployee);
      return result;
    }
    return null;
  }
}

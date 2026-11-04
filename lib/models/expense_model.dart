import 'package:intl/intl.dart';
import 'settings_model.dart';

/// Represents a general factory operating overhead or expense
class ExpenseModel {
  final int? id;
  final DateTime date;
  final String category;
  final double amount;
  final String paymentMode; // 'Cash', 'Bank / UPI', 'Cheque'
  final String paidTo;
  final String notes;
  final DateTime createdAt;

  static const List<String> categories = SettingsModel.defaultExpenseCategories;

  ExpenseModel({
    this.id,
    DateTime? date,
    required this.category,
    required this.amount,
    this.paymentMode = 'Cash',
    String paidTo = '',
    String paidBy = '',
    String title = '',
    this.notes = '',
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        paidTo = title.isNotEmpty ? title : (paidBy.isNotEmpty ? paidBy : paidTo),
        createdAt = createdAt ?? DateTime.now();

  String get title => paidTo.isNotEmpty ? paidTo : category;
  String get paidBy => paidTo;

  String get formattedDate => DateFormat('dd-MM-yyyy').format(date);
  String get isoDate => DateFormat('yyyy-MM-dd').format(date);

  ExpenseModel copyWith({
    int? id,
    DateTime? date,
    String? category,
    double? amount,
    String? paymentMode,
    String? paidTo,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      paidTo: paidTo ?? this.paidTo,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': isoDate,
      'category': category.trim().toUpperCase(),
      'amount': amount,
      'payment_mode': paymentMode.trim(),
      'paid_to': paidTo.trim(),
      'notes': notes.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      final dStr = map['date'] as String? ?? '';
      parsedDate = DateTime.parse(dStr);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime parsedCreated;
    try {
      final cStr = map['created_at'] as String? ?? '';
      parsedCreated = DateTime.parse(cStr);
    } catch (_) {
      parsedCreated = DateTime.now();
    }

    return ExpenseModel(
      id: map['id'] as int?,
      date: parsedDate,
      category: (map['category'] as String? ?? 'OTHER').trim().toUpperCase(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['payment_mode'] as String? ?? 'Cash',
      paidTo: map['paid_to'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: parsedCreated,
    );
  }
}

class ExpenseCategories {
  static const List<String> all = SettingsModel.defaultExpenseCategories;

  static const Map<String, Map<String, String>> localizedLabels = {
    'LIGHT_BILL': {
      'gu': '💡 લાઇટબિલ / વીજળી',
      'en': '💡 Electricity / Light Bill',
      'hi': '💡 बिजली / लाइट बिल',
    },
    'ELECTRICITY': {
      'gu': '💡 લાઇટબિલ / વીજળી',
      'en': '💡 Electricity / Light Bill',
      'hi': '💡 बिजली / लाइट बिल',
    },
    'RENT': {
      'gu': '🏢 કારખાના ભાડું',
      'en': '🏢 Factory Rent',
      'hi': '🏢 कारखाना किराया',
    },
    'MACHINE_REPAIR': {
      'gu': '⚙️ મશીન રીપેરિંગ & પાર્ટ્સ',
      'en': '⚙️ Machine Repairs & Spares',
      'hi': '⚙️ मशीन मरम्मत & स्पेयर पार्ट्स',
    },
    'REPAIRS_MAINTENANCE': {
      'gu': '⚙️ મશીન રીપેરિંગ & પાર્ટ્સ',
      'en': '⚙️ Machine Repairs & Spares',
      'hi': '⚙️ मशीन मरम्मत & स्पेयर पार्ट्स',
    },
    'NEEDLES_SPARES': {
      'gu': '⚙️ મશીન રીપેરિંગ & પાર્ટ્સ',
      'en': '⚙️ Machine Repairs & Spares',
      'hi': '⚙️ मशीन मरम्मत & स्पेयर पार्ट्स',
    },
    'MACHINE_OIL': {
      'gu': '🛢️ મશીન ઓઇલિંગ (તેલ)',
      'en': '🛢️ Machine Oil & Lubrication',
      'hi': '🛢️ मशीन तेल & लुब्रिकेशन',
    },
    'TEA_SNACKS': {
      'gu': '☕ ચા-પાણી તેમજ બપોરી નાસ્તો',
      'en': '☕ Tea, Water & Snacks',
      'hi': '☕ चाय-पानी एवं नाश्ता',
    },
    'TRANSPORT_TEMPO': {
      'gu': '🚚 ટેમ્પો ભાડું & ટ્રાન્સપોર્ટ',
      'en': '🚚 Tempo Freight & Transport',
      'hi': '🚚 टेंपो भाड़ा & ट्रांसपोर्ट',
    },
    'TRANSPORT': {
      'gu': '🚚 ટેમ્પો ભાડું & ટ્રાન્સપોર્ટ',
      'en': '🚚 Tempo Freight & Transport',
      'hi': '🚚 टेंपो भाड़ा & ट्रांसपोर्ट',
    },
    'PETROL_CONVEYANCE': {
      'gu': '⛽ પેટ્રોલ & ઉઘરાણી ખર્ચ',
      'en': '⛽ Petrol & Collection Conveyance',
      'hi': '⛽ पेट्रोल & वसूली खर्च',
    },
    'BOBBIN_ACCESSORIES': {
      'gu': '🧵 બોબીન & સાધનો (જાડા બોબીન)',
      'en': '🧵 Bobbin & Accessories',
      'hi': '🧵 बॉबिन & उपभोग्य वस्तुएं',
    },
    'THREAD_CUTTING': {
      'gu': '✂️ દોરા કટિંગ & પ્રોસેસિંગ',
      'en': '✂️ Thread Cutting & Processing',
      'hi': '✂️ धागा कटिंग & प्रोसेसिंग',
    },
    'OFFICE_EXPENSE': {
      'gu': '🖨️ ઓફિસ ખર્ચ & પ્રિન્ટિંગ',
      'en': '🖨️ Office Expenses & Printing',
      'hi': '🖨️ कार्यालय खर्च & प्रिंटिंग',
    },
    'COMPUTER_WIFI': {
      'gu': '💻 કોમ્પ્યુટર & વાઇફાઇ / સોફ્ટવેર',
      'en': '💻 Computer, Software & WiFi',
      'hi': '💻 कंप्यूटर, सॉफ्टवेयर & वाईफाई',
    },
    'CURTAINS_COVERS': {
      'gu': '🪟 પડદા & મશીન કવર (મોઝા)',
      'en': '🪟 Curtains & Machine Covers',
      'hi': '🪟 पर्दे & मशीन कवर',
    },
    'WATER_EXPENSE': {
      'gu': '💧 પીવાનું પાણી & પાણી વેરો',
      'en': '💧 Drinking Water & Water Tax',
      'hi': '💧 पीने का पानी & जल कर',
    },
    'IRONING_FOLDING': {
      'gu': '👔 ઇસ્ત્રી & ફોલ્ડિંગ ખર્ચ',
      'en': '👔 Ironing & Folding Cost',
      'hi': '👔 इस्त्री & फोल्डिंग खर्च',
    },
    'ELECTRIC_MAINTENANCE': {
      'gu': '🔌 વીજળી વાયરિંગ મેન્ટેનન્સ',
      'en': '🔌 Electrical Wiring Maintenance',
      'hi': '🔌 विद्युत वायरिंग रखरखाव',
    },
    'CLIENT_HOSPITALITY': {
      'gu': '🤝 ગ્રાહક સેવા & સાચવણી',
      'en': '🤝 Client Hospitality',
      'hi': '🤝 ग्राहक सत्कार खर्च',
    },
    'NEW_MACHINERY': {
      'gu': '🏭 નવી મશીનરી & સાધન',
      'en': '🏭 New Machinery & Equipment',
      'hi': '🏭 नई मशीनरी & उपकरण',
    },
    'PETTY_CASH': {
      'gu': '🪙 અંદરનો પરચૂરણ ખર્ચ',
      'en': '🪙 Petty Cash / Minor Expenses',
      'hi': '🪙 दैनिक फुटकर खर्च',
    },
    'OTHER': {
      'gu': '📦 અન્ય કારખાના ખર્ચ (Other)',
      'en': '📦 Other Factory Expenses',
      'hi': '📦 अन्य कारखाना खर्च',
    },
  };

  static String getLabel(String category, [String lang = 'en']) {
    final upper = category.trim().toUpperCase();
    if (localizedLabels.containsKey(upper)) {
      final map = localizedLabels[upper]!;
      return map[lang] ?? map['en'] ?? format(category);
    }
    return format(category);
  }

  static String format(String category) {
    final upper = category.trim().toUpperCase();
    if (localizedLabels.containsKey(upper)) {
      final map = localizedLabels[upper]!;
      return map['en'] ?? upper.replaceAll('_', ' ');
    }
    return category.trim().replaceAll('_', ' ');
  }
}

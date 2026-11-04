class SettingsModel {
  final String companyName;
  final String operatorName;
  final String currencySymbol;
  final double stitchDivider;
  final List<double> availableRates;
  final List<int> availableHeads;
  final double defaultRate;
  final int defaultHeads;
  final String dateFormat;
  final int autoRefreshIntervalSeconds;
  final bool isDarkMode;
  final String themeColorHex;
  final List<String> employeeRoles;
  final String senderPhone;
  final bool whatsappAutoSend;
  final String whatsappMessageLanguage;
  final String appLanguage; // 'en', 'gu', 'hi' (English default)
  final double fontScale; // 0.85 to 1.30, default 1.0

  static const List<String> defaultRoles = [
    'OPERATOR',
    'MASTER',
    'KARIGAR',
    'HELPER',
    'DESIGNER',
    'CHECKER',
    'MANAGER',
    'OTHER',
  ];

  SettingsModel({
    this.companyName = 'OM MAVTAR GROUP',
    this.operatorName = 'Single User',
    this.currencySymbol = '₹',
    this.stitchDivider = 1000.0,
    this.availableRates = const [1.00, 1.25, 1.50, 1.75, 2.00],
    this.availableHeads = const [6, 8, 10, 12, 14, 15, 16, 18, 20],
    this.defaultRate = 1.25,
    this.defaultHeads = 12,
    this.dateFormat = 'dd-MM-yyyy',
    this.autoRefreshIntervalSeconds = 120,
    this.isDarkMode = false,
    this.themeColorHex = '#0066FF',
    this.employeeRoles = defaultRoles,
    this.senderPhone = '',
    this.whatsappAutoSend = false,
    this.whatsappMessageLanguage = 'English',
    this.appLanguage = 'en',
    this.fontScale = 1.0,
  });

  SettingsModel copyWith({
    String? companyName,
    String? operatorName,
    String? currencySymbol,
    double? stitchDivider,
    List<double>? availableRates,
    List<int>? availableHeads,
    double? defaultRate,
    int? defaultHeads,
    String? dateFormat,
    int? autoRefreshIntervalSeconds,
    bool? isDarkMode,
    String? themeColorHex,
    List<String>? employeeRoles,
    String? senderPhone,
    bool? whatsappAutoSend,
    String? whatsappMessageLanguage,
    String? appLanguage,
    double? fontScale,
  }) {
    return SettingsModel(
      companyName: companyName ?? this.companyName,
      operatorName: operatorName ?? this.operatorName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      stitchDivider: stitchDivider ?? this.stitchDivider,
      availableRates: availableRates ?? this.availableRates,
      availableHeads: availableHeads ?? this.availableHeads,
      defaultRate: defaultRate ?? this.defaultRate,
      defaultHeads: defaultHeads ?? this.defaultHeads,
      dateFormat: dateFormat ?? this.dateFormat,
      autoRefreshIntervalSeconds: autoRefreshIntervalSeconds ?? this.autoRefreshIntervalSeconds,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      themeColorHex: themeColorHex ?? this.themeColorHex,
      employeeRoles: employeeRoles != null
          ? employeeRoles.map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toSet().toList()
          : this.employeeRoles,
      senderPhone: senderPhone ?? this.senderPhone,
      whatsappAutoSend: whatsappAutoSend ?? this.whatsappAutoSend,
      whatsappMessageLanguage: whatsappMessageLanguage ?? this.whatsappMessageLanguage,
      appLanguage: appLanguage ?? this.appLanguage,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company_name': companyName,
      'operator_name': operatorName,
      'currency_symbol': currencySymbol,
      'stitch_divider': stitchDivider,
      'available_rates': availableRates.join(','),
      'available_heads': availableHeads.join(','),
      'default_rate': defaultRate,
      'default_heads': defaultHeads,
      'date_format': dateFormat,
      'auto_refresh_seconds': autoRefreshIntervalSeconds,
      'is_dark_mode': isDarkMode ? 1 : 0,
      'theme_color_hex': themeColorHex,
      'employee_roles': employeeRoles.join(','),
      'sender_phone': senderPhone,
      'whatsapp_auto_send': whatsappAutoSend ? 1 : 0,
      'whatsapp_message_language': whatsappMessageLanguage,
      'app_language': appLanguage,
      'font_scale': fontScale,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    List<double> parseRates(dynamic val) {
      if (val is String && val.isNotEmpty) {
        return val.split(',').map((e) => double.tryParse(e.trim()) ?? 1.25).toList();
      }
      return const [1.00, 1.25, 1.50, 1.75, 2.00];
    }

    List<int> parseHeads(dynamic val) {
      if (val is String && val.isNotEmpty) {
        return val.split(',').map((e) => int.tryParse(e.trim()) ?? 12).toList();
      }
      return const [6, 8, 10, 12, 14, 15, 16, 18, 20];
    }

    List<String> parseRoles(dynamic val) {
      if (val is String && val.trim().isNotEmpty) {
        final list = val
            .split(',')
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
        if (list.isNotEmpty) return list;
      }
      return SettingsModel.defaultRoles;
    }

    return SettingsModel(
      companyName: map['company_name'] as String? ?? 'OM MAVTAR GROUP',
      operatorName: map['operator_name'] as String? ?? 'Single User',
      currencySymbol: map['currency_symbol'] as String? ?? '₹',
      stitchDivider: (map['stitch_divider'] as num?)?.toDouble() ?? 1000.0,
      availableRates: parseRates(map['available_rates']),
      availableHeads: parseHeads(map['available_heads']),
      defaultRate: (map['default_rate'] as num?)?.toDouble() ?? 1.25,
      defaultHeads: (map['default_heads'] as num?)?.toInt() ?? 12,
      dateFormat: map['date_format'] as String? ?? 'dd-MM-yyyy',
      autoRefreshIntervalSeconds: (map['auto_refresh_seconds'] as num?)?.toInt() ?? 120,
      isDarkMode: (map['is_dark_mode'] as num?)?.toInt() == 1,
      themeColorHex: map['theme_color_hex'] as String? ?? '#0066FF',
      employeeRoles: parseRoles(map['employee_roles']),
      senderPhone: map['sender_phone'] as String? ?? '',
      whatsappAutoSend: (map['whatsapp_auto_send'] as num?)?.toInt() == 1,
      whatsappMessageLanguage: () {
        final wLang = map['whatsapp_message_language'] as String?;
        if (wLang == null || wLang.isEmpty || wLang.toLowerCase() == 'both') {
          return 'English';
        }
        return wLang;
      }(),
      appLanguage: () {
        final lang = map['app_language'] as String? ?? 'en';
        if (lang == 'en_gu' || lang == 'en_hi' || lang.isEmpty) {
          return 'en';
        }
        return lang;
      }(),
      fontScale: (map['font_scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class LanguageRegionPrefs {
  const LanguageRegionPrefs({
    required this.language,
    required this.currency,
    required this.timezone,
    required this.dateFormat,
  });

  final String language; // English/Sinhala/Tamil/...
  final String currency; // LKR/INR/USD/...
  final String timezone; // e.g. Asia/Colombo (UTC+5:30)
  final String dateFormat; // DD/MM/YYYY, MM/DD/YYYY, YYYY-MM-DD

  static const defaults = LanguageRegionPrefs(
    language: 'English',
    currency: 'LKR',
    timezone: 'Asia/Colombo (UTC+5:30)',
    dateFormat: 'DD/MM/YYYY',
  );

  LanguageRegionPrefs copyWith({
    String? language,
    String? currency,
    String? timezone,
    String? dateFormat,
  }) {
    return LanguageRegionPrefs(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }

  static LanguageRegionPrefs fromMap(Map<String, dynamic>? d) {
    final m = d ?? const <String, dynamic>{};
    return LanguageRegionPrefs(
      language: (m['language'] ?? defaults.language).toString(),
      currency: (m['currency'] ?? defaults.currency).toString(),
      timezone: (m['timezone'] ?? defaults.timezone).toString(),
      dateFormat: (m['date_format'] ?? defaults.dateFormat).toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'currency': currency,
      'timezone': timezone,
      'date_format': dateFormat,
    };
  }
}


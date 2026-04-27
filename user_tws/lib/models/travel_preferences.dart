class TravelPreferences {
  const TravelPreferences({
    required this.interests,
    required this.budgetRange,
    required this.tripDuration,
  });

  /// e.g. Cultural/Food/Beach
  final List<String> interests;

  /// Budget | Mid-Range | Luxury
  final String budgetRange;

  /// Day Trip | Weekend | Week+
  final String tripDuration;

  static const defaults = TravelPreferences(
    interests: <String>[],
    budgetRange: 'Mid-Range',
    tripDuration: 'Weekend',
  );

  TravelPreferences copyWith({
    List<String>? interests,
    String? budgetRange,
    String? tripDuration,
  }) {
    return TravelPreferences(
      interests: interests ?? this.interests,
      budgetRange: budgetRange ?? this.budgetRange,
      tripDuration: tripDuration ?? this.tripDuration,
    );
  }

  static TravelPreferences fromMap(Map<String, dynamic>? d) {
    final m = d ?? const <String, dynamic>{};
    final raw = m['interests'];
    final interests = raw is List
        ? raw.map((x) => x.toString()).where((x) => x.trim().isNotEmpty).toList()
        : <String>[];
    final budget = (m['budget_range'] ?? defaults.budgetRange).toString();
    final duration = (m['trip_duration'] ?? defaults.tripDuration).toString();
    return TravelPreferences(
      interests: interests,
      budgetRange: budget,
      tripDuration: duration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'interests': interests,
      'budget_range': budgetRange,
      'trip_duration': tripDuration,
    };
  }
}


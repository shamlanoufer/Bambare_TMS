class NotificationPrefs {
  const NotificationPrefs({
    required this.bookingUpdates,
    required this.specialOffers,
    required this.tripReminders,
    required this.nearbyPlaces,
    required this.reviewRequests,
    required this.newsletter,
  });

  final bool bookingUpdates;
  final bool specialOffers;
  final bool tripReminders;
  final bool nearbyPlaces;
  final bool reviewRequests;
  final bool newsletter;

  static const defaults = NotificationPrefs(
    bookingUpdates: true,
    specialOffers: true,
    tripReminders: true,
    nearbyPlaces: true,
    reviewRequests: true,
    newsletter: true,
  );

  NotificationPrefs copyWith({
    bool? bookingUpdates,
    bool? specialOffers,
    bool? tripReminders,
    bool? nearbyPlaces,
    bool? reviewRequests,
    bool? newsletter,
  }) {
    return NotificationPrefs(
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      specialOffers: specialOffers ?? this.specialOffers,
      tripReminders: tripReminders ?? this.tripReminders,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      reviewRequests: reviewRequests ?? this.reviewRequests,
      newsletter: newsletter ?? this.newsletter,
    );
  }

  static NotificationPrefs fromMap(Map<String, dynamic>? d) {
    final m = d ?? const <String, dynamic>{};
    bool b(String k, bool def) => (m[k] is bool) ? m[k] as bool : def;
    return NotificationPrefs(
      bookingUpdates: b('booking_updates', defaults.bookingUpdates),
      specialOffers: b('special_offers', defaults.specialOffers),
      tripReminders: b('trip_reminders', defaults.tripReminders),
      nearbyPlaces: b('nearby_places', defaults.nearbyPlaces),
      reviewRequests: b('review_requests', defaults.reviewRequests),
      newsletter: b('newsletter', defaults.newsletter),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking_updates': bookingUpdates,
      'special_offers': specialOffers,
      'trip_reminders': tripReminders,
      'nearby_places': nearbyPlaces,
      'review_requests': reviewRequests,
      'newsletter': newsletter,
    };
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

/// Where this tour appears in the user app (admin Publish step).
/// If the document has **no** `visibility` map, legacy rules apply so older data still works.
class TourVisibility {
  const TourVisibility._({
    required this.hasExplicitMap,
    required this.homeFeatures,
    required this.activityHiking,
    required this.activityCycling,
    required this.activityTrekking,
    required this.activityTukTukRide,
    required this.activityJeep,
    required this.activityCookery,
    required this.bookingPopular,
    required this.bookingSeeAll,
    required this.environmentCultural,
    required this.environmentBeach,
    required this.environmentWildlife,
    required this.environmentMountain,
    required this.environmentFood,
  });

  /// Firestore contained a `visibility` object (may be empty).
  final bool hasExplicitMap;
  final bool homeFeatures;
  final bool activityHiking;
  final bool activityCycling;
  final bool activityTrekking;
  final bool activityTukTukRide;
  final bool activityJeep;
  final bool activityCookery;
  final bool bookingPopular;
  final bool bookingSeeAll;
  final bool environmentCultural;
  final bool environmentBeach;
  final bool environmentWildlife;
  final bool environmentMountain;
  final bool environmentFood;

  static TourVisibility fromDoc(Map<String, dynamic> d) {
    final raw = d['visibility'];
    final cat = (d['category'] as String? ?? '').toLowerCase();
    if (raw is! Map) {
      final feat = d['featured'] as bool? ?? false;
      return TourVisibility._(
        hasExplicitMap: false,
        homeFeatures: false,
        activityHiking: false,
        activityCycling: false,
        activityTrekking: false,
        activityTukTukRide: false,
        activityJeep: false,
        activityCookery: false,
        bookingPopular: feat,
        bookingSeeAll: true,
        environmentCultural: cat == 'cultural',
        environmentBeach: cat == 'beach',
        environmentWildlife: cat == 'wildlife',
        environmentMountain: cat == 'mountain',
        environmentFood: cat == 'food',
      );
    }
    final m = Map<String, dynamic>.from(raw);
    bool g(String k) => m[k] == true;
    return TourVisibility._(
      hasExplicitMap: true,
      homeFeatures: g('home_features'),
      activityHiking: g('activity_hiking'),
      activityCycling: g('activity_cycling'),
      activityTrekking: g('activity_trekking'),
      activityTukTukRide: g('activity_tuk_tuk_ride'),
      activityJeep: g('activity_jeep'),
      activityCookery: g('activity_cookery'),
      bookingPopular: g('booking_popular'),
      bookingSeeAll: g('booking_see_all'),
      environmentCultural: g('environment_cultural'),
      environmentBeach: g('environment_beach'),
      environmentWildlife: g('environment_wildlife'),
      environmentMountain: g('environment_mountain'),
      environmentFood: g('environment_food'),
    );
  }

  bool matchesDiscoverCategory(String selected) {
    final c = selected.toLowerCase();
    if (c == 'all') return true;
    if (environmentCultural && c == 'cultural') return true;
    if (environmentBeach && c == 'beach') return true;
    if (environmentWildlife && c == 'wildlife') return true;
    if (environmentMountain && c == 'mountain') return true;
    if (environmentFood && c == 'food') return true;
    return false;
  }
}

/// Optional map / route block edited from admin `map_config`.
class TourMapInfo {
  const TourMapInfo({
    required this.centerLat,
    required this.centerLng,
    required this.statDistance,
    required this.statDrive,
    required this.statPeak,
    required this.statRoute,
    required this.stops,
  });

  final double centerLat;
  final double centerLng;
  final String statDistance;
  final String statDrive;
  final String statPeak;
  final String statRoute;
  final List<Map<String, dynamic>> stops;

  static TourMapInfo? tryParse(Map<String, dynamic>? d) {
    if (d == null) return null;
    final lat = (d['center_lat'] as num?)?.toDouble();
    final lng = (d['center_lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    final raw = d['stops'];
    final stops = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) stops.add(Map<String, dynamic>.from(e));
      }
    }
    return TourMapInfo(
      centerLat: lat,
      centerLng: lng,
      statDistance: d['stat_distance'] as String? ?? '',
      statDrive: d['stat_drive'] as String? ?? '',
      statPeak: d['stat_peak'] as String? ?? '',
      statRoute: d['stat_route'] as String? ?? '',
      stops: stops,
    );
  }
}

/// Tour document from Firestore `tours` collection (seed + admin).
class Tour {
  const Tour({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.category,
    required this.price,
    required this.currency,
    required this.locationLabel,
    required this.featured,
    required this.featuredRank,
    required this.sortOrder,
    this.overviewBody,
    this.inclusions = const [],
    this.exclusions = const [],
    this.galleryUrls = const [],
    this.itineraryDays = const [],
    this.weatherNote,
    this.maxCapacity = 12,
    this.mapInfo,
    required this.visibility,
    this.reviewMarketingGalleryUrls = const [],
    this.reviewDisplayCount,
    this.itineraryTabImageUrl,
    this.reviewTabImageUrl,
    this.mapTabImageUrl,
    this.overviewBackgroundImageUrl,
  });

  final String id;
  final String title;
  final String imageUrl;
  final double rating;
  final String category;
  final double price;
  final String currency;
  final String locationLabel;
  final bool featured;
  final int featuredRank;
  final int sortOrder;

  /// Long overview copy (mobile Overview tab).
  final String? overviewBody;
  final List<String> inclusions;
  final List<String> exclusions;
  final List<String> galleryUrls;
  final List<Map<String, dynamic>> itineraryDays;
  final String? weatherNote;
  final int maxCapacity;
  final TourMapInfo? mapInfo;
  final TourVisibility visibility;
  final List<String> reviewMarketingGalleryUrls;
  final int? reviewDisplayCount;

  /// Optional hero when user opens the **Itinerary** tab (falls back to [imageUrl]).
  final String? itineraryTabImageUrl;

  /// Optional hero when user opens the **Review** tab (falls back to [imageUrl]).
  final String? reviewTabImageUrl;

  /// Optional hero when user opens the **Map** tab (falls back to [imageUrl]).
  final String? mapTabImageUrl;

  /// Optional full-bleed background on the mobile **Overview** tab only.
  final String? overviewBackgroundImageUrl;

  String get ratingLabel => rating.toStringAsFixed(1);

  String get formattedPrice => '$currency ${_commaFormat(price.round())}';

  factory Tour.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final title =
        (d['title'] as String? ?? d['tourName'] as String? ?? '').trim();
    final price = (d['price'] as num?)?.toDouble() ??
        (d['basePrice'] as num?)?.toDouble() ??
        0;
    return Tour(
      id: doc.id,
      title: title,
      imageUrl: (d['image_url'] as String? ?? '').trim(),
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      category: (d['category'] as String? ?? '').trim(),
      price: price,
      currency: d['currency'] as String? ?? 'LKR',
      locationLabel: (d['location'] as String? ?? '').trim(),
      featured: d['featured'] as bool? ?? false,
      featuredRank: (d['featured_rank'] as num?)?.toInt() ?? 0,
      sortOrder: (d['sort_order'] as num?)?.toInt() ?? 0,
      overviewBody: d['overview_body'] as String?,
      inclusions: _stringList(d['inclusions']),
      exclusions: _stringList(d['exclusions']),
      galleryUrls: _stringList(d['gallery_urls']),
      itineraryDays: _itineraryDays(d['itinerary_days']),
      weatherNote: d['weather_note'] as String?,
      maxCapacity: (d['maxCapacity'] as num?)?.toInt() ??
          (d['max_capacity'] as num?)?.toInt() ??
          12,
      mapInfo: TourMapInfo.tryParse(
        d['map_config'] is Map
            ? Map<String, dynamic>.from(d['map_config'] as Map)
            : null,
      ),
      visibility: TourVisibility.fromDoc(d),
      reviewMarketingGalleryUrls: _stringList(d['review_marketing_gallery_urls']),
      reviewDisplayCount: (d['review_display_count'] as num?)?.toInt(),
      itineraryTabImageUrl: _optionalUrl(d['itinerary_tab_image_url']),
      reviewTabImageUrl: _optionalUrl(d['review_tab_image_url']),
      mapTabImageUrl: _optionalUrl(
        d['map_tab_image_url'] ??
            (d['map_config'] is Map
                ? (d['map_config'] as Map)['tab_image_url']
                : null),
      ),
      overviewBackgroundImageUrl:
          _optionalUrl(d['overview_background_image_url']),
    );
  }

  static String? _optionalUrl(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e?.toString().trim() ?? '').where((s) => s.isNotEmpty).toList();
  }

  static List<Map<String, dynamic>> _itineraryDays(dynamic v) {
    if (v is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final day in v) {
      if (day is! Map) continue;
      final dm = Map<String, dynamic>.from(day);
      final ev = dm['events'];
      if (ev is List) {
        dm['events'] = ev
            .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .toList();
      } else {
        dm['events'] = <Map<String, dynamic>>[];
      }
      out.add(dm);
    }
    return out;
  }

  static String _commaFormat(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

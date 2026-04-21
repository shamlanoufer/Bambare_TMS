import 'package:cloud_firestore/cloud_firestore.dart';

/// Tour document in `tours` — admin-managed in Firestore.
///
/// Fields: `title`, `image_url`, `rating`, `category`, `price`, `currency`,
/// optional `location`, `sort_order` (int, lower first), `published` (bool, default true),
/// `featured` + `featured_rank` (home “Popular Tours”; admin-controlled).
class Tour {
  const Tour({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.category,
    required this.price,
    required this.currency,
    this.location,
    this.sortOrder = 0,
    this.published = true,
    this.featured = false,
    this.featuredRank = 0,
  });

  final String id;
  final String title;
  final String imageUrl;
  final double rating;
  final String category;
  final double price;
  final String currency;
  /// From Firestore `location` — admin-set; not editable in the app.
  final String? location;
  final int sortOrder;
  final bool published;
  final bool featured;
  /// Order on home popular row (1, 2, 3…). 0 = not used for ordering.
  final int featuredRank;

  /// Shown in lists; uses [location] when set, else a title-based guess.
  String get locationLabel {
    final l = location?.trim();
    if (l != null && l.isNotEmpty) return l;
    return _inferLocationFromTitle(title);
  }

  static String _inferLocationFromTitle(String title) {
    if (title.contains('Sigiriya')) return 'Dabulla';
    if (title.contains('Yala')) return 'Yala';
    if (title.contains('Mirissa')) return 'Mirissa';
    if (title.contains('Ella')) return 'Ella';
    if (title.contains('Marble')) return 'Trincomalee';
    if (title.contains('Piduruthalagala')) return 'Piduruthalagala';
    if (title.contains('Kandy')) return 'Kandy';
    if (title.contains('Udunuwara')) return 'Udunuwara';
    return 'Kandy';
  }

  factory Tour.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    return Tour(
      id: doc.id,
      title: (d['title'] as String?)?.trim() ?? '',
      imageUrl: (d['image_url'] as String?)?.trim() ?? '',
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      category: (d['category'] as String? ?? 'CULTURAL').trim().toUpperCase(),
      price: (d['price'] as num?)?.toDouble() ?? 0,
      currency: (d['currency'] as String?)?.trim().toUpperCase() ?? 'LKR',
      location: (d['location'] as String?)?.trim(),
      sortOrder: (d['sort_order'] as num?)?.toInt() ?? 0,
      published: d['published'] as bool? ?? true,
      featured: d['featured'] as bool? ?? false,
      featuredRank: (d['featured_rank'] as num?)?.toInt() ?? 0,
    );
  }

  String get ratingLabel {
    if (rating == rating.roundToDouble()) {
      return rating.toStringAsFixed(0);
    }
    return rating.toStringAsFixed(1);
  }

  String get formattedPrice {
    final p = price.round();
    final s = p.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      if (i > 0 && fromEnd % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$currency $buf';
  }
}

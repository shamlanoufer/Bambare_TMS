import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tour.dart';

/// Reads collection `tours`. Configure public **read** in Firestore rules so the
/// app can load data; writes stay in Firebase Console / admin / Cloud Functions.
///
/// Example document fields:
/// `title`, `image_url` (https or `images/foo.png` asset path), `rating`, `category`,
/// `price`, `currency`, `sort_order`, `published`, optional `featured`, `featured_rank`.
class TourService {
  TourService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Live list of published tours, sorted by `sort_order` then title.
  Stream<List<Tour>> popularToursStream() {
    return _db.collection('tours').snapshots().map((snap) {
      final list = snap.docs
          .map(Tour.fromFirestore)
          .where((t) => t.published && t.title.isNotEmpty)
          .toList();
      list.sort((a, b) {
        final o = a.sortOrder.compareTo(b.sortOrder);
        if (o != 0) return o;
        return a.title.compareTo(b.title);
      });
      return list;
    });
  }

  /// Home “Popular Tours”: `featured == true`, ordered by `featured_rank` then `sort_order`.
  Stream<List<Tour>> featuredToursStream() {
    return popularToursStream().map((list) {
      final featured = list.where((t) => t.featured).toList();
      if (featured.isEmpty) {
        return list.take(3).toList();
      }
      featured.sort((a, b) {
        final ar = a.featuredRank;
        final br = b.featuredRank;
        if (ar != 0 && br != 0 && ar != br) {
          return ar.compareTo(br);
        }
        if (ar != 0 && br == 0) return -1;
        if (ar == 0 && br != 0) return 1;
        final o = a.sortOrder.compareTo(b.sortOrder);
        if (o != 0) return o;
        return a.title.compareTo(b.title);
      });
      return featured;
    });
  }
}

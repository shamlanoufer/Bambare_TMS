import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tour.dart';

class TourService {
  TourService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

<<<<<<< HEAD
  Future<Tour?> fetchTourById(String tourId) async {
    final id = tourId.trim();
    if (id.isEmpty) return null;
    final snap = await _db.collection('tours').doc(id).get();
    if (!snap.exists) return null;
    return Tour.fromFirestore(snap);
  }

=======
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
  /// Discover / "See all" full catalog: every **published** tour (no placement filter).
  /// Use this for the booking Explore → See all screen so **All** shows admin-added packages.
  Stream<List<Tour>> allPublishedToursStream() {
    return _db
        .collection('tours')
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Tour.fromFirestore).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  /// Legacy: tours flagged for the old "See all" placement only [Tour.visibility.bookingSeeAll].
  Stream<List<Tour>> popularToursStream() {
    return _db
        .collection('tours')
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(Tour.fromFirestore)
          .where((t) => t.visibility.bookingSeeAll)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  /// Explore dashboard "Popular Tours": [Tour.visibility.bookingPopular].
  Stream<List<Tour>> featuredToursStream() {
    return _db
        .collection('tours')
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final featured = snap.docs
          .map(Tour.fromFirestore)
          .where((t) => t.visibility.bookingPopular)
          .toList()
        ..sort((a, b) => a.featuredRank.compareTo(b.featuredRank));
      return featured;
    });
  }

  /// Home horizontal "Featured Tours" strip: [Tour.visibility.homeFeatures].
  Stream<List<Tour>> homeFeaturesToursStream() {
    return _db
        .collection('tours')
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(Tour.fromFirestore)
          .where((t) => t.visibility.homeFeatures)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  /// Home activity detail — tours tagged for that activity (`activity_*` flags).
  Stream<List<Tour>> toursForActivityId(String activityId) {
    return _db
        .collection('tours')
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(Tour.fromFirestore)
          .where((t) => _tourMatchesActivity(t, activityId))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    });
  }

  static bool _tourMatchesActivity(Tour t, String activityId) {
    switch (activityId) {
      case 'hiking':
        return t.visibility.activityHiking;
      case 'cycling':
        return t.visibility.activityCycling;
      case 'trekking':
        return t.visibility.activityTrekking;
      case 'tuk_tuk':
        return t.visibility.activityTukTukRide;
      case 'jeep':
        return t.visibility.activityJeep;
      case 'cookery':
        return t.visibility.activityCookery;
      default:
        return false;
    }
  }
}

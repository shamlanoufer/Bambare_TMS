import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tour.dart';

class MapReportsService {
  MapReportsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection('public_stats').doc('map_reports');

  static const _categoryKeys = <String>[
    'Cultural',
    'Beach',
    'Wildlife',
    'Mountain',
    'Food',
  ];

  /// Parses `public_stats/map_reports` nested map fields into tourId -> count.
  static Map<String, int> _tourTotalsFromField(dynamic raw) {
    final out = <String, int>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        final k = e.key?.toString();
        final v = e.value;
        if (k == null || k.trim().isEmpty) continue;
        if (v is num) out[k] = v.toInt();
      }
    }
    return out;
  }

  static Map<String, int> _mergeTourMaps(Map<String, int> a, Map<String, int> b) {
    final out = Map<String, int>.from(a);
    for (final e in b.entries) {
      out[e.key] = (out[e.key] ?? 0) + e.value;
    }
    return out;
  }

  static bool _mapHasPositiveCount(Map<String, int> m) => m.values.any((v) => v > 0);

  static bool _isCancelledStatus(String s) {
    final x = s.trim().toLowerCase();
    return x == 'cancelled' || x == 'canceled';
  }

  /// Accepts common variants/typos like "copmpled".
  static bool _isCompletedStatus(String s) {
    final x = s.trim().toLowerCase();
    if (x == 'completed') return true;
    return x.contains('complete');
  }

  /// Category visit bars: merges legacy buckets written at booking time.
  /// Uses `completed_visits_by_category` rebuilt from bookings where `status == Completed`.
  Stream<Map<String, int>> completedVisitsByCategoryStream() {
    return _doc.snapshots().map((snap) {
      final d = snap.data() ?? const <String, dynamic>{};
      final completedRaw = d['completed_visits_by_category'];
      final legacyRaw = d['visits_by_category'];
      final out = <String, int>{
        for (final k in _categoryKeys) k: 0,
      };
      void apply(Map<String, int> target, dynamic raw) {
        if (raw is! Map) return;
        for (final k in _categoryKeys) {
          final v = raw[k];
          if (v is num) target[k] = (target[k] ?? 0) + v.toInt();
        }
      }
      apply(out, completedRaw);
      // Fallback for accounts that have confirmed bookings but no completed bookings yet.
      final hasCompletedCounts = out.values.any((v) => v > 0);
      if (!hasCompletedCounts) {
        apply(out, legacyRaw);
      }
      return out;
    });
  }

  /// Per-tour booking counts for ranking / gems.
  /// Uses `completed_tour_bookings_total` (bookings where `status == Completed`).
  Stream<Map<String, int>> completedTourBookingsTotalStream() {
    return _doc.snapshots().map((snap) {
      final d = snap.data() ?? const <String, dynamic>{};
      final completed = _tourTotalsFromField(d['completed_tour_bookings_total']);
      if (_mapHasPositiveCount(completed)) return completed;
      // Fallback for older/non-completed datasets so rankings are still meaningful.
      return _tourTotalsFromField(d['all_tour_bookings_total']);
    });
  }

  /// Raw next-7-days counters (no merge). Prefer [trendingTourBookingsTotalStream] for UI.
  Stream<Map<String, int>> upcomingWeekTourBookingsTotalStream() {
    return _doc.snapshots().map((snap) {
      final d = snap.data() ?? const <String, dynamic>{};
      return _tourTotalsFromField(d['upcoming_week_tour_bookings_total']);
    });
  }

  /// Trending list: next-7-days totals from `upcoming_week_tour_bookings_total`.
  Stream<Map<String, int>> trendingTourBookingsTotalStream() {
    return _doc.snapshots().map((snap) {
      final d = snap.data() ?? const <String, dynamic>{};
      return _tourTotalsFromField(d['upcoming_week_tour_bookings_total']);
    });
  }

  /// Same gate as [backfillVisitsFromBookingsIfAdmin] / Firestore rules.
  Future<bool> currentUserIsMapReportsAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final adminSnap = await _db.collection('admins').doc(uid).get();
    final adminData = adminSnap.data();
    if (adminData == null) return false;
    if ((adminData['role'] as String?) != 'admin') return false;
    if (adminData['active'] == false) return false;
    return true;
  }

  /// Rebuilds `public_stats/map_reports` from the `bookings` collection.
  /// Returns a short message for UI, or `null` if the user is not an active admin.
  Future<String?> syncMapReportsFromBookingsIfAdmin() async {
    final ok = await currentUserIsMapReportsAdmin();
    if (!ok) return null;

    return _runBackfillBody();
  }

  /// Fire-and-forget on screen open (admin only).
  Future<void> backfillVisitsFromBookingsIfAdmin() async {
    final ok = await currentUserIsMapReportsAdmin();
    if (!ok) return;
    await _runBackfillBody();
  }

  Future<String> _runBackfillBody() async {

    final existing = await _doc.get();
    final d = existing.data() ?? const <String, dynamic>{};
    final alreadyBackfilled = d['backfilled_from_bookings'] == true;
    final allExisting = _tourTotalsFromField(d['all_tour_bookings_total']);

    // Full backfill only once; if an older backfill omitted [all_tour_bookings_total], merge it.
    if (alreadyBackfilled && _mapHasPositiveCount(allExisting)) {
      return 'Map stats already include booking totals.';
    }

    final bookings = await _db.collection('bookings').get();

    if (alreadyBackfilled) {
      final tourTotalsAll = <String, int>{};
      for (final doc in bookings.docs) {
        final bd = doc.data();
        final status = (bd['status'] as String? ?? '').toLowerCase();
        if (status == 'cancelled' || status == 'canceled') continue;
        final tid = ((bd['tour_id'] ?? bd['tourId']) as String? ?? '').trim();
        if (tid.isEmpty) continue;
        tourTotalsAll[tid] = (tourTotalsAll[tid] ?? 0) + 1;
      }
      await _doc.set(
        {'all_tour_bookings_total': tourTotalsAll},
        SetOptions(merge: true),
      );
      return 'Merged all-time booking counts for ${tourTotalsAll.length} tours.';
    }

    final outCompleted = <String, int>{
      'Cultural': 0,
      'Beach': 0,
      'Wildlife': 0,
      'Mountain': 0,
      'Food': 0,
    };
    final tourTotalsCompleted = <String, int>{};
    final tourTotalsUpcomingWeek = <String, int>{};
    final tourTotalsAll = <String, int>{};
    final tourIds = <String>{};
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final endUpcomingWeek = startToday.add(const Duration(days: 7));
    for (final doc in bookings.docs) {
      final bd = doc.data();
      final status = (bd['status'] as String? ?? '').toLowerCase();
      if (_isCancelledStatus(status)) continue;
      final isCompletedStatus = _isCompletedStatus(status);
      final tid = ((bd['tour_id'] ?? bd['tourId']) as String? ?? '').trim();
      if (tid.isNotEmpty) tourIds.add(tid);
      if (tid.isEmpty) continue;
      tourTotalsAll[tid] = (tourTotalsAll[tid] ?? 0) + 1;
      final travelTs = bd['travel_date'] ?? bd['travelDate'];
      DateTime travel = DateTime.fromMillisecondsSinceEpoch(0);
      if (travelTs is Timestamp) travel = travelTs.toDate();
      final travelDay = DateTime(travel.year, travel.month, travel.day);
      final upcomingWeek = !isCompletedStatus &&
          !travelDay.isBefore(startToday) &&
          !travelDay.isAfter(endUpcomingWeek);
      if (isCompletedStatus) {
        tourTotalsCompleted[tid] = (tourTotalsCompleted[tid] ?? 0) + 1;
      }
      if (upcomingWeek) {
        tourTotalsUpcomingWeek[tid] = (tourTotalsUpcomingWeek[tid] ?? 0) + 1;
      }
    }

    // Load tours in chunks (whereIn limit).
    final ids = tourIds.toList();
    final tourById = <String, Map<String, dynamic>>{};
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
      final snap = await _db.collection('tours').where(FieldPath.documentId, whereIn: chunk).get();
      for (final t in snap.docs) {
        tourById[t.id] = t.data();
      }
    }

    // Count COMPLETED bookings per category by checking tour visibility flags (fallback to category string).
    for (final doc in bookings.docs) {
      final bd = doc.data();
      final status = (bd['status'] as String? ?? '').toLowerCase();
      if (_isCancelledStatus(status)) continue;
      if (!_isCompletedStatus(status)) continue;
      final tid = ((bd['tour_id'] ?? bd['tourId']) as String? ?? '').trim();
      if (tid.isEmpty) continue;
      final td = tourById[tid] ?? const <String, dynamic>{};
      final tv = TourVisibility.fromDoc(td);

      var bumped = false;

      void bump(String k) {
        outCompleted[k] = (outCompleted[k] ?? 0) + 1;
        bumped = true;
      }

      if (tv.environmentCultural) bump('Cultural');
      if (tv.environmentBeach) bump('Beach');
      if (tv.environmentWildlife) bump('Wildlife');
      if (tv.environmentMountain) bump('Mountain');
      if (tv.environmentFood) bump('Food');

      if (!bumped) {
        final cat = (td['category'] as String? ?? '').trim().toLowerCase();
        switch (cat) {
          case 'cultural':
            bump('Cultural');
            break;
          case 'beach':
            bump('Beach');
            break;
          case 'wildlife':
            bump('Wildlife');
            break;
          case 'mountain':
            bump('Mountain');
            break;
          case 'food':
            bump('Food');
            break;
        }
      }
    }

    await _doc.set(
      {
        'completed_visits_by_category': outCompleted,
        'all_tour_bookings_total': tourTotalsAll,
        'completed_tour_bookings_total': tourTotalsCompleted,
        'upcoming_week_tour_bookings_total': tourTotalsUpcomingWeek,
        'backfilled_from_bookings': true,
        'backfilled_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return 'Synced map stats from ${bookings.docs.length} booking documents.';
  }
}


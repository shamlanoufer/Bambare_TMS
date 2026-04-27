import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/tour.dart';

class BookingService {
  BookingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final Set<String> _autoCompletedIds = <String>{};

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  DocumentReference<Map<String, dynamic>> get _mapReports =>
      _db.collection('public_stats').doc('map_reports');

  Future<void> _incrementVisitCategoryForTour(String tourId, {required bool completed}) async {
    // Read the tour category/visibility once to know which bucket to increment.
    final tourSnap = await _db.collection('tours').doc(tourId).get();
    final d = tourSnap.data() ?? const <String, dynamic>{};

    // Same rules as discover / [TourVisibility.fromDoc] so stats match how tours are tagged.
    final tv = TourVisibility.fromDoc(d);

    final inc = <String, FieldValue>{};

    void bump(String key) {
      final base = completed ? 'completed_visits_by_category' : 'visits_by_category';
      inc['$base.$key'] = FieldValue.increment(1);
    }

    if (tv.environmentCultural) bump('Cultural');
    if (tv.environmentBeach) bump('Beach');
    if (tv.environmentWildlife) bump('Wildlife');
    if (tv.environmentMountain) bump('Mountain');
    if (tv.environmentFood) bump('Food');

    if (inc.isEmpty) {
      final cat = (d['category'] as String? ?? '').trim().toLowerCase();
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

    if (inc.isEmpty) return;

    // Merge so the doc can be created lazily.
    await _mapReports.set(inc, SetOptions(merge: true));
  }

  Future<void> _incrementTourBookingTotal(String tourId, {required bool completed, required bool upcomingWeek}) async {
    // Always count the booking per tour so ranking / gems / trends are not empty
    // when travel is more than 7 days away (legacy logic skipped both buckets).
    final updates = <String, FieldValue>{
      'all_tour_bookings_total.$tourId': FieldValue.increment(1),
    };
    if (completed) {
      updates['completed_tour_bookings_total.$tourId'] = FieldValue.increment(1);
    }
    if (upcomingWeek) {
      updates['upcoming_week_tour_bookings_total.$tourId'] = FieldValue.increment(1);
    }
    await _mapReports.set(
      updates,
      SetOptions(merge: true),
    );
  }

  Stream<List<Booking>> myBookingsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream<List<Booking>>.value([]);
    }
    return _bookings.where('user_id', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(Booking.fromDoc).toList()
        ..sort((a, b) => a.travelDate.compareTo(b.travelDate));

      // Auto-mark past trips as Completed in Firestore (so DB matches UI).
      // This runs best-effort and only once per booking id per app session.
      final now = DateTime.now();
      final startToday = DateTime(now.year, now.month, now.day);
      for (final b in list) {
        if (_autoCompletedIds.contains(b.id)) continue;
        if (b.isCancelled) continue;
        if (!b.travelDate.isBefore(startToday)) continue;
        final st = b.status.trim().toLowerCase();
        if (st == 'completed' || st.contains('complete')) continue;

        _autoCompletedIds.add(b.id);
        // Fire-and-forget: do not block stream mapping.
        _bookings.doc(b.id).update({
          'status': 'Completed',
          'completed_at': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }

      return list;
    });
  }

  Future<String> createBooking({
    required String tourId,
    required String tourTitle,
    required String tourImageUrl,
    required String location,
    required DateTime travelDate,
    required int adults,
    required int children,
    required int rooms,
    required double totalPrice,
    required double subtotalTours,
    required double serviceFee,
    required String currency,
    required String pickup,
    required String durationLabel,
    required String leadFirstName,
    required String leadLastName,
    required String phone,
    required String email,
    required String nationality,
    required String specialRequests,
    required String paymentMethod,
  }) async {
    var user = _auth.currentUser;
    if (user == null) {
      final cred = await _auth.signInAnonymously();
      user = cred.user;
    }
    if (user == null) {
      throw StateError('Not signed in');
    }

    final doc = _bookings.doc();
    final reference =
        'BR-${Random().nextInt(900000) + 100000}'; // 6-digit ref

    await doc.set({
      'user_id': user.uid,
      'tour_id': tourId,
      'tour_title': tourTitle,
      'tourName': tourTitle, // Admin dashboard legacy field
      'tour_image_url': tourImageUrl,
      'location': location,
      'travel_date': Timestamp.fromDate(
        DateTime(travelDate.year, travelDate.month, travelDate.day),
      ),
      'adults': adults,
      'children': children,
      'rooms': rooms,
      'total_price': totalPrice,
      'totalAmount': totalPrice, // Admin dashboard legacy field
      'subtotal_tours': subtotalTours,
      'service_fee': serviceFee,
      'currency': currency,
      'pickup': pickup,
      'duration_label': durationLabel,
      'lead_first_name': leadFirstName,
      'lead_last_name': leadLastName,
      'customerName': '$leadFirstName $leadLastName'.trim(), // Admin dashboard legacy field
      'phone': phone,
      'email': email,
      'nationality': nationality,
      'special_requests': specialRequests,
      'payment_method': paymentMethod,
      'status': 'Confirmed',
      'reference': reference,
      'created_at': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(), // Admin dashboard legacy field
    });

    // Update aggregated map report stats (all users).
    // If stats writes fail due to rules / missing deploy, booking should still succeed.
    try {
      final now = DateTime.now();
      final startToday = DateTime(now.year, now.month, now.day);
      final travelDay = DateTime(travelDate.year, travelDate.month, travelDate.day);
      // Map Reports uses Firestore `status == Completed` for "completed" counts.
      // A booking can have a past travel_date but still not be marked completed.
      const completed = false;
      final upcomingWeek = !travelDay.isBefore(startToday) &&
          !travelDay.isAfter(startToday.add(const Duration(days: 7)));

      await _incrementVisitCategoryForTour(tourId, completed: completed);
      await _incrementTourBookingTotal(tourId, completed: completed, upcomingWeek: upcomingWeek);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('BookingService: map_reports aggregate update failed: $e\n$st');
      }
    }

    return reference;
  }

  Future<void> cancelBooking(
    String bookingId, {
    String? cancellationReason,
  }) async {
    await _bookings.doc(bookingId).update({
      'status': 'Cancel Pending',
      'cancel_requested_at': FieldValue.serverTimestamp(),
      'cancel_request_status': 'pending',
      'cancel_request_resolved_at': null,
      if (cancellationReason != null && cancellationReason.isNotEmpty)
        'cancellation_reason': cancellationReason,
    });

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _bookings.doc(bookingId).get();
        final bd = doc.data() ?? {};
        final title = bd['tour_title'] ?? bd['tourName'] ?? 'Tour';
        await _db.collection('users').doc(user.uid).collection('notifications').add({
          'type': 'booking_cancelled',
          'title': 'Cancel Request Sent',
          'body': 'Your cancellation request for $title has been received and is pending admin approval.',
          'booking_id': bookingId,
          'tour_title': title,
          'booking_status': 'Cancel Pending',
          'read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to send notification: $e');
      }
    }
  }
}

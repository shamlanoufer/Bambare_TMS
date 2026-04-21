import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking.dart';

class BookingService {
  BookingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  Stream<List<Booking>> myBookingsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream<List<Booking>>.value([]);
    }
    return _bookings.where('user_id', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(Booking.fromDoc).toList()
        ..sort((a, b) => a.travelDate.compareTo(b.travelDate));
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
      'tour_image_url': tourImageUrl,
      'location': location,
      'travel_date': Timestamp.fromDate(
        DateTime(travelDate.year, travelDate.month, travelDate.day),
      ),
      'adults': adults,
      'children': children,
      'rooms': rooms,
      'total_price': totalPrice,
      'subtotal_tours': subtotalTours,
      'service_fee': serviceFee,
      'currency': currency,
      'pickup': pickup,
      'duration_label': durationLabel,
      'lead_first_name': leadFirstName,
      'lead_last_name': leadLastName,
      'phone': phone,
      'email': email,
      'nationality': nationality,
      'special_requests': specialRequests,
      'payment_method': paymentMethod,
      'status': 'Confirmed',
      'reference': reference,
      'created_at': FieldValue.serverTimestamp(),
    });

    return reference;
  }

  Future<void> cancelBooking(
    String bookingId, {
    String? cancellationReason,
  }) async {
    await _bookings.doc(bookingId).update({
      'status': 'Cancelled',
      'cancelled_at': FieldValue.serverTimestamp(),
      if (cancellationReason != null && cancellationReason.isNotEmpty)
        'cancellation_reason': cancellationReason,
    });
  }
}

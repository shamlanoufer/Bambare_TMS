import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking.dart';

/// Writes to `bookings` for the signed-in user. Tours remain read-only from `tours`.
class BookingService {
  BookingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');

  /// Ensures an anonymous session (needed for Firestore `bookings` rules).
  Future<User> _ensureAuthUser() async {
    var user = _auth.currentUser;
    if (user != null) return user;
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw StateError(
        'Anonymous sign-in failed (${e.code}). Firebase Console → Authentication → Sign-in method → enable Anonymous.',
      );
    }
    user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'Could not sign in. Enable Anonymous in Firebase Console → Authentication.',
      );
    }
    return user;
  }

  /// Live list for the current user, newest first.
  ///
  /// Uses only `where('user_id')` (no composite index). Sorts by `created_at` in memory.
  /// Follows [authStateChanges] so the list appears after anonymous sign-in completes.
  Stream<List<Booking>> myBookingsStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<Booking>>.value([]);
      }
      return _col.where('user_id', isEqualTo: user.uid).snapshots().map((snap) {
        final list = snap.docs.map(Booking.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    });
  }

  /// Creates a booking document; returns the human reference (e.g. BMB-AB12CD34).
  ///
  /// Full snapshot is stored in `bookings` for admin; cancel updates the same doc.
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
  }) async {
    final user = await _ensureAuthUser();

    final docRef = _col.doc();
    final raw = docRef.id.replaceAll('-', '');
    final suffix = raw.length >= 8 ? raw.substring(0, 8) : raw.padRight(8, '0');
    final reference = 'BMB-${suffix.toUpperCase()}';

    await docRef.set({
      'user_id': user.uid,
      'reference': reference,
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
      'subtotal_tours': subtotalTours,
      'service_fee': serviceFee,
      'total_price': totalPrice,
      'currency': currency,
      'pickup': pickup,
      'duration': durationLabel,
      'status': 'Confirmed',
      'lead_first_name': leadFirstName,
      'lead_last_name': leadLastName,
      'phone': phone,
      'email': email,
      'nationality': nationality,
      'special_requests': specialRequests,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return reference;
  }

  Future<void> cancelBooking(String bookingId) async {
    final user = await _ensureAuthUser();
    final ref = _col.doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Booking not found.');
    }
    final data = snap.data();
    if (data?['user_id'] != user.uid) {
      throw StateError('Not allowed.');
    }
    await ref.update({
      'status': 'Cancelled',
      'cancelled_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'cancelled_via': 'app',
    });
  }
}

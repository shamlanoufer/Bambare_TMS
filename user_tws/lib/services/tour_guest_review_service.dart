import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../models/tour_guest_review.dart';

/// Pending + approved guest reviews for a tour package.
///
/// Firestore: `tours/{tourId}/guest_reviews/{reviewId}`
/// - `approved: false` when user submits after a completed trip
/// - Admin sets `approved: true` so the review appears in the user app Review tab
class TourGuestReviewService {
  TourGuestReviewService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _col(String tourId) =>
      _db.collection('tours').doc(tourId).collection('guest_reviews');

  /// Whether this booking already has a submitted review (any approval state).
  Future<bool> hasReviewForBooking({
    required String tourId,
    required String bookingId,
  }) async {
    if (tourId.isEmpty || bookingId.isEmpty) return false;
    final q = await _col(tourId)
        .where('booking_id', isEqualTo: bookingId)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  Stream<List<TourGuestReview>> approvedReviewsStream(String tourId) {
    if (tourId.isEmpty) {
      return Stream<List<TourGuestReview>>.value(const []);
    }
    return _col(tourId).where('approved', isEqualTo: true).snapshots().map((s) {
      final list = s.docs.map(TourGuestReview.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String?> uploadReviewPhoto({
    required String tourId,
    required dynamic file,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    if (kIsWeb) {
      try {
        final bytes = await (file is XFile
            ? file.readAsBytes()
            : (file as File).readAsBytes());
        final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        return dataUrl;
      } catch (_) {
        return null;
      }
    }

    try {
      final name =
          'tour_guest_reviews/${tourId}_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(name);
      UploadTask task;
      if (file is File) {
        task = ref.putFile(file);
      } else if (file is XFile) {
        task = ref.putFile(File(file.path));
      } else {
        return null;
      }
      await task.timeout(const Duration(seconds: 45));
      return ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> submitPendingReview({
    required String tourId,
    required String bookingId,
    required String userName,
    required String userPhotoUrl,
    required double rating,
    required String commentText,
    String reviewImageUrl = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    if (tourId.isEmpty) {
      throw ArgumentError('tourId required');
    }
    final text = commentText.trim();
    if (text.isEmpty) {
      throw ArgumentError('comment required');
    }

    await _col(tourId).add({
      'user_id': user.uid,
      'booking_id': bookingId,
      'user_name': userName.trim().isEmpty ? 'Guest' : userName.trim(),
      'user_photo_url': userPhotoUrl.trim(),
      'rating': rating.clamp(1.0, 5.0),
      'comment_text': text,
      'review_image_url': reviewImageUrl.trim(),
      'helpful_count': 0,
      'created_at': FieldValue.serverTimestamp(),
      'approved': false,
    });
  }
}

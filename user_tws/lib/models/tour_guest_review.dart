import 'package:cloud_firestore/cloud_firestore.dart';

/// One guest review under `tours/{tourId}/guest_reviews/{id}`.
class TourGuestReview {
  const TourGuestReview({
    required this.id,
    required this.userName,
    required this.userPhotoUrl,
    required this.commentText,
    required this.rating,
    required this.reviewImageUrl,
    required this.helpfulCount,
    required this.createdAt,
    required this.approved,
  });

  final String id;
  final String userName;
  final String userPhotoUrl;
  final String commentText;
  final double rating;
  final String reviewImageUrl;
  final int helpfulCount;
  final DateTime createdAt;
  final bool approved;

  factory TourGuestReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['created_at'];
    DateTime created = DateTime.now();
    if (ts is Timestamp) {
      created = ts.toDate();
    }
    return TourGuestReview(
      id: doc.id,
      userName: (d['user_name'] ?? 'Guest').toString().trim(),
      userPhotoUrl: (d['user_photo_url'] ?? '').toString().trim(),
      commentText: (d['comment_text'] ?? d['text'] ?? '').toString(),
      rating: (d['rating'] as num?)?.toDouble() ?? 5,
      reviewImageUrl: (d['review_image_url'] ?? '').toString().trim(),
      helpfulCount: (d['helpful_count'] as num?)?.toInt() ?? 0,
      createdAt: created,
      approved: d['approved'] == true,
    );
  }
}

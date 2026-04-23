import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin → user message in `users/{uid}/notifications/{id}`.
class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  /// e.g. `booking_cancelled`, `tour_reminder`, `booking_confirmed`, `special_offer`, `payment_reminder`
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;

  factory InboxMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['created_at'];
    // Missing timestamp: sort to end of “newest first” list (epoch).
    DateTime created = DateTime.fromMillisecondsSinceEpoch(0);
    if (ts is Timestamp) created = ts.toDate();
    return InboxMessage(
      id: doc.id,
      type: (d['type'] as String? ?? 'general').trim(),
      title: (d['title'] as String? ?? '').trim(),
      body: (d['body'] as String? ?? d['message'] as String? ?? '').trim(),
      createdAt: created,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inbox_message.dart';

/// Reads admin-sent notifications from `users/{uid}/notifications`.
///
/// ### Admin test (Firebase Console)
/// 1. **Authentication** → Users → copy the **User UID** for the account that
///    is logged into the app (must match; anonymous users have their own UID).
/// 2. **Firestore** → `users` → `{thatUid}` → `notifications` → **Add document**
///    (auto-ID is fine).
/// 3. Fields (example):
///    - `type` (string): `booking_confirmed`
///    - `body` (string): `Yala Safari Experience confirmed! Reference: YSE-3812.`
///    - `created_at` (timestamp): use **Server timestamp** (recommended).
///    - `title` (string, optional): if omitted, the app picks a label from `type`.
/// 4. Open **Notifications** in the app on that same account; the list updates
///    live via snapshot stream (pull-to-refresh not required).
///
/// **Security rules:** the signed-in user may only read `users/{theirUid}/…`.
/// Console writes bypass rules; the app user must still match the document path.
///
/// Field reference:
/// - `type`: `booking_cancelled` | `tour_reminder` | `booking_confirmed` |
///   `special_offer` | `payment_reminder` | `general`
/// - `title`: optional (UI falls back by type)
/// - `body` or `message`: main text
/// - `created_at`: [Timestamp] — use server timestamp so ordering is correct
class InboxService {
  InboxService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? _inbox(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<List<InboxMessage>> myMessagesStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream<List<InboxMessage>>.value([]);
    }
    // No server-side orderBy: documents missing `created_at` would be omitted
    // from ordered queries. Sort client-side so Console tests always show up.
    return _inbox(uid)!.snapshots().map((s) {
      final list = s.docs.map(InboxMessage.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}

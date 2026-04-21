import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes to `activity_log` for the dashboard "Recent Activity" feed.
class ActivityLogService {
  ActivityLogService._();

  static Future<void> log({
    required String type,
    required String message,
  }) async {
    await FirebaseFirestore.instance.collection('activity_log').add({
      'type': type,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

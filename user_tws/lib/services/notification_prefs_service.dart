import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_prefs.dart';

class NotificationPrefsService {
  NotificationPrefsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('notification_prefs')
      .doc('prefs');

  Stream<NotificationPrefs> myPrefsStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value(NotificationPrefs.defaults);
    }
    return _doc(uid).snapshots().map((s) {
      return NotificationPrefs.fromMap(s.data());
    });
  }

  Future<void> upsert(NotificationPrefs prefs) async {
    final uid = _uid;
    if (uid == null) throw 'Not signed in';
    await _doc(uid).set(
      {
        ...prefs.toMap(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}


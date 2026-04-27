import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/privacy_security_prefs.dart';

class PrivacySecurityService {
  PrivacySecurityService({
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
      .collection('privacy_security')
      .doc('prefs');

  Stream<PrivacySecurityPrefs> myPrefsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value(PrivacySecurityPrefs.defaults);
    return _doc(uid).snapshots().map((s) {
      return PrivacySecurityPrefs.fromMap(s.data());
    });
  }

  Future<void> upsert(PrivacySecurityPrefs prefs) async {
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


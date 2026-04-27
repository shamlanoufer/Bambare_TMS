import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/travel_document.dart';

class TravelDocumentService {
  TravelDocumentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('travel_documents');

  String? get _uid => _auth.currentUser?.uid;

  Stream<List<TravelDocument>> myDocsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value(const <TravelDocument>[]);
    return _col(uid)
        .orderBy('expiry_date', descending: false)
        .snapshots()
        .map((s) => s.docs.map(TravelDocument.fromDoc).toList());
  }

  Future<void> create(TravelDocument doc) async {
    final uid = _uid;
    if (uid == null) throw 'Not signed in';
    await _col(uid).add(doc.toCreateMap());
  }

  Future<void> update(TravelDocument doc) async {
    final uid = _uid;
    if (uid == null) throw 'Not signed in';
    await _col(uid).doc(doc.id).update(doc.toUpdateMap());
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    if (uid == null) throw 'Not signed in';
    await _col(uid).doc(id).delete();
  }
}


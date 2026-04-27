import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' show XFile;

import '../models/memory_item.dart';

class MemoriesService {
  MemoriesService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('memories');

  Stream<List<MemoryItem>> myMemoriesStream({int limit = 24}) {
    final uid = _uid;
    if (uid == null) return const Stream<List<MemoryItem>>.empty();
    return _col(uid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(MemoryItem.fromDoc).toList());
  }

  Future<String> _uploadImage({
    required String uid,
    required String memoryId,
    required dynamic file,
  }) async {
    final ref = _storage.ref().child('memories').child(uid).child('$memoryId.jpg');
    UploadTask task;
    if (file is XFile) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        task = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        task = ref.putFile(File(file.path));
      }
    } else if (file is File) {
      task = ref.putFile(file);
    } else {
      throw 'Unsupported file type';
    }

    // Storage uploads can hang (especially on web due to CORS or network).
    // Enforce a timeout so UI doesn't spin forever.
    try {
      await task.whenComplete(() {}).timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw 'Upload timed out. Please check your internet connection and (if web) Firebase Storage CORS settings.';
    }

    return await ref.getDownloadURL().timeout(const Duration(seconds: 15));
  }

  Future<String> _webDataUrl(XFile file) async {
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    return 'data:image/jpeg;base64,$b64';
  }

  Future<void> addMemory({
    required String title,
    String story = '',
    required dynamic imageFile,
  }) async {
    final uid = _uid;
    if (uid == null) throw 'Not signed in';

    final doc = _col(uid).doc();
    String imageUrl;
    try {
      imageUrl = await _uploadImage(uid: uid, memoryId: doc.id, file: imageFile);
    } catch (e) {
      // Web fallback: store data URL in Firestore if Storage upload fails (CORS/network).
      if (kIsWeb && imageFile is XFile) {
        imageUrl = await _webDataUrl(imageFile);
      } else {
        rethrow;
      }
    }

    await doc.set({
      'title': title.trim(),
      'story': story.trim(),
      'image_url': imageUrl,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMemory({
    required String memoryId,
    required String title,
    String story = '',
    dynamic imageFile,
  }) async {
    final uid = _uid;
    if (uid == null) throw 'Not signed in';

    String? imageUrl;
    if (imageFile != null) {
      try {
        imageUrl = await _uploadImage(uid: uid, memoryId: memoryId, file: imageFile);
      } catch (e) {
        if (kIsWeb && imageFile is XFile) {
          imageUrl = await _webDataUrl(imageFile);
        } else {
          rethrow;
        }
      }
    }

    await _col(uid).doc(memoryId).set(
      {
        'title': title.trim(),
        'story': story.trim(),
        if (imageUrl != null) 'image_url': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteMemory({
    required String memoryId,
  }) async {
    final uid = _uid;
    if (uid == null) throw 'Not signed in';

    // Delete Firestore doc first
    await _col(uid).doc(memoryId).delete();

    // Best-effort: delete Storage file (ignore if missing)
    try {
      await _storage.ref().child('memories').child(uid).child('$memoryId.jpg').delete();
    } catch (_) {}
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_saved_tours_store.dart';

/// Saved / liked tours per user.
///
/// Data model:
/// - `users/{uid}/saved_tours/{tourId}`: { tour_id, savedAt }
/// - `users/{uid}.savedCount`: maintained for fast counters
class SavedToursService {
  static final LocalSavedToursStore _sharedLocal = createStore();

  SavedToursService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    LocalSavedToursStore? localStore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _local = localStore ?? _sharedLocal;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final LocalSavedToursStore _local;

  Future<User> _ensureUser() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  Future<void> _syncLocalWithRemoteIds(List<String> remoteIds) async {
    final remote = remoteIds.toSet();
    final local = (await _local.getIds()).toSet();
    if (local.length == remote.length && local.containsAll(remote)) return;

    for (final id in remote.difference(local)) {
      await _local.setSaved(id, true);
    }
    for (final id in local.difference(remote)) {
      await _local.setSaved(id, false);
    }
  }

  CollectionReference<Map<String, dynamic>> _savedToursRef(String uid) {
    return _db.collection('users').doc(uid).collection('saved_tours');
  }

  DocumentReference<Map<String, dynamic>> savedTourDoc({
    required String uid,
    required String tourId,
  }) {
    return _savedToursRef(uid).doc(tourId);
  }

  Stream<bool> isSavedStream(String tourId) async* {
    // Emit local first (works even if Firebase is blocked).
    yield await _local.isSaved(tourId);

    // Local updates (instant).
    yield* _local.idsStream().map((ids) => ids.contains(tourId)).distinct();

    // Remote source of truth (persists across restart/device).
    try {
      final user = await _ensureUser();
      final uid = user.uid;
      yield* savedTourDoc(uid: uid, tourId: tourId)
          .snapshots()
          .map((doc) => doc.exists)
          .asyncMap((remoteSaved) async {
        // Keep local cache consistent with Firestore.
        await _local.setSaved(tourId, remoteSaved);
        return remoteSaved;
      })
          .distinct();
    } on FirebaseException {
      // fall back to local
    } catch (_) {
      // fall back to local
    }
  }

  Stream<List<String>> savedIdsStream() async* {
    // Always emit local first (instant UI).
    yield await _local.getIds();

    // Then keep listening to local changes.
    yield* _local.idsStream();

    // Also listen to Firestore so saved state persists across restart/device.
    try {
      final user = await _ensureUser();
      final uid = user.uid;
      yield* _savedToursRef(uid)
          .snapshots()
          .map((snap) => sortIds(snap.docs.map((d) => d.id)))
          .asyncMap((remoteIds) async {
        await _syncLocalWithRemoteIds(remoteIds);
        return remoteIds;
      })
          .distinct((a, b) =>
              a.length == b.length && a.asMap().entries.every((e) => e.value == b[e.key]));
    } on FirebaseException {
      // If auth/rules block reads, we fall back to local only.
    } catch (_) {
      // Non-Firebase error (network/etc). Fall back to local only.
    }
  }

  Future<void> toggleSaved({
    required String tourId,
    bool? force,
  }) async {
    // Update local first so UI feels instant.
    final currentlySaved = await _local.isSaved(tourId);
    final shouldSave = force ?? !currentlySaved;
    await _local.setSaved(tourId, shouldSave);

    // Remote sync. If Firebase auth/rules block it, we keep local saved
    // but still surface the error to the caller (so UI can show the reason).
    try {
      final user = await _ensureUser();
      final uid = user.uid;
      final doc = savedTourDoc(uid: uid, tourId: tourId);
      final usersDoc = _db.collection('users').doc(uid);

      await _db.runTransaction((tx) async {
        final current = await tx.get(doc);
        final exists = current.exists;

        if (shouldSave && !exists) {
          tx.set(doc, {
            'tour_id': tourId,
            'savedAt': FieldValue.serverTimestamp(),
          });
          tx.set(
            usersDoc,
            {'savedCount': FieldValue.increment(1)},
            SetOptions(merge: true),
          );
        } else if (!shouldSave && exists) {
          tx.delete(doc);
          tx.set(
            usersDoc,
            {'savedCount': FieldValue.increment(-1)},
            SetOptions(merge: true),
          );
        }
      });
    } on FirebaseException {
      rethrow;
    } catch (e) {
      // Non-Firebase error (network/etc). Keep local but let UI know.
      throw Exception(e.toString());
    }
  }
}


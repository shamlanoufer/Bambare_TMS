import 'dart:async';

/// Local (device/browser) saved tours store.
///
/// Used as a fallback when Firestore writes are blocked by auth/rules.
abstract class LocalSavedToursStore {
  Stream<List<String>> idsStream();
  Future<List<String>> getIds();
  Future<bool> isSaved(String tourId);
  Future<void> setSaved(String tourId, bool saved);
}

/// Small helper for consistent ordering.
List<String> sortIds(Iterable<String> ids) {
  final list = ids.toList(growable: false);
  list.sort();
  return list;
}


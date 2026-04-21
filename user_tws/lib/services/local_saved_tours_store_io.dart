import 'dart:async';

import 'local_saved_tours_store_base.dart';

// Non-web fallback: in-memory only (no persistence).
class _MemorySavedToursStore implements LocalSavedToursStore {
  final _ids = <String>{};
  final _ctrl = StreamController<List<String>>.broadcast();

  _MemorySavedToursStore() {
    _ctrl.add(sortIds(_ids));
  }

  @override
  Stream<List<String>> idsStream() => _ctrl.stream;

  @override
  Future<List<String>> getIds() async => sortIds(_ids);

  @override
  Future<bool> isSaved(String tourId) async => _ids.contains(tourId);

  @override
  Future<void> setSaved(String tourId, bool saved) async {
    if (saved) {
      _ids.add(tourId);
    } else {
      _ids.remove(tourId);
    }
    _ctrl.add(sortIds(_ids));
  }
}

LocalSavedToursStore createLocalSavedToursStore() => _MemorySavedToursStore();


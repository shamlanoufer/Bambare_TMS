import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'local_saved_tours_store_base.dart';

class _WebSavedToursStore implements LocalSavedToursStore {
  static const _storageKey = 'bambare_saved_tour_ids_v1';

  final _ctrl = StreamController<List<String>>.broadcast();

  _WebSavedToursStore() {
    _ctrl.add(_readIds());
  }

  List<String> _readIds() {
    final raw = html.window.localStorage[_storageKey];
    if (raw == null || raw.trim().isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      final ids =
          decoded.map((e) => e?.toString().trim() ?? '').where((s) => s.isNotEmpty);
      return sortIds(ids);
    } catch (_) {
      return const <String>[];
    }
  }

  void _writeIds(List<String> ids) {
    html.window.localStorage[_storageKey] = jsonEncode(ids);
    _ctrl.add(ids);
  }

  @override
  Stream<List<String>> idsStream() => _ctrl.stream;

  @override
  Future<List<String>> getIds() async => _readIds();

  @override
  Future<bool> isSaved(String tourId) async {
    final ids = _readIds();
    return ids.contains(tourId);
  }

  @override
  Future<void> setSaved(String tourId, bool saved) async {
    final ids = _readIds().toSet();
    if (saved) {
      ids.add(tourId);
    } else {
      ids.remove(tourId);
    }
    _writeIds(sortIds(ids));
  }
}

LocalSavedToursStore createLocalSavedToursStore() => _WebSavedToursStore();


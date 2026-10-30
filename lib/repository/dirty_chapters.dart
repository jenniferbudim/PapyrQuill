import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which chapters have edits that have not reached the server yet
/// (saved on this device while offline, or the send failed). They are kept in
/// the device's preferences so the list survives closing the app.
///
/// Without this, opening or refreshing a chapter would replace the newer text
/// on this device with the older text still on the server.
class DirtyChapters {
  static const _key = 'dirty_chapter_ids';
  Set<int>? _ids;

  Future<Set<int>> _load() async {
    final cached = _ids;
    if (cached != null) return cached;
    final ids = <int>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final s in prefs.getStringList(_key) ?? const <String>[]) {
        final v = int.tryParse(s);
        if (v != null) ids.add(v);
      }
    } catch (e) {
      debugPrint('DirtyChapters load: $e');
    }
    return _ids = ids;
  }

  Future<void> _save(Set<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, [for (final i in ids) '$i']);
    } catch (e) {
      debugPrint('DirtyChapters save: $e');
    }
  }

  Future<bool> contains(int id) async => (await _load()).contains(id);

  Future<List<int>> all() async => (await _load()).toList();

  Future<void> add(int id) async {
    final ids = await _load();
    if (ids.add(id)) await _save(ids);
  }

  Future<void> remove(int id) async {
    final ids = await _load();
    if (ids.remove(id)) await _save(ids);
  }

  /// A chapter that got a server id: carry the mark over to it.
  Future<void> rename(int oldId, int newId) async {
    final ids = await _load();
    if (ids.remove(oldId)) {
      ids.add(newId);
      await _save(ids);
    }
  }
}

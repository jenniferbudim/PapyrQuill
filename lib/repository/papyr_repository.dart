import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../network/sync_manager.dart';

/// Result of trying to send one pending row to the server.
enum _Step {
  /// Sent and re-keyed, or nothing left to do.
  done,

  /// Not sent yet because the row it belongs to is not on the server yet.
  waiting,

  /// The server could not be reached, or refused the request.
  failed,
}

/// Port of PapyrRepository.kt: every write goes to the local database first,
/// then is sent to the server. Reads are always from the local database.
///
/// ## How ids work (this is what prevents duplicates)
///
/// The server owns the real ids. A row created on this device cannot know its
/// final id, so it is first stored with a **temporary negative id**. Server ids
/// are positive, so a temporary id can never equal the id of a row that
/// another device created.
///
/// Right after saving, the row is sent to the server. The server answers with
/// its real id, and the row (plus everything that points to it: a story's
/// chapters, a group's characters, ...) is re-keyed to that id. The Android and
/// Windows copies then agree on every id, and a later pull updates the existing
/// row instead of adding a second one.
///
/// If the server cannot be reached, the row simply keeps its temporary id.
/// [syncPending] sends such rows later (parents before children), and runs at
/// launch, on pull-to-refresh and whenever a story is opened.
///
/// Screens may still hold a temporary id after the row was re-keyed. Reads and
/// writes here translate it through [resolveStoryId] and friends, so an editor
/// that was open during the re-key keeps saving to the right row.
class PapyrRepository {
  PapyrRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncManager _sync;

  // ── Id bookkeeping ───────────────────────────────────────────────────────

  int _lastTempId = 0;

  /// "story:-123" -> 45: temporary ids that have been swapped for real ones.
  final Map<String, int> _remapped = {};

  /// Pending rows currently being sent, so they are never sent twice at once.
  final Set<String> _inFlight = {};

  /// Pending rows the server accepted without returning an id. They are not
  /// retried in this session, which would only create more copies.
  final Set<String> _blocked = {};

  Future<void>? _pendingRun;

  /// A temporary id: negative, derived from the clock and strictly decreasing,
  /// so one is never handed out twice (even after its row has been re-keyed).
  int _newTempId() {
    final candidate = -DateTime.now().microsecondsSinceEpoch;
    _lastTempId = candidate < _lastTempId ? candidate : _lastTempId - 1;
    return _lastTempId;
  }

  int _resolve(String kind, int id) {
    var current = id;
    for (var hops = 0; hops < 8; hops++) {
      final next = _remapped['$kind:$current'];
      if (next == null) break;
      current = next;
    }
    return current;
  }

  /// The current id of a story, group or chapter, for a possibly outdated one.
  int resolveStoryId(int id) => _resolve('story', id);
  int resolveGroupId(int id) => _resolve('group', id);
  int resolveChapterId(int id) => _resolve('chapter', id);
  int resolveFrameId(int id) => _resolve('frame', id);

  // ── Stories ──────────────────────────────────────────────────────────────
  Stream<List<Story>> getAllStories() => _db.watchAllStories();
  Stream<Story?> getStoryById(int id) => _db.watchStoryById(resolveStoryId(id));

  /// Saves a new story and returns its id (the real one when the server could
  /// be reached, a temporary one otherwise).
  Future<int> insertStory(Story story) async {
    final id = _newTempId();
    await _db.insertNewStory(story.copyWith(id: id));
    await _syncStory(id);
    return _resolve('story', id);
  }

  Future<void> updateStory(Story story) async {
    final s = story.copyWith(id: resolveStoryId(story.id));
    await _db.updateStory(s);
    if (s.id > 0) await _sync.pushStoryUpdated(s);
  }

  Future<void> deleteStory(Story story) async {
    final id = resolveStoryId(story.id);
    await _db.deleteStory(id);
    if (id > 0) await _sync.pushStoryDeleted(id);
  }

  /// Sends rows created offline, then pulls the story list.
  Future<void> refreshStories() async {
    await syncPending();
    await _sync.pullAllStories();
  }

  // ── Chapters ─────────────────────────────────────────────────────────────
  Stream<List<Chapter>> getChaptersForStory(int storyId) =>
      _db.watchChaptersForStory(resolveStoryId(storyId));
  Future<Chapter?> getChapterById(int id) =>
      _db.getChapterById(resolveChapterId(id));
  Stream<List<Chapter>> getUnassignedChapters(int storyId) =>
      _db.watchUnassignedChapters(resolveStoryId(storyId));
  Stream<List<Chapter>> getChaptersForFrame(int frameId) =>
      _db.watchChaptersForFrame(_resolve('frame', frameId));

  Future<int> insertChapter(Chapter chapter) async {
    final id = _newTempId();
    await _db.insertNewChapter(
      chapter.copyWith(id: id, storyId: resolveStoryId(chapter.storyId)),
    );
    await _syncChapter(id);
    return _resolve('chapter', id);
  }

  Future<void> updateChapter(Chapter chapter) async {
    final c = chapter.copyWith(
      id: resolveChapterId(chapter.id),
      storyId: resolveStoryId(chapter.storyId),
    );
    await _db.updateChapter(c);
    if (c.id > 0) await _sync.pushChapterUpdated(c);
  }

  Future<void> deleteChapter(Chapter chapter) async {
    final id = resolveChapterId(chapter.id);
    await _db.deleteChapter(id);
    if (id > 0) await _sync.pushChapterDeleted(id);
  }

  /// Saves a new document order. All local writes happen in one transaction (so
  /// the UI updates once), then the changed chapters are pushed to the server.
  Future<void> reorderChapters(List<Chapter> ordered) async {
    final changed = <Chapter>[];
    await _db.transaction(() async {
      for (var i = 0; i < ordered.length; i++) {
        final chapter = ordered[i];
        if (chapter.documentOrder != i) {
          final updated = chapter.copyWith(
            documentOrder: i,
            id: resolveChapterId(chapter.id),
          );
          await _db.updateChapter(updated);
          changed.add(updated);
        }
      }
    });
    for (final chapter in changed) {
      if (chapter.id > 0) await _sync.pushChapterUpdated(chapter);
    }
  }

  // ── Timeline ─────────────────────────────────────────────────────────────
  Stream<List<TimelineFrame>> getFramesForStory(int storyId) =>
      _db.watchFramesForStory(resolveStoryId(storyId));

  Future<int> insertFrame(TimelineFrame frame) async {
    final id = _newTempId();
    await _db.insertNewFrame(
      frame.copyWith(id: id, storyId: resolveStoryId(frame.storyId)),
    );
    await _syncFrame(id);
    return _resolve('frame', id);
  }

  /// Deletes a frame. Its chapters are not deleted: they go back to the
  /// unassigned pool (the chapters table has no foreign key to frames, so this
  /// is done by hand).
  Future<void> deleteFrame(TimelineFrame frame) async {
    final id = resolveFrameId(frame.id);
    await _db.transaction(() async {
      await _db.clearFrameFromChapters(id);
      await _db.deleteFrame(id);
    });
    if (id > 0) await _sync.pushFrameDeleted(id);
  }

  /// Saves a new frame order. There is no "update frame" endpoint, so the new
  /// order is sent with the bulk endpoint (frames only, real ids only).
  Future<void> reorderFrames(List<TimelineFrame> ordered) async {
    final changed = <TimelineFrame>[];
    await _db.transaction(() async {
      for (var i = 0; i < ordered.length; i++) {
        final f = ordered[i];
        if (f.frameOrder != i) {
          final updated =
              f.copyWith(id: resolveFrameId(f.id), frameOrder: i);
          await _db.insertFrame(updated);
          changed.add(updated);
        }
      }
    });
    final real = changed.where((f) => f.id > 0).toList();
    if (real.isNotEmpty) {
      await _sync.pushBulk(
        stories: const [],
        chapters: const [],
        frames: real,
        groups: const [],
        characters: const [],
      );
    }
  }

  /// Puts a chapter into a frame, at the end of that frame's list.
  Future<void> placeChapterInFrame(int chapterId, int frameId) async {
    final fid = resolveFrameId(frameId);
    final chapter = await _db.getChapterById(resolveChapterId(chapterId));
    if (chapter == null || chapter.timelineFrameId == fid) return;
    final count = (await _db.getChaptersByFrameOnce(fid)).length;
    await updateChapter(chapter.copyWith(
      timelineFrameId: Value(fid),
      timelineOrder: count,
    ));
  }

  /// Saves the order of the chapters inside one frame.
  Future<void> reorderChaptersInFrame(List<Chapter> ordered) async {
    final changed = <Chapter>[];
    await _db.transaction(() async {
      for (var i = 0; i < ordered.length; i++) {
        final c = ordered[i];
        if (c.timelineOrder != i) {
          final updated =
              c.copyWith(timelineOrder: i, id: resolveChapterId(c.id));
          await _db.updateChapter(updated);
          changed.add(updated);
        }
      }
    });
    for (final c in changed) {
      if (c.id > 0) await _sync.pushChapterUpdated(c);
    }
  }

  // ── Character groups ─────────────────────────────────────────────────────
  Stream<List<CharacterGroup>> getGroupsForStory(int storyId) =>
      _db.watchGroupsForStory(resolveStoryId(storyId));

  Future<CharacterGroup?> getGroupById(int id) =>
      _db.getGroupById(resolveGroupId(id));

  Future<int> insertGroup(CharacterGroup group) async {
    final id = _newTempId();
    await _db.insertNewGroup(
      group.copyWith(id: id, storyId: resolveStoryId(group.storyId)),
    );
    await _syncGroup(id);
    return _resolve('group', id);
  }

  Future<void> updateGroup(CharacterGroup group) async {
    final g = group.copyWith(
      id: resolveGroupId(group.id),
      storyId: resolveStoryId(group.storyId),
    );
    await _db.updateGroup(g);
    if (g.id > 0) await _sync.pushGroupUpdated(g);
  }

  Future<void> deleteGroup(CharacterGroup group) async {
    final id = resolveGroupId(group.id);
    await _db.deleteGroup(id);
    if (id > 0) await _sync.pushGroupDeleted(id);
  }

  // ── Characters ───────────────────────────────────────────────────────────
  Stream<List<StoryCharacter>> getCharactersForGroup(int groupId) =>
      _db.watchCharactersForGroup(resolveGroupId(groupId));

  Stream<List<StoryCharacter>> getCharactersForStory(int storyId) =>
      _db.watchCharactersForStory(resolveStoryId(storyId));

  Future<int> insertCharacter(StoryCharacter character) async {
    final id = _newTempId();
    await _db.insertNewCharacter(
      character.copyWith(
        id: id,
        storyId: resolveStoryId(character.storyId),
        groupId: resolveGroupId(character.groupId),
      ),
    );
    await _syncCharacter(id);
    return _resolve('character', id);
  }

  Future<void> updateCharacter(StoryCharacter character) async {
    final c = character.copyWith(
      id: _resolve('character', character.id),
      storyId: resolveStoryId(character.storyId),
      groupId: resolveGroupId(character.groupId),
    );
    await _db.updateCharacter(c);
    if (c.id > 0) await _sync.pushCharacterUpdated(c);
  }

  Future<void> deleteCharacter(StoryCharacter character) async {
    final id = _resolve('character', character.id);
    await _db.deleteCharacter(id);
    if (id > 0) await _sync.pushCharacterDeleted(id);
  }

  // ── Pull refresh ─────────────────────────────────────────────────────────

  /// Sends rows created offline, then pulls the story's chapters, frames,
  /// groups and characters. A story that is not on the server yet has nothing
  /// to pull.
  Future<void> refreshStoryData(int storyId) async {
    await syncPending();
    final id = resolveStoryId(storyId);
    if (id > 0) await _sync.pullStory(id);
  }

  /// Fetches a single chapter's full HTML from the server, stores it locally
  /// and returns it so the editor can show it immediately. Returns null for a
  /// chapter that is not on the server yet.
  Future<Chapter?> refreshChapter(int chapterId) async {
    final id = resolveChapterId(chapterId);
    if (id <= 0) return null;
    final chapter = await _sync.pullChapter(id);
    if (chapter != null) await _db.insertChapter(chapter);
    return chapter;
  }

  // ── Sending rows that were created offline ───────────────────────────────

  /// Sends every row that still has a temporary id, parents before children
  /// (stories, frames, groups, chapters, characters). Stops at the first
  /// failure, so an unreachable server costs one timeout rather than one per
  /// row. Concurrent calls share one run.
  Future<void> syncPending() {
    return _pendingRun ??=
        _runSyncPending().whenComplete(() => _pendingRun = null);
  }

  Future<void> _runSyncPending() async {
    for (final s in await _db.getPendingStories()) {
      if (!await _syncStory(s.id)) return;
    }
    for (final f in await _db.getPendingFrames()) {
      if (!await _syncFrame(f.id)) return;
    }
    for (final g in await _db.getPendingGroups()) {
      if (!await _syncGroup(g.id)) return;
    }
    for (final c in await _db.getPendingChapters()) {
      if (!await _syncChapter(c.id)) return;
    }
    for (final c in await _db.getPendingCharacters()) {
      if (!await _syncCharacter(c.id)) return;
    }
  }

  /// Runs [work] for one pending row, unless it is already real, already being
  /// sent, or blocked. Returns false only when the send failed.
  Future<bool> _syncOne(
    String kind,
    int localId,
    Future<_Step> Function() work,
  ) async {
    if (localId > 0) return true;
    final key = '$kind:$localId';
    if (_blocked.contains(key)) return true;
    if (!_inFlight.add(key)) return true;
    try {
      return await work() != _Step.failed;
    } on MissingServerIdException catch (e) {
      debugPrint('PapyrRepository $e');
      _blocked.add(key);
      return true;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Records old -> new before swapping, so screens that rebuild as soon as the
  /// database changes already see the new id.
  Future<bool> _swapId(
    String kind,
    int oldId,
    int newId,
    Future<bool> Function() swap,
  ) async {
    final key = '$kind:$oldId';
    _remapped[key] = newId;
    try {
      return await swap();
    } catch (_) {
      _remapped.remove(key);
      rethrow;
    }
  }

  Future<bool> _syncStory(int localId) => _syncOne('story', localId, () async {
        final story = await _db.getStoryOnce(localId);
        if (story == null) return _Step.done;
        final serverId = await _sync.pushStoryCreated(story);
        if (serverId == null) return _Step.failed;
        final existed = await _swapId(
          'story',
          localId,
          serverId,
          () => _db.remapStoryId(localId, serverId),
        );
        // Deleted while the request was in flight: delete the server's copy.
        if (!existed) await _sync.pushStoryDeleted(serverId);
        return _Step.done;
      });

  Future<bool> _syncFrame(int localId) => _syncOne('frame', localId, () async {
        final frame = await _db.getFrameById(localId);
        if (frame == null) return _Step.done;
        if (frame.storyId <= 0) return _Step.waiting;
        final serverId = await _sync.pushFrameCreated(frame);
        if (serverId == null) return _Step.failed;
        final existed = await _swapId(
          'frame',
          localId,
          serverId,
          () => _db.remapFrameId(localId, serverId),
        );
        if (!existed) {
          await _sync.pushFrameDeleted(serverId);
          return _Step.done;
        }
        // Chapters placed in this frame before it existed on the server.
        for (final c in await _db.getChaptersByFrameOnce(serverId)) {
          if (c.id > 0) await _sync.pushChapterUpdated(c);
        }
        return _Step.done;
      });

  Future<bool> _syncGroup(int localId) => _syncOne('group', localId, () async {
        final group = await _db.getGroupById(localId);
        if (group == null) return _Step.done;
        if (group.storyId <= 0) return _Step.waiting;
        final serverId = await _sync.pushGroupCreated(group);
        if (serverId == null) return _Step.failed;
        final existed = await _swapId(
          'group',
          localId,
          serverId,
          () => _db.remapGroupId(localId, serverId),
        );
        if (!existed) await _sync.pushGroupDeleted(serverId);
        return _Step.done;
      });

  Future<bool> _syncChapter(int localId) =>
      _syncOne('chapter', localId, () async {
        final chapter = await _db.getChapterById(localId);
        if (chapter == null) return _Step.done;
        if (chapter.storyId <= 0) return _Step.waiting;
        final frameId = chapter.timelineFrameId;
        if (frameId != null && frameId <= 0) return _Step.waiting;

        final serverId = await _sync.pushChapterCreated(chapter);
        if (serverId == null) return _Step.failed;
        final existed = await _swapId(
          'chapter',
          localId,
          serverId,
          () => _db.remapChapterId(localId, serverId),
        );
        if (!existed) {
          await _sync.pushChapterDeleted(serverId);
          return _Step.done;
        }
        // The create request has no timelineFrameId, so set it separately.
        if (frameId != null) {
          await _sync.pushChapterUpdated(chapter.copyWith(id: serverId));
        }
        return _Step.done;
      });

  Future<bool> _syncCharacter(int localId) =>
      _syncOne('character', localId, () async {
        final character = await _db.getCharacterById(localId);
        if (character == null) return _Step.done;
        if (character.storyId <= 0 || character.groupId <= 0) {
          return _Step.waiting;
        }
        final serverId = await _sync.pushCharacterCreated(character);
        if (serverId == null) return _Step.failed;
        final existed = await _swapId(
          'character',
          localId,
          serverId,
          () => _db.remapCharacterId(localId, serverId),
        );
        if (!existed) await _sync.pushCharacterDeleted(serverId);
        return _Step.done;
      });

  // ── Bulk push (not used by the app) ──────────────────────────────────────

  /// Sends everything to the server's bulk endpoint, ids included. That
  /// endpoint overwrites rows that have the same id, so it is only safe from a
  /// single device. The app does not call it; rows created here are sent one by
  /// one and adopt the server's ids. Rows that are still pending are skipped.
  Future<void> pushAllExistingData() async {
    final stories = (await _db.getAllStories()).where((s) => s.id > 0).toList();
    if (stories.isEmpty) return;

    final chapters = <Chapter>[];
    final frames = <TimelineFrame>[];
    final groups = <CharacterGroup>[];
    for (final s in stories) {
      chapters.addAll(
        (await _db.getChaptersByStoryId(s.id)).where((c) => c.id > 0),
      );
      frames.addAll(
        (await _db.getFramesForStory(s.id)).where((f) => f.id > 0),
      );
      groups.addAll(
        (await _db.getGroupsForStory(s.id)).where((g) => g.id > 0),
      );
    }
    final characters = <StoryCharacter>[];
    for (final g in groups) {
      characters.addAll(
        (await _db.getCharactersForGroup(g.id)).where((c) => c.id > 0),
      );
    }

    await _sync.pushBulk(
      stories: stories,
      chapters: chapters,
      frames: frames,
      groups: groups,
      characters: characters,
    );
  }
}

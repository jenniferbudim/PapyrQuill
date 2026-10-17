import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'converters.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// Port of AppDatabase.kt and Dao.kt (StoryDao, ChapterDao, TimelineDao,
/// CharacterGroupDao, CharacterDao) in one class.
///
/// Kotlin `Flow<List<T>>` becomes Drift `Stream<List<T>>` via `.watch()`.
///
/// Inserts are upserts (INSERT ... ON CONFLICT DO UPDATE) rather than Room's
/// REPLACE. REPLACE deletes the old row first, which would trigger the
/// ON DELETE CASCADE rules and wipe a story's chapters, frames and characters
/// whenever the story list was refreshed from the server. An id of 0 means
/// "let the database assign the id", as in the Kotlin code.
@DriftDatabase(
  tables: [Stories, Chapters, TimelineFrames, CharacterGroups, StoryCharacters],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'papyrquill'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Needed for the ON DELETE CASCADE rules to work.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Value<int> _id(int id) => id == 0 ? const Value.absent() : Value(id);

  // ── Stories (StoryDao) ───────────────────────────────────────────────────

  Stream<List<Story>> watchAllStories() => (select(stories)
        ..orderBy([
          (t) => OrderingTerm.desc(t.isFavorite),
          (t) => OrderingTerm.desc(t.timestamp),
        ]))
      .watch();

  Future<List<Story>> getAllStories() => (select(stories)
        ..orderBy([
          (t) => OrderingTerm.desc(t.isFavorite),
          (t) => OrderingTerm.desc(t.timestamp),
        ]))
      .get();

  Stream<Story?> watchStoryById(int id) =>
      (select(stories)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> insertStory(Story s) => into(stories).insertOnConflictUpdate(
        StoriesCompanion(
          id: _id(s.id),
          title: Value(s.title),
          previewText: Value(s.previewText),
          isFavorite: Value(s.isFavorite),
          timestamp: Value(s.timestamp),
        ),
      );

  Future<void> updateStory(Story s) => update(stories).replace(s);

  Future<void> deleteStory(int id) =>
      (delete(stories)..where((t) => t.id.equals(id))).go();

  // ── Chapters (ChapterDao) ────────────────────────────────────────────────

  Stream<List<Chapter>> watchChaptersForStory(int storyId) => (select(chapters)
        ..where((t) => t.storyId.equals(storyId))
        ..orderBy([(t) => OrderingTerm.asc(t.documentOrder)]))
      .watch();

  Future<Chapter?> getChapterById(int id) =>
      (select(chapters)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertChapter(Chapter c) => into(chapters).insertOnConflictUpdate(
        ChaptersCompanion(
          id: _id(c.id),
          storyId: Value(c.storyId),
          title: Value(c.title),
          contentHtml: Value(c.contentHtml),
          timestamp: Value(c.timestamp),
          timelineFrameId: Value(c.timelineFrameId),
          timelineOrder: Value(c.timelineOrder),
          documentOrder: Value(c.documentOrder),
        ),
      );

  Future<void> updateChapter(Chapter c) => update(chapters).replace(c);

  Future<void> deleteChapter(int id) =>
      (delete(chapters)..where((t) => t.id.equals(id))).go();

  /// Chapters not yet placed in any timeline frame.
  Stream<List<Chapter>> watchUnassignedChapters(int storyId) =>
      (select(chapters)
            ..where((t) => t.storyId.equals(storyId) & t.timelineFrameId.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.documentOrder)]))
          .watch();

  Stream<List<Chapter>> watchChaptersForFrame(int frameId) => (select(chapters)
        ..where((t) => t.timelineFrameId.equals(frameId))
        ..orderBy([(t) => OrderingTerm.asc(t.timelineOrder)]))
      .watch();

  Future<List<Chapter>> getChaptersByStoryId(int storyId) =>
      (select(chapters)..where((t) => t.storyId.equals(storyId))).get();

  // ── Timeline frames (TimelineDao) ────────────────────────────────────────

  Stream<List<TimelineFrame>> watchFramesForStory(int storyId) =>
      (select(timelineFrames)
            ..where((t) => t.storyId.equals(storyId))
            ..orderBy([(t) => OrderingTerm.asc(t.frameOrder)]))
          .watch();

  Future<List<TimelineFrame>> getFramesForStory(int storyId) =>
      (select(timelineFrames)
            ..where((t) => t.storyId.equals(storyId))
            ..orderBy([(t) => OrderingTerm.asc(t.frameOrder)]))
          .get();

  Future<int> insertFrame(TimelineFrame f) =>
      into(timelineFrames).insertOnConflictUpdate(
        TimelineFramesCompanion(
          id: _id(f.id),
          storyId: Value(f.storyId),
          name: Value(f.name),
          frameOrder: Value(f.frameOrder),
        ),
      );

  /// Sets timelineFrameId back to null on every chapter in the frame.
  Future<void> clearFrameFromChapters(int frameId) =>
      (update(chapters)..where((t) => t.timelineFrameId.equals(frameId)))
          .write(const ChaptersCompanion(timelineFrameId: Value(null)));

  Future<void> deleteFrame(int id) =>
      (delete(timelineFrames)..where((t) => t.id.equals(id))).go();

  // ── Character groups (CharacterGroupDao) ─────────────────────────────────

  Stream<List<CharacterGroup>> watchGroupsForStory(int storyId) =>
      (select(characterGroups)
            ..where((t) => t.storyId.equals(storyId))
            ..orderBy([(t) => OrderingTerm.asc(t.groupOrder)]))
          .watch();

  Future<List<CharacterGroup>> getGroupsForStory(int storyId) =>
      (select(characterGroups)
            ..where((t) => t.storyId.equals(storyId))
            ..orderBy([(t) => OrderingTerm.asc(t.groupOrder)]))
          .get();

  Future<CharacterGroup?> getGroupById(int id) =>
      (select(characterGroups)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertGroup(CharacterGroup g) =>
      into(characterGroups).insertOnConflictUpdate(
        CharacterGroupsCompanion(
          id: _id(g.id),
          storyId: Value(g.storyId),
          name: Value(g.name),
          iconIndex: Value(g.iconIndex),
          groupOrder: Value(g.groupOrder),
        ),
      );

  Future<void> updateGroup(CharacterGroup g) =>
      update(characterGroups).replace(g);

  Future<void> deleteGroup(int id) =>
      (delete(characterGroups)..where((t) => t.id.equals(id))).go();

  // ── Characters (CharacterDao) ────────────────────────────────────────────

  Stream<List<StoryCharacter>> watchCharactersForGroup(int groupId) =>
      (select(storyCharacters)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<List<StoryCharacter>> getCharactersForGroup(int groupId) =>
      (select(storyCharacters)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<int> insertCharacter(StoryCharacter c) =>
      into(storyCharacters).insertOnConflictUpdate(
        StoryCharactersCompanion(
          id: _id(c.id),
          storyId: Value(c.storyId),
          groupId: Value(c.groupId),
          name: Value(c.name),
          description: Value(c.description),
          attributes: Value(c.attributes),
        ),
      );

  Future<void> updateCharacter(StoryCharacter c) =>
      update(storyCharacters).replace(c);

  Future<void> deleteCharacter(int id) =>
      (delete(storyCharacters)..where((t) => t.id.equals(id))).go();

  // ── Rows that are not on the server yet ──────────────────────────────────
  //
  // A row created on this device gets a temporary NEGATIVE id (see
  // PapyrRepository). Server ids are positive, so a temporary id can never
  // collide with a row pulled from the server. When the server has created the
  // row and returned its real id, the remap methods below swap the id
  // everywhere it is used.

  /// Plain INSERT (not an upsert) using the id already set on the row, so an
  /// id clash fails loudly instead of overwriting another row.
  Future<int> insertNewStory(Story s) => into(stories).insert(s);
  Future<int> insertNewChapter(Chapter c) => into(chapters).insert(c);
  Future<int> insertNewFrame(TimelineFrame f) => into(timelineFrames).insert(f);
  Future<int> insertNewGroup(CharacterGroup g) =>
      into(characterGroups).insert(g);
  Future<int> insertNewCharacter(StoryCharacter c) =>
      into(storyCharacters).insert(c);

  // Rows still waiting to be created on the server, oldest first (temporary
  // ids get smaller over time, so descending id order is creation order).
  Future<List<Story>> getPendingStories() => (select(stories)
        ..where((t) => t.id.isSmallerThanValue(0))
        ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .get();

  Future<List<TimelineFrame>> getPendingFrames() => (select(timelineFrames)
        ..where((t) => t.id.isSmallerThanValue(0))
        ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .get();

  Future<List<CharacterGroup>> getPendingGroups() => (select(characterGroups)
        ..where((t) => t.id.isSmallerThanValue(0))
        ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .get();

  Future<List<Chapter>> getPendingChapters() => (select(chapters)
        ..where((t) => t.id.isSmallerThanValue(0))
        ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .get();

  Future<List<StoryCharacter>> getPendingCharacters() =>
      (select(storyCharacters)
            ..where((t) => t.id.isSmallerThanValue(0))
            ..orderBy([(t) => OrderingTerm.desc(t.id)]))
          .get();

  Future<List<Chapter>> getChaptersByFrameOnce(int frameId) =>
      (select(chapters)..where((t) => t.timelineFrameId.equals(frameId))).get();

  Future<Story?> getStoryOnce(int id) =>
      (select(stories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<TimelineFrame?> getFrameById(int id) =>
      (select(timelineFrames)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<StoryCharacter?> getCharacterById(int id) =>
      (select(storyCharacters)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  // ── Swapping a temporary id for the server's id ──────────────────────────
  //
  // Each remap* method runs in one transaction and returns false when the row
  // [oldId] no longer exists (it was deleted while the server request was in
  // flight; the caller then deletes the server's copy too).
  //
  // PRAGMA defer_foreign_keys postpones the foreign key check to the end of the
  // transaction, so a parent and its children can be re-keyed in any order.
  //
  // If the server's copy ([newId]) was already pulled in the meantime, that
  // copy is removed and ours is kept: ours is at least as new, and the pull may
  // have left out the chapter text.

  Future<void> _deferForeignKeys() =>
      customStatement('PRAGMA defer_foreign_keys = ON');

  Future<bool> remapStoryId(int oldId, int newId) => transaction(() async {
        await _deferForeignKeys();
        if (await getStoryOnce(oldId) == null) return false;
        await deleteStory(newId);
        await (update(stories)..where((t) => t.id.equals(oldId)))
            .write(StoriesCompanion(id: Value(newId)));
        await (update(chapters)..where((t) => t.storyId.equals(oldId)))
            .write(ChaptersCompanion(storyId: Value(newId)));
        await (update(timelineFrames)..where((t) => t.storyId.equals(oldId)))
            .write(TimelineFramesCompanion(storyId: Value(newId)));
        await (update(characterGroups)..where((t) => t.storyId.equals(oldId)))
            .write(CharacterGroupsCompanion(storyId: Value(newId)));
        await (update(storyCharacters)..where((t) => t.storyId.equals(oldId)))
            .write(StoryCharactersCompanion(storyId: Value(newId)));
        return true;
      });

  Future<bool> remapFrameId(int oldId, int newId) => transaction(() async {
        await _deferForeignKeys();
        if (await getFrameById(oldId) == null) return false;
        await deleteFrame(newId);
        await (update(timelineFrames)..where((t) => t.id.equals(oldId)))
            .write(TimelineFramesCompanion(id: Value(newId)));
        // chapters.timelineFrameId is a plain column, not a foreign key.
        await (update(chapters)..where((t) => t.timelineFrameId.equals(oldId)))
            .write(ChaptersCompanion(timelineFrameId: Value(newId)));
        return true;
      });

  Future<bool> remapGroupId(int oldId, int newId) => transaction(() async {
        await _deferForeignKeys();
        if (await getGroupById(oldId) == null) return false;
        await deleteGroup(newId);
        await (update(characterGroups)..where((t) => t.id.equals(oldId)))
            .write(CharacterGroupsCompanion(id: Value(newId)));
        await (update(storyCharacters)..where((t) => t.groupId.equals(oldId)))
            .write(StoryCharactersCompanion(groupId: Value(newId)));
        return true;
      });

  Future<bool> remapChapterId(int oldId, int newId) => transaction(() async {
        if (await getChapterById(oldId) == null) return false;
        await deleteChapter(newId);
        await (update(chapters)..where((t) => t.id.equals(oldId)))
            .write(ChaptersCompanion(id: Value(newId)));
        return true;
      });

  Future<bool> remapCharacterId(int oldId, int newId) =>
      transaction(() async {
        if (await getCharacterById(oldId) == null) return false;
        await deleteCharacter(newId);
        await (update(storyCharacters)..where((t) => t.id.equals(oldId)))
            .write(StoryCharactersCompanion(id: Value(newId)));
        return true;
      });

  // ── Pulling chapters ─────────────────────────────────────────────────────

  /// Like [insertChapter], but leaves contentHtml untouched. Used when the
  /// server's chapter list does not include the text, so a pull cannot blank
  /// out the text stored on this device. A brand-new row gets empty content.
  Future<int> upsertChapterKeepingContent(Chapter c) =>
      into(chapters).insertOnConflictUpdate(
        ChaptersCompanion(
          id: Value(c.id),
          storyId: Value(c.storyId),
          title: Value(c.title),
          timestamp: Value(c.timestamp),
          timelineFrameId: Value(c.timelineFrameId),
          timelineOrder: Value(c.timelineOrder),
          documentOrder: Value(c.documentOrder),
        ),
      );
}

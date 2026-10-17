import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import 'api_models.dart';
import 'remote_data_source.dart';

/// The server accepted a create request but did not say which id it used.
/// Without that id the local copy cannot be matched to the server's row.
class MissingServerIdException implements Exception {
  MissingServerIdException(this.what);

  final String what;

  @override
  String toString() =>
      'The server created the $what but did not return its id. The create '
      'endpoint should answer {"success":true,"data":{"id":123}}.';
}

/// Port of SyncManager.kt.
///
/// Pull order matters: groups and frames are stored before characters and
/// chapters that reference them. A failed network call just returns null from
/// [RemoteDataSource] and the local data stays as it is. The create calls
/// return the id the server assigned, or null when it could not be reached.
class SyncManager {
  SyncManager(this._remote, this._db);

  final RemoteDataSource _remote;
  final AppDatabase _db;

  static const _tag = 'SyncManager';

  void _log(String message) => debugPrint('$_tag $message');

  /// A frame id the server knows, or null for none / a temporary id.
  int? _realId(int? id) => (id != null && id > 0) ? id : null;

  /// The id from a create response: null when the server was not reached or
  /// refused the request (the row stays pending and is retried later). Throws
  /// [MissingServerIdException] when the request succeeded but no id came back.
  int? _idOf(MutationResult? result, String what) {
    if (result == null) return null;
    final id = result.id;
    if (id == null || id <= 0) throw MissingServerIdException(what);
    return id;
  }

  // ── Pull: server -> local database ───────────────────────────────────────

  Future<void> pullAllStories() async {
    final list = await _remote.getAllStories();
    if (list == null) return;
    for (final dto in list) {
      await _db.insertStory(_toStory(dto));
    }
    _log('Pulled ${list.length} stories');
  }

  /// Call when opening the document, timeline or character screens.
  Future<void> pullStory(int storyId) async {
    // 1. Chapters
    final chapters = await _remote.getChaptersForStory(storyId);
    if (chapters != null) {
      for (final dto in chapters) {
        final row = _toChapter(dto);
        if (dto.contentHtml == null) {
          // The list leaves out the text: keep what is stored here.
          await _db.upsertChapterKeepingContent(row);
        } else {
          await _db.insertChapter(row);
        }
      }
      _log('Pulled ${chapters.length} chapters for story $storyId');
    }

    // 2. Timeline frames
    final frames = await _remote.getFramesForStory(storyId);
    if (frames != null) {
      for (final dto in frames) {
        await _db.insertFrame(_toFrame(dto));
      }
      _log('Pulled ${frames.length} frames for story $storyId');
    }

    // 3. Character groups, before characters
    final groups = await _remote.getGroupsForStory(storyId);
    if (groups != null) {
      for (final dto in groups) {
        await _db.insertGroup(_toGroup(dto));
      }
      _log('Pulled ${groups.length} groups for story $storyId');
    }

    // 4. Characters, which need their group to exist first
    final characters = await _remote.getCharactersForStory(storyId);
    if (characters != null) {
      for (final dto in characters) {
        await _db.insertCharacter(_toCharacter(dto));
      }
      _log('Pulled ${characters.length} characters for story $storyId');
    }
  }

  /// Fetches one chapter with its full contentHtml (the list endpoint omits it).
  Future<Chapter?> pullChapter(int chapterId) async {
    final dto = await _remote.getChapter(chapterId);
    if (dto == null) return null;
    final chapter = _toChapter(dto);
    _log('Pulled chapter id=$chapterId (${chapter.title})');
    return chapter;
  }

  // ── Push: local database -> server ───────────────────────────────────────

  Future<int?> pushStoryCreated(Story story) async {
    final r = await _remote.createStory(CreateStoryRequest(
      title: story.title,
      previewText: story.previewText,
      isFavorite: story.isFavorite ? 1 : 0,
      timestamp: story.timestamp,
    ));
    final id = _idOf(r, 'story');
    if (id != null) _log('Pushed new story: ${story.title} (server id $id)');
    return id;
  }

  Future<void> pushStoryUpdated(Story story) async {
    final r = await _remote.updateStory(
      story.id,
      UpdateStoryRequest(
        title: story.title,
        previewText: story.previewText,
        isFavorite: story.isFavorite ? 1 : 0,
      ),
    );
    if (r != null) _log('Pushed story update: id=${story.id}');
  }

  Future<void> pushStoryDeleted(int storyId) async {
    final r = await _remote.deleteStory(storyId);
    if (r != null) _log('Pushed story delete: id=$storyId');
  }

  Future<int?> pushChapterCreated(Chapter chapter) async {
    final r = await _remote.createChapter(CreateChapterRequest(
      storyId: chapter.storyId,
      title: chapter.title,
      contentHtml: chapter.contentHtml,
      timelineOrder: chapter.timelineOrder,
      documentOrder: chapter.documentOrder,
      timestamp: chapter.timestamp,
    ));
    final id = _idOf(r, 'chapter');
    if (id != null) _log('Pushed new chapter: ${chapter.title} (server id $id)');
    return id;
  }

  Future<void> pushChapterUpdated(Chapter chapter) async {
    final r = await _remote.updateChapter(
      chapter.id,
      UpdateChapterRequest(
        title: chapter.title,
        contentHtml: chapter.contentHtml,
        timelineFrameId: _realId(chapter.timelineFrameId),
        timelineOrder: chapter.timelineOrder,
        documentOrder: chapter.documentOrder,
      ),
    );
    if (r != null) _log('Pushed chapter update: id=${chapter.id}');
  }

  Future<void> pushChapterDeleted(int chapterId) async {
    final r = await _remote.deleteChapter(chapterId);
    if (r != null) _log('Pushed chapter delete: id=$chapterId');
  }

  Future<int?> pushGroupCreated(CharacterGroup group) async {
    final r = await _remote.createGroup(CreateGroupRequest(
      storyId: group.storyId,
      name: group.name,
      iconIndex: group.iconIndex,
      groupOrder: group.groupOrder,
    ));
    final id = _idOf(r, 'group');
    if (id != null) _log('Pushed new group: ${group.name} (server id $id)');
    return id;
  }

  Future<void> pushGroupUpdated(CharacterGroup group) async {
    final r = await _remote.updateGroup(
      group.id,
      UpdateGroupRequest(
        name: group.name,
        iconIndex: group.iconIndex,
        groupOrder: group.groupOrder,
      ),
    );
    if (r != null) _log('Pushed group update: id=${group.id}');
  }

  Future<void> pushGroupDeleted(int groupId) async {
    final r = await _remote.deleteGroup(groupId);
    if (r != null) _log('Pushed group delete: id=$groupId');
  }

  Future<int?> pushCharacterCreated(StoryCharacter character) async {
    final r = await _remote.createCharacter(CreateCharacterRequest(
      storyId: character.storyId,
      groupId: character.groupId,
      name: character.name,
      description: character.description,
      attributes: character.attributes,
    ));
    final id = _idOf(r, 'character');
    if (id != null) _log('Pushed new character: ${character.name} (server id $id)');
    return id;
  }

  Future<void> pushCharacterUpdated(StoryCharacter character) async {
    final r = await _remote.updateCharacter(
      character.id,
      UpdateCharacterRequest(
        groupId: character.groupId,
        name: character.name,
        description: character.description,
        attributes: character.attributes,
      ),
    );
    if (r != null) _log('Pushed character update: id=${character.id}');
  }

  Future<void> pushCharacterDeleted(int characterId) async {
    final r = await _remote.deleteCharacter(characterId);
    if (r != null) _log('Pushed character delete: id=$characterId');
  }

  Future<int?> pushFrameCreated(TimelineFrame frame) async {
    final r = await _remote.createFrame(CreateFrameRequest(
      storyId: frame.storyId,
      name: frame.name,
      frameOrder: frame.frameOrder,
    ));
    final id = _idOf(r, 'frame');
    if (id != null) _log('Pushed new frame: ${frame.name} (server id $id)');
    return id;
  }

  Future<void> pushFrameDeleted(int frameId) async {
    final r = await _remote.deleteFrame(frameId);
    if (r != null) _log('Pushed frame delete: id=$frameId');
  }

  /// Pushes everything to the server in one request. The server endpoint uses
  /// INSERT ... ON DUPLICATE KEY UPDATE, so calling this repeatedly is safe.
  Future<void> pushBulk({
    required List<Story> stories,
    required List<Chapter> chapters,
    required List<TimelineFrame> frames,
    required List<CharacterGroup> groups,
    required List<StoryCharacter> characters,
  }) async {
    final request = SyncRequest(
      stories: stories
          .map((s) => SyncStoryDto(
                id: s.id,
                title: s.title,
                previewText: s.previewText,
                isFavorite: s.isFavorite ? 1 : 0,
                timestamp: s.timestamp,
                updatedAt: s.timestamp,
              ))
          .toList(),
      chapters: chapters
          .map((c) => SyncChapterDto(
                id: c.id,
                storyId: c.storyId,
                title: c.title,
                contentHtml: c.contentHtml,
                timestamp: c.timestamp,
                updatedAt: c.timestamp,
                timelineFrameId: _realId(c.timelineFrameId),
                timelineOrder: c.timelineOrder,
                documentOrder: c.documentOrder,
              ))
          .toList(),
      frames: frames
          .map((f) => SyncFrameDto(
                id: f.id,
                storyId: f.storyId,
                name: f.name,
                frameOrder: f.frameOrder,
              ))
          .toList(),
      groups: groups
          .map((g) => SyncGroupDto(
                id: g.id,
                storyId: g.storyId,
                name: g.name,
                iconIndex: g.iconIndex,
                groupOrder: g.groupOrder,
              ))
          .toList(),
      characters: characters
          .map((c) => SyncCharacterDto(
                id: c.id,
                storyId: c.storyId,
                groupId: c.groupId,
                name: c.name,
                description: c.description,
                attributes: c.attributes,
              ))
          .toList(),
    );

    final result = await _remote.sync(request);
    if (result != null) {
      final s = result.synced;
      _log('Bulk push complete: stories:${s.stories} chapters:${s.chapters} '
          'groups:${s.groups} characters:${s.characters} frames:${s.frames}');
    }
  }

  // ── DTO -> local row converters ──────────────────────────────────────────

  Story _toStory(StoryDto d) => Story(
        id: d.id,
        title: d.title,
        previewText: d.previewText,
        isFavorite: d.isFavorite,
        timestamp: d.timestamp,
      );

  Chapter _toChapter(ChapterDto d) => Chapter(
        id: d.id,
        storyId: d.storyId,
        title: d.title,
        contentHtml: d.contentHtml ?? '',
        timestamp: d.timestamp,
        timelineFrameId: d.timelineFrameId,
        timelineOrder: d.timelineOrder,
        documentOrder: d.documentOrder,
      );

  CharacterGroup _toGroup(CharacterGroupDto d) => CharacterGroup(
        id: d.id,
        storyId: d.storyId,
        name: d.name,
        iconIndex: d.iconIndex,
        groupOrder: d.groupOrder,
      );

  StoryCharacter _toCharacter(CharacterDto d) => StoryCharacter(
        id: d.id,
        storyId: d.storyId,
        groupId: d.groupId,
        name: d.name,
        description: d.description,
        attributes: d.attributes,
      );

  TimelineFrame _toFrame(TimelineFrameDto d) => TimelineFrame(
        id: d.id,
        storyId: d.storyId,
        name: d.name,
        frameOrder: d.frameOrder,
      );
}

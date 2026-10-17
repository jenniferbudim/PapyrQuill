// Tests for how new rows get their ids (see PapyrRepository).
//
// They use a fake server and an in-memory database, so they need SQLite to be
// loadable in tests the same way it is for the app.

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrquill/data/app_database.dart';
import 'package:papyrquill/network/api_models.dart';
import 'package:papyrquill/network/remote_data_source.dart';
import 'package:papyrquill/network/sync_manager.dart';
import 'package:papyrquill/repository/papyr_repository.dart';

/// A stand-in for the PHP server. It hands out its own ids and can be switched
/// offline.
class FakeServer extends RemoteDataSource {
  FakeServer() : super(Dio());

  bool online = true;

  /// When true the server creates rows but leaves the id out of its answer.
  bool omitIds = false;

  int createStoryCalls = 0;
  int _nextStoryId = 100;
  int _nextChapterId = 500;

  final List<StoryDto> stories = [];
  final List<CreateChapterRequest> chapterRequests = [];
  final List<int> deletedStories = [];
  List<ChapterDto> chaptersToServe = [];

  /// Runs after the server created a story and before the app hears about it.
  Future<void> Function(int serverId)? whileStoryIsBeingCreated;

  @override
  Future<MutationResult?> createStory(CreateStoryRequest r) async {
    createStoryCalls++;
    if (!online) return null;
    final id = _nextStoryId++;
    stories.add(StoryDto(
      id: id,
      title: r.title,
      previewText: r.previewText,
      isFavorite: r.isFavorite == 1,
      timestamp: r.timestamp,
      updatedAt: r.timestamp,
    ));
    await whileStoryIsBeingCreated?.call(id);
    return omitIds ? MutationResult() : MutationResult(id: id);
  }

  @override
  Future<MutationResult?> createChapter(CreateChapterRequest r) async {
    if (!online) return null;
    chapterRequests.add(r);
    return MutationResult(id: _nextChapterId++);
  }

  @override
  Future<MutationResult?> updateStory(int id, UpdateStoryRequest r) async =>
      online ? MutationResult(updated: true) : null;

  @override
  Future<MutationResult?> updateChapter(int id, UpdateChapterRequest r) async =>
      online ? MutationResult(updated: true) : null;

  @override
  Future<MutationResult?> deleteStory(int id) async {
    if (!online) return null;
    deletedStories.add(id);
    return MutationResult(deleted: true);
  }

  @override
  Future<List<StoryDto>?> getAllStories() async =>
      online ? List.of(stories) : null;

  @override
  Future<List<ChapterDto>?> getChaptersForStory(int storyId) async =>
      online ? chaptersToServe : null;

  @override
  Future<List<TimelineFrameDto>?> getFramesForStory(int storyId) async =>
      online ? <TimelineFrameDto>[] : null;

  @override
  Future<List<CharacterGroupDto>?> getGroupsForStory(int storyId) async =>
      online ? <CharacterGroupDto>[] : null;

  @override
  Future<List<CharacterDto>?> getCharactersForStory(int storyId) async =>
      online ? <CharacterDto>[] : null;
}

void main() {
  late AppDatabase db;
  late FakeServer server;
  late PapyrRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeServer();
    repo = PapyrRepository(db, SyncManager(server, db));
  });

  tearDown(() => db.close());

  Story newStory(String title) => Story(
        id: 0,
        title: title,
        previewText: '',
        isFavorite: false,
        timestamp: 1,
      );

  Chapter newChapter(int storyId, {String html = ''}) => Chapter(
        id: 0,
        storyId: storyId,
        title: 'Chapter',
        contentHtml: html,
        timestamp: 1,
        timelineFrameId: null,
        timelineOrder: 0,
        documentOrder: 0,
      );

  test('online: a new story adopts the server id and a pull adds no copy',
      () async {
    final id = await repo.insertStory(newStory('A'));
    expect(id, 100);

    await repo.refreshStories();

    final all = await db.getAllStories();
    expect(all.map((s) => s.id), [100]);
    expect(all.single.title, 'A');
  });

  test('offline: the story keeps a temporary id and is sent later', () async {
    server.online = false;
    final tempId = await repo.insertStory(newStory('Offline'));
    expect(tempId, isNegative);

    // Still offline: nothing changes, and no duplicate appears.
    await repo.refreshStories();
    expect((await db.getAllStories()).map((s) => s.id), [tempId]);

    server.online = true;
    await repo.refreshStories();

    expect((await db.getAllStories()).map((s) => s.id), [100]);
    expect(server.stories, hasLength(1));
  });

  test('a chapter written under a pending story follows it to its real id',
      () async {
    server.online = false;
    final storyTemp = await repo.insertStory(newStory('S'));
    final chapterTemp = await repo.insertChapter(newChapter(storyTemp));
    expect(chapterTemp, isNegative);

    server.online = true;
    await repo.syncPending();

    expect((await db.getAllStories()).map((s) => s.id), [100]);
    final chapters = await db.getChaptersByStoryId(100);
    expect(chapters.map((c) => c.id), [500]);
    // The chapter was created under the story's REAL id, not the temporary one.
    expect(server.chapterRequests.single.storyId, 100);
  });

  test('an outdated id still reaches the right row after the swap', () async {
    server.online = false;
    final storyTemp = await repo.insertStory(newStory('S'));
    final chapterTemp = await repo.insertChapter(newChapter(storyTemp));
    final stale = (await db.getChapterById(chapterTemp))!;

    server.online = true;
    await repo.syncPending();

    // An editor that still holds the temporary id saves a change.
    await repo.updateChapter(stale.copyWith(title: 'Renamed'));

    final saved = await db.getChapterById(500);
    expect(saved?.title, 'Renamed');
    expect(repo.resolveStoryId(storyTemp), 100);
    expect(repo.resolveChapterId(chapterTemp), 500);
  });

  test('if the server copy was pulled during the create, ours replaces it',
      () async {
    server.whileStoryIsBeingCreated = (serverId) async {
      await db.insertStory(Story(
        id: serverId,
        title: 'pulled copy',
        previewText: '',
        isFavorite: false,
        timestamp: 1,
      ));
    };

    await repo.insertStory(newStory('mine'));

    final all = await db.getAllStories();
    expect(all, hasLength(1));
    expect(all.single.id, 100);
    expect(all.single.title, 'mine');
  });

  test('a story deleted while it was being created is deleted on the server',
      () async {
    server.whileStoryIsBeingCreated = (serverId) async {
      final pending = (await db.getPendingStories()).single;
      await db.deleteStory(pending.id);
    };

    await repo.insertStory(newStory('gone'));

    expect(await db.getAllStories(), isEmpty);
    expect(server.deletedStories, [100]);
  });

  test('a server that returns no id is not asked to create it again',
      () async {
    server.omitIds = true;
    final tempId = await repo.insertStory(newStory('X'));
    expect(tempId, isNegative);
    expect(server.createStoryCalls, 1);

    await repo.syncPending();
    await repo.syncPending();

    expect(server.createStoryCalls, 1);
  });

  test('an unreachable server costs one attempt per run, not one per row',
      () async {
    server.online = false;
    await repo.insertStory(newStory('one'));
    await repo.insertStory(newStory('two'));
    await repo.insertStory(newStory('three'));

    server.createStoryCalls = 0;
    await repo.syncPending();

    expect(server.createStoryCalls, 1);
  });

  test('a pull that leaves out chapter text keeps the text stored here',
      () async {
    await db.insertStory(Story(
      id: 7,
      title: 'S',
      previewText: '',
      isFavorite: false,
      timestamp: 1,
    ));
    await db.insertChapter(Chapter(
      id: 9,
      storyId: 7,
      title: 'Old title',
      contentHtml: '<p>keep me</p>',
      timestamp: 1,
      timelineFrameId: null,
      timelineOrder: 0,
      documentOrder: 0,
    ));
    server.chaptersToServe = [
      ChapterDto(
        id: 9,
        storyId: 7,
        title: 'Renamed on server',
        contentHtml: null, // the list leaves the text out
        timestamp: 2,
        updatedAt: 2,
        timelineFrameId: null,
        timelineOrder: 0,
        documentOrder: 0,
      ),
    ];

    await repo.refreshStoryData(7);

    final chapter = (await db.getChapterById(9))!;
    expect(chapter.title, 'Renamed on server');
    expect(chapter.contentHtml, '<p>keep me</p>');
  });
}

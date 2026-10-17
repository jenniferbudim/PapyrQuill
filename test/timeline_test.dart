// Tests for the timeline operations in PapyrRepository.

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrquill/data/app_database.dart';
import 'package:papyrquill/network/api_models.dart';
import 'package:papyrquill/network/remote_data_source.dart';
import 'package:papyrquill/network/sync_manager.dart';
import 'package:papyrquill/repository/papyr_repository.dart';

/// A server that is always unreachable: every write stays local.
class OfflineServer extends RemoteDataSource {
  OfflineServer() : super(Dio());

  @override
  Future<MutationResult?> createFrame(CreateFrameRequest r) async => null;
  @override
  Future<MutationResult?> deleteFrame(int id) async => null;
  @override
  Future<MutationResult?> updateChapter(int id, UpdateChapterRequest r) async =>
      null;
  @override
  Future<SyncResult?> sync(SyncRequest r) async => null;
}

void main() {
  late AppDatabase db;
  late PapyrRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = PapyrRepository(db, SyncManager(OfflineServer(), db));
    await db.insertStory(Story(
      id: 1,
      title: 'S',
      previewText: '',
      isFavorite: false,
      timestamp: 1,
    ));
  });

  tearDown(() => db.close());

  Future<void> chapter(int id, {int? frame, int order = 0}) =>
      db.insertChapter(Chapter(
        id: id,
        storyId: 1,
        title: 'C$id',
        contentHtml: '<p>text $id</p>',
        timestamp: 1,
        timelineFrameId: frame,
        timelineOrder: order,
        documentOrder: id,
      ));

  Future<void> frame(int id, int order) => db.insertFrame(
      TimelineFrame(id: id, storyId: 1, name: 'F$id', frameOrder: order));

  test('placing a chapter appends it to the frame and keeps its text',
      () async {
    await frame(10, 0);
    await chapter(1, frame: 10, order: 0);
    await chapter(2);

    await repo.placeChapterInFrame(2, 10);

    final c = (await db.getChapterById(2))!;
    expect(c.timelineFrameId, 10);
    expect(c.timelineOrder, 1);
    expect(c.contentHtml, '<p>text 2</p>');
  });

  test('moving a chapter to another frame', () async {
    await frame(10, 0);
    await frame(11, 1);
    await chapter(1, frame: 10);

    await repo.placeChapterInFrame(1, 11);

    expect((await db.getChapterById(1))!.timelineFrameId, 11);
  });

  test('deleting a frame returns its chapters to unassigned', () async {
    await frame(10, 0);
    await chapter(1, frame: 10);

    await repo.deleteFrame((await db.getFrameById(10))!);

    expect(await db.getFrameById(10), isNull);
    final c = (await db.getChapterById(1))!;
    expect(c.timelineFrameId, isNull);
    expect(c.contentHtml, '<p>text 1</p>');
  });

  test('reordering frames and chapters is saved', () async {
    await frame(10, 0);
    await frame(11, 1);
    await chapter(1, frame: 10, order: 0);
    await chapter(2, frame: 10, order: 1);

    await repo.reorderFrames([
      (await db.getFrameById(11))!,
      (await db.getFrameById(10))!,
    ]);
    await repo.reorderChaptersInFrame([
      (await db.getChapterById(2))!,
      (await db.getChapterById(1))!,
    ]);

    final frames = await db.getFramesForStory(1);
    expect(frames.map((f) => f.id), [11, 10]);
    final inFrame = await db.getChaptersByFrameOnce(10);
    inFrame.sort((a, b) => a.timelineOrder.compareTo(b.timelineOrder));
    expect(inFrame.map((c) => c.id), [2, 1]);
  });

  test('a chapter put into a pending frame follows it to its real id',
      () async {
    final tempFrame = await repo.insertFrame(
        TimelineFrame(id: 0, storyId: 1, name: 'New', frameOrder: 0));
    expect(tempFrame, isNegative);
    await chapter(1);

    await repo.placeChapterInFrame(1, tempFrame);

    expect((await db.getChapterById(1))!.timelineFrameId, tempFrame);
  });
}

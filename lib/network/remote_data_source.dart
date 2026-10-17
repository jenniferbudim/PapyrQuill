import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_models.dart';

/// Port of PapyrApiService.kt + RemoteDataSource.kt.
///
/// Retrofit's annotated interface has no Dart equivalent, so the endpoint calls
/// and the safeCall wrapper live together here. Every method returns null on
/// failure instead of throwing, exactly like the Kotlin version.
class RemoteDataSource {
  RemoteDataSource(this._dio);

  final Dio _dio;

  static const _tag = 'RemoteDataSource';

  Future<T?> _call<T>(
    String operation,
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) parse,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map && body['success'] == true) {
        final data = body['data'];
        return data == null ? null : parse(data);
      }
      final error = body is Map ? body['error'] : body;
      debugPrint('$_tag $operation failed: HTTP ${response.statusCode} - $error');
      return null;
    } on DioException catch (e) {
      debugPrint('$_tag $operation error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('$_tag $operation error: $e');
      return null;
    }
  }

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List)
          .map((e) => fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  Map<String, dynamic> _map(dynamic data) =>
      (data as Map).cast<String, dynamic>();

  // ── Stories ──────────────────────────────────────────────────────────────

  Future<List<StoryDto>?> getAllStories() => _call(
        'getAllStories',
        () => _dio.get('stories.php'),
        (d) => _list(d, StoryDto.fromJson),
      );

  Future<MutationResult?> createStory(CreateStoryRequest r) => _call(
        'createStory',
        () => _dio.post('stories.php', data: r.toJson()),
        (d) => MutationResult.parse(d),
      );

  Future<MutationResult?> updateStory(int id, UpdateStoryRequest r) => _call(
        'updateStory($id)',
        () => _dio.put('stories.php', queryParameters: {'id': id}, data: r.toJson()),
        (d) => MutationResult.parse(d),
      );

  Future<MutationResult?> deleteStory(int id) => _call(
        'deleteStory($id)',
        () => _dio.delete('stories.php', queryParameters: {'id': id}),
        (d) => MutationResult.parse(d),
      );

  // ── Chapters ─────────────────────────────────────────────────────────────

  Future<List<ChapterDto>?> getChaptersForStory(int storyId) => _call(
        'getChapters(storyId=$storyId)',
        () => _dio.get('chapters.php', queryParameters: {'storyId': storyId}),
        (d) => _list(d, ChapterDto.fromJson),
      );

  /// Full chapter including contentHtml (the list endpoint omits it).
  Future<ChapterDto?> getChapter(int id) => _call(
        'getChapter($id)',
        () => _dio.get('chapters.php', queryParameters: {'id': id}),
        (d) => ChapterDto.fromJson(_map(d)),
      );

  Future<MutationResult?> createChapter(CreateChapterRequest r) => _call(
        'createChapter',
        () => _dio.post('chapters.php', data: r.toJson()),
        (d) => MutationResult.parse(d),
      );

  Future<MutationResult?> updateChapter(int id, UpdateChapterRequest r) => _call(
        'updateChapter($id)',
        () => _dio.put('chapters.php', queryParameters: {'id': id}, data: r.toJson()),
        (d) => MutationResult.parse(d),
      );

  Future<MutationResult?> deleteChapter(int id) => _call(
        'deleteChapter($id)',
        () => _dio.delete('chapters.php', queryParameters: {'id': id}),
        (d) => MutationResult.parse(d),
      );

  // ── Character groups ─────────────────────────────────────────────────────

  Future<List<CharacterGroupDto>?> getGroupsForStory(int storyId) => _call(
        'getGroups(storyId=$storyId)',
        () => _dio.get('character_groups.php', queryParameters: {'storyId': storyId}),
        (d) => _list(d, CharacterGroupDto.fromJson),
      );

  Future<MutationResult?> createGroup(CreateGroupRequest r) => _call(
        'createGroup',
        () => _dio.post('character_groups.php', data: r.toJson()),
        (d) => MutationResult.parse(d),
      );

  Future<MutationResult?> updateGroup(int id, UpdateGroupRequest r) => _call(
        'updateGroup($id)',
        () => _dio.put('character_groups.php', queryParameters: {'id': id}, data: r.toJson()),
        (d) => MutationResult.parse(d),
      );

  Future<MutationResult?> deleteGroup(int id) => _call(
        'deleteGroup($id)',
        () => _dio.delete('character_groups.php', queryParameters: {'id': id}),
        (d) => MutationResult.parse(d),
      );

  // ── Characters ───────────────────────────────────────────────────────────

  /// Used during the story-level pull (all characters of a story at once).
  Future<List<CharacterDto>?> getCharactersForStory(int storyId) => _call(
        'getCharacters(storyId=$storyId)',
        () => _dio.get('characters.php', queryParameters: {'storyId': storyId}),
        (d) => _list(d, CharacterDto.fromJson),
      );

  Future<List<CharacterDto>?> getCharactersForGroup(int groupId) => _call(
        'getCharacters(groupId=$groupId)',
        () => _dio.get('characters.php', queryParameters: {'groupId': groupId}),
        (d) => _list(d, CharacterDto.fromJson),
      );

  Future<MutationResult?> createCharacter(CreateCharacterRequest r) => _call(
        'createCharacter',
        () => _dio.post('characters.php', data: r.toJson()),
        (d) => MutationResult.parse(d),
      );

  Future<MutationResult?> updateCharacter(int id, UpdateCharacterRequest r) => _call(
        'updateCharacter($id)',
        () => _dio.put('characters.php', queryParameters: {'id': id}, data: r.toJson()),
        (d) => MutationResult.parse(d),
      );

  Future<MutationResult?> deleteCharacter(int id) => _call(
        'deleteCharacter($id)',
        () => _dio.delete('characters.php', queryParameters: {'id': id}),
        (d) => MutationResult.parse(d),
      );

  // ── Timeline frames ──────────────────────────────────────────────────────

  Future<List<TimelineFrameDto>?> getFramesForStory(int storyId) => _call(
        'getFrames(storyId=$storyId)',
        () => _dio.get('timeline_frames.php', queryParameters: {'storyId': storyId}),
        (d) => _list(d, TimelineFrameDto.fromJson),
      );

  Future<MutationResult?> createFrame(CreateFrameRequest r) => _call(
        'createFrame',
        () => _dio.post('timeline_frames.php', data: r.toJson()),
        (d) => MutationResult.parse(d),
      );

  Future<MutationResult?> deleteFrame(int id) => _call(
        'deleteFrame($id)',
        () => _dio.delete('timeline_frames.php', queryParameters: {'id': id}),
        (d) => MutationResult.parse(d),
      );

  // ── Bulk sync ────────────────────────────────────────────────────────────

  Future<SyncResult?> sync(SyncRequest r) => _call(
        'sync',
        () => _dio.post('sync.php', data: r.toJson()),
        (d) => SyncResult.fromJson(_map(d)),
      );
}

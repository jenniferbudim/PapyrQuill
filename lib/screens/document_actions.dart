import '../data/app_database.dart';
import '../repository/papyr_repository.dart';

/// The write operations of DocumentViewModel.kt. Reading (story, chapters) is
/// done with storyProvider / chaptersProvider in providers.dart.
class DocumentActions {
  DocumentActions(this._repo);

  final PapyrRepository _repo;

  /// Appends a chapter at the end: documentOrder is the current chapter count.
  Future<void> createChapter(int storyId, String title) async {
    final count = (await _repo.getChaptersForStory(storyId).first).length;
    await _repo.insertChapter(
      Chapter(
        id: 0,
        storyId: storyId,
        title: title,
        contentHtml: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        timelineFrameId: null,
        timelineOrder: 0,
        documentOrder: count,
      ),
    );
  }

  Future<void> updateStoryTitle(int storyId, String newTitle) async {
    final story = await _repo.getStoryById(storyId).first;
    if (story == null) return;
    await _repo.updateStory(story.copyWith(title: newTitle));
  }

  /// The description is stored in the story's previewText.
  Future<void> updateStoryDescription(int storyId, String newDescription) async {
    final story = await _repo.getStoryById(storyId).first;
    if (story == null) return;
    await _repo.updateStory(story.copyWith(previewText: newDescription));
  }

  Future<void> reorderChapters(List<Chapter> reordered) =>
      _repo.reorderChapters(reordered);

  Future<void> renameChapter(Chapter chapter, String newTitle) =>
      _repo.updateChapter(chapter.copyWith(title: newTitle));

  Future<void> deleteChapter(Chapter chapter) => _repo.deleteChapter(chapter);
}

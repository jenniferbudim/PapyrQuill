import '../data/app_database.dart';
import '../repository/papyr_repository.dart';

/// The write operations of TimelineViewModel.kt. Reading uses framesProvider
/// and chaptersProvider in providers.dart.
class TimelineActions {
  TimelineActions(this._repo);

  final PapyrRepository _repo;

  /// Adds a frame at the end: frameOrder is the current frame count.
  Future<void> createFrame(int storyId, String name, int currentFrameCount) =>
      _repo.insertFrame(
        TimelineFrame(
          id: 0,
          storyId: storyId,
          name: name,
          frameOrder: currentFrameCount,
        ),
      );

  Future<void> reorderFrames(List<TimelineFrame> ordered) =>
      _repo.reorderFrames(ordered);

  /// Assigns an unassigned chapter to a frame, or moves a chapter from one
  /// frame to another.
  Future<void> placeChapterInFrame(int chapterId, int frameId) =>
      _repo.placeChapterInFrame(chapterId, frameId);

  Future<void> reorderChaptersInFrame(List<Chapter> ordered) =>
      _repo.reorderChaptersInFrame(ordered);

  Future<void> deleteFrame(TimelineFrame frame) => _repo.deleteFrame(frame);
}

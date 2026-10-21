import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database.dart';
import 'network/api_config.dart';
import 'network/remote_data_source.dart';
import 'network/sync_manager.dart';
import 'network/xampp_launcher.dart';
import 'repository/papyr_repository.dart';
import 'screens/character_actions.dart';
import 'screens/document_actions.dart';
import 'screens/timeline_actions.dart';

/// Overridden in main() with the loaded instance.
final apiConfigProvider = Provider<ApiConfig>(
  (ref) => throw UnimplementedError('apiConfigProvider must be overridden'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final remoteDataSourceProvider = Provider<RemoteDataSource>(
  (ref) => RemoteDataSource(ref.watch(apiConfigProvider).dio),
);

final syncManagerProvider = Provider<SyncManager>(
  (ref) => SyncManager(
    ref.watch(remoteDataSourceProvider),
    ref.watch(databaseProvider),
  ),
);

final repositoryProvider = Provider<PapyrRepository>(
  (ref) => PapyrRepository(
    ref.watch(databaseProvider),
    ref.watch(syncManagerProvider),
  ),
);

/// Runs once when the home screen first appears: sends rows created while
/// offline, then pulls the story list. (Kotlin: HomeViewModel's init block.)
final startupSyncProvider = FutureProvider<void>((ref) async {
  // Windows: make sure XAMPP's Apache and MySQL are running first (no-op on
  // Android, or when the server address is not this PC).
  await XamppLauncher.startIfNeeded(ref.read(apiConfigProvider).baseUrl);
  await ref.read(repositoryProvider).refreshStories();
});

/// Replaces HomeViewModel's story list Flow.
final storiesProvider = StreamProvider<List<Story>>(
  (ref) => ref.watch(repositoryProvider).getAllStories(),
);

/// Replaces DocumentViewModel's story / chapters state.
final storyProvider = StreamProvider.family<Story?, int>(
  (ref, storyId) => ref.watch(repositoryProvider).getStoryById(storyId),
);

final chaptersProvider = StreamProvider.family<List<Chapter>, int>(
  (ref, storyId) => ref.watch(repositoryProvider).getChaptersForStory(storyId),
);

final documentActionsProvider = Provider<DocumentActions>(
  (ref) => DocumentActions(ref.watch(repositoryProvider)),
);

/// Replaces CharacterViewModel's groups / characters state.
final groupsProvider = StreamProvider.family<List<CharacterGroup>, int>(
  (ref, storyId) => ref.watch(repositoryProvider).getGroupsForStory(storyId),
);

final charactersProvider = StreamProvider.family<List<StoryCharacter>, int>(
  (ref, groupId) => ref.watch(repositoryProvider).getCharactersForGroup(groupId),
);

/// All characters of a story (every group), for links between characters.
final allCharactersProvider = StreamProvider.family<List<StoryCharacter>, int>(
  (ref, storyId) => ref.watch(repositoryProvider).getCharactersForStory(storyId),
);

final characterActionsProvider = Provider<CharacterActions>(
  (ref) => CharacterActions(ref.watch(repositoryProvider)),
);

/// Replaces TimelineViewModel's frames state. The chapters come from
/// [chaptersProvider]; the screen groups them by frame.
final framesProvider = StreamProvider.family<List<TimelineFrame>, int>(
  (ref, storyId) => ref.watch(repositoryProvider).getFramesForStory(storyId),
);

final timelineActionsProvider = Provider<TimelineActions>(
  (ref) => TimelineActions(ref.watch(repositoryProvider)),
);

import 'dart:async';

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
/// How the last sync went, shown on the Home screen.
enum SyncStatus { unknown, syncing, success, offline }

final syncStatusProvider = StateProvider<SyncStatus>((_) => SyncStatus.unknown);

/// Syncs and updates [syncStatusProvider]: success, or offline mode when the
/// server cannot be reached or rows are still waiting to be sent.
Future<bool> runSyncNow(WidgetRef ref) async {
  ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
  bool ok;
  try {
    ok = await ref.read(repositoryProvider).syncNow();
  } catch (_) {
    ok = false;
  }
  ref.read(syncStatusProvider.notifier).state =
      ok ? SyncStatus.success : SyncStatus.offline;
  return ok;
}

final startupSyncProvider = FutureProvider<void>((ref) async {
  // Windows: make sure XAMPP's Apache and MySQL are running first (no-op on
  // Android, or when the server address is not this PC).
  await XamppLauncher.startIfNeeded(ref.read(apiConfigProvider).baseUrl);
  bool ok;
  try {
    ok = await ref.read(repositoryProvider).syncNow();
  } catch (_) {
    ok = false;
  }
  ref.read(syncStatusProvider.notifier).state =
      ok ? SyncStatus.success : SyncStatus.offline;

  // From now on, sync by itself every 45 seconds, so edits made on another
  // device show up (and edits made here while offline get sent) without
  // pressing anything.
  final timer = Timer.periodic(const Duration(seconds: 45), (_) async {
    if (ref.read(syncStatusProvider) == SyncStatus.syncing) return;
    bool ok;
    try {
      ok = await ref.read(repositoryProvider).syncNow();
    } catch (_) {
      ok = false;
    }
    ref.read(syncStatusProvider.notifier).state =
        ok ? SyncStatus.success : SyncStatus.offline;
  });
  ref.onDispose(timer.cancel);
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

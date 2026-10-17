import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'document_screen.dart';

/// Port of HomeScreen.kt + HomeViewModel.kt.
///
/// A pill-shaped search box, then the story cards. Tap a card to open the
/// story, long-press (or right-click) to delete, and tap the heart to
/// favorite. Pull down to sync with the server. The gear next to the search box
/// sets the server address (the Kotlin app had it hard-coded).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _maxContentWidth = 820.0;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Story> _filter(List<Story> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((s) => s.title.toLowerCase().contains(q)).toList();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBeige,
        title: const Text('Create New Story',
            style: TextStyle(color: darkPink, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: darkPink),
          decoration: const InputDecoration(
            labelText: 'Story Name',
            labelStyle: TextStyle(color: darkPink),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: darkPink),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: darkPink, width: 2),
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: darkPink)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: darkPink,
              foregroundColor: cardBeige,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) return;
    await ref.read(repositoryProvider).insertStory(
          Story(
            id: 0, // 0 = let the repository pick a temporary id
            title: title.trim(),
            previewText: '',
            isFavorite: false,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> _confirmDelete(Story story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBeige,
        title: const Text('Delete Story?',
            style: TextStyle(color: darkPink, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to delete '${story.title}'? "
          'This cannot be undone.',
          style: const TextStyle(color: darkPink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: darkPink)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: darkPink,
              foregroundColor: colorBackground,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(repositoryProvider).deleteStory(story);
    }
  }

  void _openStory(Story story) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // The name lets the character screens' bookmark return here.
        settings: const RouteSettings(name: 'document'),
        builder: (_) => DocumentScreen(storyId: story.id),
      ),
    );
  }

  Future<void> _showServerDialog() async {
    final config = ref.read(apiConfigProvider);
    final controller = TextEditingController(text: config.baseUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBeige,
        title: const Text('Server address',
            style: TextStyle(color: darkPink, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API base URL',
                hintText: 'http://192.168.1.10/papyrquill/api/',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Phone: your PC\'s Wi-Fi IP. Windows on the same PC: localhost.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: darkPink)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: darkPink,
              foregroundColor: cardBeige,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (url != null) await config.setBaseUrl(url);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: searchTextColor),
            cursorColor: searchTextColor,
            decoration: InputDecoration(
              hintText: 'Search documents',
              hintStyle: TextStyle(
                color: searchTextColor.withValues(alpha: 0.7),
                fontSize: 15,
              ),
              prefixIcon: const Icon(Icons.search, color: searchTextColor),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close, color: searchTextColor),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: mediumPink,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Server settings',
          icon: const Icon(Icons.settings, color: darkPink),
          onPressed: _showServerDialog,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // First time only: send rows created offline, then pull the story list.
    ref.watch(startupSyncProvider);
    final stories = ref.watch(storiesProvider);
    final repo = ref.watch(repositoryProvider);

    final width = MediaQuery.sizeOf(context).width;
    final side =
        width > _maxContentWidth + 32 ? (width - _maxContentWidth) / 2 : 16.0;

    return Scaffold(
      backgroundColor: colorBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: mediumPink,
        foregroundColor: darkPink,
        shape: const CircleBorder(),
        tooltip: 'Add New Story',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(side, 14, side - 8, 14),
              child: _searchBar(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: repo.refreshStories,
                child: stories.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (all) {
                    final list = _filter(all);
                    if (list.isEmpty) {
                      // A ListView so pull-to-refresh still works when empty.
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              all.isEmpty
                                  ? 'No stories yet. Tap + to add one.'
                                  : 'No stories match your search.',
                              style: const TextStyle(color: cardBodyColor),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // 88 at the bottom clears the + button.
                      padding: EdgeInsets.fromLTRB(side, 0, side, 88),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final story = list[i];
                        return _StoryCard(
                          key: ValueKey(story.id),
                          story: story,
                          onTap: () => _openStory(story),
                          onDelete: () => _confirmDelete(story),
                          onToggleFavorite: () => repo.updateStory(
                            story.copyWith(isFavorite: !story.isFavorite),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final Story story;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: cardBeige,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onDelete,
          // Right-click is the mouse equivalent on Windows.
          onSecondaryTap: onDelete,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: cardTitleColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.previewText.isEmpty
                            ? 'No content yet...'
                            : story.previewText,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: cardBodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Favorite',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    story.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: story.isFavorite ? heartActive : heartInactive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

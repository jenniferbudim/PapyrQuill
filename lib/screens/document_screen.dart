import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../editor/html_codec.dart';
import '../export/docx_exporter.dart';
import '../providers.dart';
import '../repository/papyr_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_tabs.dart';
import '../widgets/desktop_shell.dart';
import '../widgets/rename_dialog.dart';
import '../widgets/unsaved_dialog.dart';
import 'character_group_screen.dart';
import 'document_actions.dart';
import 'editor_screen.dart';
import 'timeline_screen.dart';

/// Port of DocumentScreen.kt + DocumentViewModel.kt.
///
/// Header with an editable title and description, then the story's chapters.
/// Tap a chapter to edit it, long-press (or use the menu) to delete, and drag
/// the handle to reorder.
class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key, required this.storyId});

  final int storyId;

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  static const _maxContentWidth = 820.0;

  late final PapyrRepository _repo;
  late final DocumentActions _actions;

  /// The story's current id. A story created offline gets its real id when it
  /// is sent to the server, which can happen while this screen is open.
  int get _storyId => _repo.resolveStoryId(widget.storyId);


  final _chapterScroll = ScrollController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _editingTitle = false;
  bool _editingDescription = false;

  /// While you drag a chapter: its index (for the pink highlight).
  int? _draggingIndex;

  /// The order you just dropped, shown until the database stream catches up.
  List<Chapter>? _orderOverride;

  late final LeaveGuardHolder _guard;
  Future<bool> Function()? _previousLeaveGuard;

  /// Asks before the Windows window is closed with an unsaved title edit.
  AppLifecycleListener? _exitListener;

  @override
  void initState() {
    super.initState();
    _exitListener = AppLifecycleListener(onExitRequested: _onExitRequested);
    _guard = LeaveGuardHolder.of(context);
    _previousLeaveGuard = _guard.check;
    _guard.check = _confirmLeave;
    _repo = ref.read(repositoryProvider);
    _actions = ref.read(documentActionsProvider);
    // Pull the latest from the server. The database streams update the UI.
    unawaited(_repo.refreshStoryData(_storyId));
  }

  @override
  void dispose() {
    // Hand the check back to the screen underneath, if there is one.
    if (_guard.check == _confirmLeave) {
      _guard.check = _previousLeaveGuard;
    }
    _exitListener?.dispose();
    _chapterScroll.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Leaving with an unsaved title or description ──────────────────────────

  /// True when the title or description box is open and its text differs from
  /// what is stored.
  bool get _hasUnsavedEdits {
    final story = ref.read(storyProvider(_storyId)).valueOrNull;
    if (story == null) return false;
    final titleChanged = _editingTitle &&
        _titleController.text.trim().isNotEmpty &&
        _titleController.text.trim() != story.title;
    final descriptionChanged =
        _editingDescription && _descriptionController.text != story.previewText;
    return titleChanged || descriptionChanged;
  }

  Future<void> _saveOpenEdits() async {
    if (_editingTitle) await _saveTitle();
    if (_editingDescription) await _saveDescription();
  }

  /// Back button / swipe back while a title or description box is open.
  Future<void> _onBackWhileEditing() async {
    if (!_hasUnsavedEdits) {
      Navigator.of(context).pop();
      return;
    }
    final choice = await askUnsavedChanges(
      context,
      message: 'Your title or description changes are not saved yet. '
          'Save them before leaving?',
    );
    if (!mounted) return;
    switch (choice) {
      case LeaveChoice.save:
        await _saveOpenEdits();
        if (mounted) Navigator.of(context).pop();
      case LeaveChoice.discard:
        Navigator.of(context).pop();
      case LeaveChoice.keepEditing:
        break;
    }
  }

  /// Clicking the logo or another story on Windows: true if it is fine to
  /// leave.
  Future<bool> _confirmLeave() async {
    if (!mounted || !_hasUnsavedEdits) return true;
    final choice = await askUnsavedChanges(
      context,
      message: 'Your title or description changes are not saved yet. '
          'Save them before leaving?',
    );
    switch (choice) {
      case LeaveChoice.save:
        await _saveOpenEdits();
        return true;
      case LeaveChoice.discard:
        return true;
      case LeaveChoice.keepEditing:
        return false;
    }
  }

  /// The Windows window's close button.
  Future<AppExitResponse> _onExitRequested() async {
    if (!mounted || !_hasUnsavedEdits) return AppExitResponse.exit;
    final choice = await askUnsavedChanges(
      context,
      message: 'Your title or description changes are not saved yet. '
          'Save them before closing?',
    );
    switch (choice) {
      case LeaveChoice.save:
        await _saveOpenEdits();
        return AppExitResponse.exit;
      case LeaveChoice.discard:
        return AppExitResponse.exit;
      case LeaveChoice.keepEditing:
        return AppExitResponse.cancel;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _openChapter(Chapter chapter) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(chapterId: chapter.id),
      ),
    );
  }

  /// Windows tabs: middle-click or Ctrl+click on a chapter.
  void _openChapterInNewTab(Chapter chapter) {
    openInNewTab(context, [
      TabPage(DocumentScreen(storyId: _storyId), routeName: 'document'),
      TabPage(EditorScreen(chapterId: chapter.id)),
    ]);
  }

  void _openCharacters() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CharacterGroupScreen(storyId: _storyId),
      ),
    );
  }

  void _openTimeline() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TimelineScreen(storyId: _storyId),
      ),
    );
  }

  void _onReorder(List<Chapter> current, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex == oldIndex) return;
    final list = List<Chapter>.of(current);
    list.insert(newIndex, list.removeAt(oldIndex));
    setState(() => _orderOverride = list);
    unawaited(_actions.reorderChapters(list));
  }

  /// Exports the whole story: title, description and all chapters.
  Future<void> _shareStory(Story? story, List<Chapter> chapters) async {
    final title = story?.title ?? 'Story';
    final bytes = buildStoryDocx(
      storyTitle: title,
      description: story?.previewText ?? '',
      chapters: chapters,
    );
    await deliverDocx(context, title: title, bytes: bytes);
  }

  Future<void> _showAddChapterDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorBackground,
        title: const Text('New Chapter', style: TextStyle(color: cardTitleColor)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Chapter Title'),
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
              foregroundColor: colorBackground,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    await _actions.createChapter(_storyId, name.trim());
  }

  Future<void> _rename(Chapter chapter) async {
    final title = await askChapterTitle(context, chapter.title);
    if (title == null) return;
    await _actions.renameChapter(chapter, title);
  }

  Future<void> _confirmDelete(Chapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorBackground,
        title: const Text('Delete Chapter?', style: TextStyle(color: cardTitleColor)),
        content: Text(
          'Delete "${chapter.title}"? This cannot be undone.',
          style: const TextStyle(color: cardBodyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: cardBodyColor)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _actions.deleteChapter(chapter);
  }

  // ── Windows layout ───────────────────────────────────────────────────────

  /// Switches to another story from the sidebar without an animation.
  Future<void> _switchStory(Story target) async {
    if (target.id == _storyId) return;
    if (!await _confirmLeave() || !mounted) return;
    Navigator.of(context).pushReplacement(
      instantRoute<void>(DocumentScreen(storyId: target.id), name: 'document'),
    );
  }

  Widget _chapterSliver(
    List<Chapter> shown,
    EdgeInsets padding, {
    bool compact = false,
  }) {
    return SliverPadding(
      padding: padding,
      sliver: SliverReorderableList(
        itemCount: shown.length,
        onReorderStart: (i) => setState(() => _draggingIndex = i),
        onReorderEnd: (_) => setState(() => _draggingIndex = null),
        onReorder: (oldIndex, newIndex) =>
            _onReorder(shown, oldIndex, newIndex),
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(compact ? 8 : 14),
          child: child,
        ),
        itemBuilder: (context, index) {
          final chapter = shown[index];
          return Padding(
            key: ValueKey(chapter.id),
            padding: EdgeInsets.only(bottom: compact ? 11 : 8),
            child: MiddleClickable(
              onMiddleClick: () => _openChapterInNewTab(chapter),
              child: _ChapterCard(
                chapter: chapter,
                index: index,
                compact: compact,
                isDragging: _draggingIndex == index,
                onTap: () => compact && isCtrlPressed()
                    ? _openChapterInNewTab(chapter)
                    : _openChapter(chapter),
                onRename: () => _rename(chapter),
                onDelete: () => _confirmDelete(chapter),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktop(Story? story, List<Chapter> shown) {
    final stories =
        ref.watch(storiesProvider).valueOrNull ?? const <Story>[];
    final selected = stories.indexWhere((s) => s.id == _storyId);

    Widget navImage(String asset, String label, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        child: Tooltip(
          message: label,
          child: SizedBox(
            width: 66,
            height: 70,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !(_editingTitle || _editingDescription),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_onBackWhileEditing());
      },
      child: Scaffold(
        backgroundColor: colorBackground,
        body: DesktopShell(
          title: story?.title,
          sidebar: SidebarList(
            labels: [for (final s in stories) s.title],
            selectedIndex: selected,
            onTap: (i) => _switchStory(stories[i]),
            onOpenInNewTab: (i) => openInNewTab(context, [
              TabPage(DocumentScreen(storyId: stories[i].id),
                  routeName: 'document'),
            ]),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(story, shown, desktop: true),
                  Expanded(
                    child: ScrollbarTheme(
                      data: const ScrollbarThemeData(
                        thumbColor: WidgetStatePropertyAll(desktopScrollThumb),
                        thickness: WidgetStatePropertyAll(6.0),
                        radius: Radius.circular(3),
                        crossAxisMargin: 12,
                      ),
                      child: Scrollbar(
                        controller: _chapterScroll,
                        thumbVisibility: true,
                        child: CustomScrollView(
                          controller: _chapterScroll,
                          slivers: [
                            _chapterSliver(
                              shown,
                              const EdgeInsets.fromLTRB(40, 18, 130, 110),
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Bookmark = characters, hourglass = timeline.
              Positioned(
                left: 22,
                bottom: 0,
                child: Row(
                  children: [
                    navImage('assets/images/bookmark.png', 'Characters',
                        _openCharacters),
                    const SizedBox(width: 6),
                    navImage(
                        'assets/images/hour.png', 'Timeline', _openTimeline),
                  ],
                ),
              ),
              Positioned(
                right: 22,
                bottom: 20,
                child: Tooltip(
                  message: 'Add Chapter',
                  child: Material(
                    color: mediumPink,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _showAddChapterDialog,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.add, size: 30, color: darkPink),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final story = ref.watch(storyProvider(_storyId)).valueOrNull;
    final chapters =
        ref.watch(chaptersProvider(_storyId)).valueOrNull ?? const <Chapter>[];

    // Once the database reports the new order, stop using the dropped order.
    ref.listen<AsyncValue<List<Chapter>>>(chaptersProvider(_storyId),
        (_, __) {
      if (_orderOverride != null && _draggingIndex == null) {
        setState(() => _orderOverride = null);
      }
    });

    final shown = _orderOverride ?? chapters;

    if (useDesktopLayout(context)) return _buildDesktop(story, shown);

    final width = MediaQuery.sizeOf(context).width;
    final sidePadding =
        width > _maxContentWidth + 32 ? (width - _maxContentWidth) / 2 : 16.0;

    return PopScope(
      // While a title or description box is open, Back goes through
      // _onBackWhileEditing so unsaved text is not lost silently.
      canPop: !(_editingTitle || _editingDescription),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_onBackWhileEditing());
      },
      child: Scaffold(
      backgroundColor: colorBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChapterDialog,
        backgroundColor: mediumPink,
        foregroundColor: darkPink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tooltip: 'Add Chapter',
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(story, shown)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverPadding(
            // Centers the list on wide windows (Windows) and keeps a 16px
            // margin on phones.
            padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 88),
            sliver: SliverReorderableList(
              itemCount: shown.length,
              onReorderStart: (i) => setState(() => _draggingIndex = i),
              onReorderEnd: (_) => setState(() => _draggingIndex = null),
              onReorder: (oldIndex, newIndex) =>
                  _onReorder(shown, oldIndex, newIndex),
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                child: child,
              ),
              itemBuilder: (context, index) {
                final chapter = shown[index];
                return Padding(
                  key: ValueKey(chapter.id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChapterCard(
                    chapter: chapter,
                    index: index,
                    isDragging: _draggingIndex == index,
                    onTap: () => _openChapter(chapter),
                    onRename: () => _rename(chapter),
                    onDelete: () => _confirmDelete(chapter),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBottomBar() {
    Widget navImage(String asset, String label, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        child: Tooltip(
          message: label,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        ),
      );
    }

    return Material(
      color: colorBackground,
      child: SafeArea(
        child: SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                navImage('assets/images/bookmark.png', 'Characters', _openCharacters),
                navImage('assets/images/hour.png', 'Timeline', _openTimeline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Story? story, List<Chapter> shown,
      {bool desktop = false}) {
    final titleStyle = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: desktop ? 27 : 30,
      color: headerTitleColor,
    );
    final descriptionStyle = TextStyle(
      fontSize: desktop ? 12 : 14,
      height: 1.45,
      color: headerBodyColor,
    );
    final fieldBorder = OutlineInputBorder(
      borderSide: BorderSide(color: darkPink.withValues(alpha: 0.4)),
    );
    const focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: darkPink),
    );

    return Material(
      color: headerCardPink,
      // Soft rounded bottom corners, like the reference card.
      shape: RoundedRectangleBorder(
        borderRadius: desktop
            ? BorderRadius.zero
            : const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: desktop ? double.infinity : _maxContentWidth),
            child: Stack(
              children: [
                Padding(
                  padding: desktop
                      ? const EdgeInsets.fromLTRB(44, 26, 72, 22)
                      : const EdgeInsets.fromLTRB(24, 24, 56, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Editable title
                      if (_editingTitle)
                        TextField(
                          controller: _titleController,
                          autofocus: true,
                          style: titleStyle,
                          cursorColor: darkPink,
                          decoration: InputDecoration(
                            border: fieldBorder,
                            enabledBorder: fieldBorder,
                            focusedBorder: focusedBorder,
                            suffixIcon: IconButton(
                              tooltip: 'Confirm',
                              icon: const Icon(Icons.check, color: darkPink),
                              onPressed: _saveTitle,
                            ),
                          ),
                          onSubmitted: (_) => _saveTitle(),
                        )
                      else
                        InkWell(
                          onTap: story == null
                              ? null
                              : () => setState(() {
                                    _titleController.text = story.title;
                                    _editingTitle = true;
                                  }),
                          child: Text(
                            story?.title ?? 'Loading...',
                            style: titleStyle,
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Editable description
                      if (_editingDescription) ...[
                        TextField(
                          controller: _descriptionController,
                          autofocus: true,
                          minLines: 2,
                          maxLines: 8,
                          style: descriptionStyle,
                          cursorColor: darkPink,
                          decoration: InputDecoration(
                            border: fieldBorder,
                            enabledBorder: fieldBorder,
                            focusedBorder: focusedBorder,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    setState(() => _editingDescription = false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: cardTitleColor),
                                ),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: darkPink,
                                  foregroundColor: colorBackground,
                                ),
                                onPressed: _saveDescription,
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        InkWell(
                          onTap: story == null
                              ? null
                              : () => setState(() {
                                    _descriptionController.text =
                                        story.previewText;
                                    _editingDescription = true;
                                  }),
                          child: Text(
                            (story?.previewText.isNotEmpty ?? false)
                                ? story!.previewText
                                : 'Tap to add a description...',
                            style: descriptionStyle,
                            maxLines: desktop ? 2 : 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: desktop ? 14 : 12,
                  right: desktop ? 20 : 4,
                  child: IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.share_outlined, color: mediumPink),
                    onPressed: () => unawaited(_shareStory(story, shown)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTitle() async {
    final title = _titleController.text.trim();
    setState(() => _editingTitle = false);
    if (title.isEmpty) return;
    await _actions.updateStoryTitle(_storyId, title);
  }

  Future<void> _saveDescription() async {
    final description = _descriptionController.text;
    setState(() => _editingDescription = false);
    await _actions.updateStoryDescription(_storyId, description);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.index,
    required this.isDragging,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    this.compact = false,
  });

  /// Windows look: smaller, flatter card.
  final bool compact;

  final Chapter chapter;
  final int index;
  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final preview = htmlToPlainText(chapter.contentHtml);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 8 : 14)),
      color: isDragging ? mediumPink : cardBeige,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 12, vertical: compact ? 11 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dragging starts on the handle, so a tap or long-press on the
              // rest of the card still opens or deletes the chapter.
              ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.drag_handle,
                      size: 24,
                      color: cardTitleColor.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: TextStyle(
                        fontWeight:
                            compact ? FontWeight.w500 : FontWeight.bold,
                        fontSize: compact ? 14 : 16,
                        color: cardTitleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.isEmpty ? 'No content yet...' : preview,
                      maxLines: compact ? 2 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 11 : 13,
                        height: compact ? 1.4 : 18 / 13,
                        color:
                            compact ? desktopPreviewColor : cardBodyColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Long-press is awkward with a mouse, so there is also a menu.
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: Icon(
                  Icons.more_vert,
                  color: cardTitleColor.withValues(alpha: 0.5),
                ),
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

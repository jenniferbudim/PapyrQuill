import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../providers.dart';
import '../repository/papyr_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/book_top_header.dart' show backToDocument;
import 'timeline_actions.dart';

/// Port of TimelineScreen.kt + TimelineViewModel.kt.
///
/// A pink card titled "Timeline" holding one card per frame ("Year 1",
/// "Act II", ...). Each frame lists its chapters.
///  - The arrows on the left of a frame move the frame up or down.
///  - The + on a frame picks an unassigned chapter to put in it.
///  - The arrows on a chapter move it up or down inside its frame.
///  - Tap a chapter to move it to another frame, or long-press and drag it onto
///    the other frame's card.
///  - Long-press (or right-click) a frame's name to delete the frame.
///  - The big + at the bottom right adds a frame; the hourglass goes back.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key, required this.storyId});

  final int storyId;

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  static const _maxContentWidth = 560.0;

  late final PapyrRepository _repo;
  late final TimelineActions _actions;
  final ScrollController _scroll = ScrollController();

  /// A story created offline gets its real id while this screen may be open.
  int get _storyId => _repo.resolveStoryId(widget.storyId);

  @override
  void initState() {
    super.initState();
    _repo = ref.read(repositoryProvider);
    _actions = ref.read(timelineActionsProvider);
    unawaited(_repo.refreshStoryData(_storyId));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<void> _showAddFrameDialog(int frameCount) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorBackground,
        title: const Text('New Timeframe',
            style: TextStyle(color: cardTitleColor)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: fieldDecoration('Name (e.g. Year 1)'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: cardTitleColor)),
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
    await _actions.createFrame(_storyId, name.trim(), frameCount);
  }

  Future<void> _confirmDeleteFrame(TimelineFrame frame) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorBackground,
        title: const Text('Delete Timeframe?',
            style: TextStyle(color: cardTitleColor)),
        content: Text(
          'Delete "${frame.name}"? Its chapters will return to the '
          'unassigned pool — they won\'t be deleted.',
          style: const TextStyle(color: cardTitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: cardTitleColor)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: colorBackground,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _actions.deleteFrame(frame);
  }

  // ── Moving frames ─────────────────────────────────────────────────────────

  void _moveFrame(List<TimelineFrame> frames, int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= frames.length) return;
    final list = List<TimelineFrame>.of(frames);
    list.insert(target, list.removeAt(index));
    unawaited(_actions.reorderFrames(list));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final frames =
        ref.watch(framesProvider(_storyId)).valueOrNull ?? const <TimelineFrame>[];
    final chapters =
        ref.watch(chaptersProvider(_storyId)).valueOrNull ?? const <Chapter>[];

    // Group the chapters. A chapter whose frame is unknown counts as
    // unassigned, so it can never disappear from the screen.
    final frameIds = {for (final f in frames) f.id};
    final byFrame = <int, List<Chapter>>{};
    final unassigned = <Chapter>[];
    for (final c in chapters) {
      final fid = c.timelineFrameId;
      if (fid != null && frameIds.contains(fid)) {
        byFrame.putIfAbsent(fid, () => []).add(c);
      } else {
        unassigned.add(c);
      }
    }
    for (final list in byFrame.values) {
      list.sort((a, b) => a.timelineOrder.compareTo(b.timelineOrder));
    }
    unassigned.sort((a, b) => a.documentOrder.compareTo(b.documentOrder));

    final width = MediaQuery.sizeOf(context).width;
    // viewPadding (not padding) so the layout does not change when the
    // keyboard opens.
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    const bandHeight = 30.0;
    // 24 px from the screen edge on phones; centered on wide windows.
    final side =
        width > _maxContentWidth + 48 ? (width - _maxContentWidth) / 2 : 24.0;

    return Scaffold(
      backgroundColor: colorBackground,
      // The keyboard covers the bottom band instead of pushing it up.
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Dark band that peeks out on both sides of the card.
                Positioned(
                  left: 0,
                  right: 0,
                  top: topInset + 15,
                  height: 30,
                  child: const ColoredBox(color: darkPink),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(side, topInset + 9, side, 12),
                    child: _buildCard(frames, byFrame, unassigned),
                  ),
                ),
              ],
            ),
          ),
          // The hourglass stands on the bottom band and returns to the
          // document. Its dark pink base is part of the picture; it overlaps
          // the band by one pixel so there is no gap under it.
          SizedBox(
            height: 111 + bandHeight + bottomInset,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bandHeight + bottomInset,
                  child: const ColoredBox(color: mediumPink),
                ),
                Positioned(
                  left: side > 21 ? side - 13 : 8,
                  bottom: bandHeight + bottomInset - 1,
                  child: InkWell(
                    onTap: () => backToDocument(context),
                    child: Tooltip(
                      message: 'Back to the document',
                      child: Image.asset(
                        'assets/images/hour.png',
                        width: 112,
                        height: 112,
                        fit: BoxFit.contain,
                        // Pixel art: keep the edges crisp.
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    List<TimelineFrame> frames,
    Map<int, List<Chapter>> byFrame,
    List<Chapter> unassigned,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: headerCardPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 18, 22, 10),
                child: Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: timelineTitleColor,
                  ),
                ),
              ),
              Expanded(
                child: frames.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No timeframes yet. Tap + to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: timelineFrameNameColor),
                          ),
                        ),
                      )
                    : ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thumbColor:
                              const WidgetStatePropertyAll(timelineScrollThumb),
                          thickness: const WidgetStatePropertyAll(4.0),
                          radius: const Radius.circular(2),
                          crossAxisMargin: 10,
                        ),
                        child: Scrollbar(
                          controller: _scroll,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(22, 2, 22, 72),
                            itemCount: frames.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final frame = frames[index];
                              return _TimeframeCard(
                                key: ValueKey(frame.id),
                                frame: frame,
                                chapters: byFrame[frame.id] ?? const [],
                                unassigned: unassigned,
                                otherFrames: [
                                  for (final f in frames)
                                    if (f.id != frame.id) f,
                                ],
                                canMoveUp: index > 0,
                                canMoveDown: index < frames.length - 1,
                                onMoveUp: () => _moveFrame(frames, index, -1),
                                onMoveDown: () => _moveFrame(frames, index, 1),
                                onLongPress: () => _confirmDeleteFrame(frame),
                                onAddChapter: (c) => _actions
                                    .placeChapterInFrame(c.id, frame.id),
                                onDropChapter: (id) => _actions
                                    .placeChapterInFrame(id, frame.id),
                                onMoveChapter: (c, target) => _actions
                                    .placeChapterInFrame(c.id, target.id),
                                onReorderChapters:
                                    _actions.reorderChaptersInFrame,
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
          // Add a timeframe.
          Positioned(
            right: 14,
            bottom: 10,
            child: IconButton(
              tooltip: 'Add Timeframe',
              iconSize: 36,
              onPressed: () => _showAddFrameDialog(frames.length),
              icon: const Icon(Icons.add, color: darkPink),
            ),
          ),
        ],
      ),
    );
  }
}

/// One frame with its chapters. Also the drop target for chapters dragged from
/// another frame.
class _TimeframeCard extends StatelessWidget {
  const _TimeframeCard({
    super.key,
    required this.frame,
    required this.chapters,
    required this.unassigned,
    required this.otherFrames,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onLongPress,
    required this.onAddChapter,
    required this.onDropChapter,
    required this.onMoveChapter,
    required this.onReorderChapters,
  });

  final TimelineFrame frame;
  final List<Chapter> chapters;
  final List<Chapter> unassigned;
  final List<TimelineFrame> otherFrames;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onLongPress;
  final void Function(Chapter) onAddChapter;
  final void Function(int chapterId) onDropChapter;
  final void Function(Chapter, TimelineFrame) onMoveChapter;
  final Future<void> Function(List<Chapter>) onReorderChapters;

  void _moveChapter(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= chapters.length) return;
    final list = List<Chapter>.of(chapters);
    list.insert(target, list.removeAt(index));
    unawaited(onReorderChapters(list));
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => !chapters.any((c) => c.id == d.data),
      onAcceptWithDetails: (d) => onDropChapter(d.data),
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: hovering ? lighterPink : lightPink,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.fromLTRB(2, 6, 0, 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Move the frame up / down, centered on the card's height.
                Center(
                  child: _ArrowPair(
                    size: 26,
                    canUp: canMoveUp,
                    canDown: canMoveDown,
                    onUp: onMoveUp,
                    onDown: onMoveDown,
                    upTip: 'Move timeframe up',
                    downTip: 'Move timeframe down',
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: onLongPress,
                        // Right-click is the mouse equivalent on Windows.
                        onSecondaryTap: onLongPress,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                          child: Text(
                            frame.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: timelineFrameNameColor,
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < chapters.length; i++)
                        _ChapterChip(
                          key: ValueKey(chapters[i].id),
                          chapter: chapters[i],
                          otherFrames: otherFrames,
                          canUp: i > 0,
                          canDown: i < chapters.length - 1,
                          onUp: () => _moveChapter(i, -1),
                          onDown: () => _moveChapter(i, 1),
                          onMove: (target) =>
                              onMoveChapter(chapters[i], target),
                        ),
                    ],
                  ),
                ),
                // The + sits above the free space to the right of the chapters.
                SizedBox(
                  width: 39,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: PopupMenuButton<Chapter>(
                      tooltip: 'Add Chapter',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add,
                          size: 28, color: mediumPink),
                      color: colorBackground,
                      onSelected: onAddChapter,
                      itemBuilder: (_) => unassigned.isEmpty
                          ? const [
                              PopupMenuItem<Chapter>(
                                enabled: false,
                                child: Text('No unassigned chapters',
                                    style: TextStyle(
                                        color: timelineFrameNameColor)),
                              ),
                            ]
                          : [
                              for (final c in unassigned)
                                PopupMenuItem<Chapter>(
                                  value: c,
                                  child: Text(c.title,
                                      style: const TextStyle(
                                          color: timelineFrameNameColor)),
                                ),
                            ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A small stacked pair of chevrons (up above down).
class _ArrowPair extends StatelessWidget {
  const _ArrowPair({
    required this.size,
    required this.canUp,
    required this.canDown,
    required this.onUp,
    required this.onDown,
    required this.upTip,
    required this.downTip,
  });

  final double size;
  final bool canUp;
  final bool canDown;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final String upTip;
  final String downTip;

  Widget _button(IconData icon, bool enabled, VoidCallback onTap, String tip) {
    return SizedBox(
      width: size + 4,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tip,
        onPressed: enabled ? onTap : null,
        icon: Icon(
          icon,
          size: size,
          color: enabled ? mediumPink : mediumPink.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.keyboard_arrow_up, canUp, onUp, upTip),
        _button(Icons.keyboard_arrow_down, canDown, onDown, downTip),
      ],
    );
  }
}

class _ChapterChip extends StatelessWidget {
  const _ChapterChip({
    super.key,
    required this.chapter,
    required this.otherFrames,
    required this.canUp,
    required this.canDown,
    required this.onUp,
    required this.onDown,
    required this.onMove,
  });

  final Chapter chapter;
  final List<TimelineFrame> otherFrames;
  final bool canUp;
  final bool canDown;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final void Function(TimelineFrame) onMove;

  Future<void> _showMoveMenu(BuildContext context, Offset at) async {
    final target = await showMenu<TimelineFrame>(
      context: context,
      color: colorBackground,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        for (final f in otherFrames)
          PopupMenuItem<TimelineFrame>(
            value: f,
            child: Text('Move to ${f.name}',
                style: const TextStyle(color: timelineFrameNameColor)),
          ),
      ],
    );
    if (target != null) onMove(target);
  }

  Widget _body(BuildContext context, {bool dragging = false}) {
    final title = Text(
      chapter.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 15, color: timelineChipTextColor),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: headerCardPink,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: dragging
                ? title
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: otherFrames.isEmpty
                        ? null
                        : (d) => _showMoveMenu(context, d.globalPosition),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: title,
                    ),
                  ),
          ),
          if (!dragging)
            _ArrowPair(
              size: 20,
              canUp: canUp,
              canDown: canDown,
              onUp: onUp,
              onDown: onDown,
              upTip: 'Move chapter up',
              downTip: 'Move chapter down',
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chip = Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: _body(context),
    );
    // Long-press and drag onto another frame's card.
    if (otherFrames.isEmpty) return chip;
    return LongPressDraggable<int>(
      data: chapter.id,
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Opacity(
              opacity: 0.92, child: _body(context, dragging: true)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: chip,
    );
  }
}

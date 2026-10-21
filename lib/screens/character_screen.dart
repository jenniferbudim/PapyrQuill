import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../providers.dart';
import '../repository/papyr_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/book_top_header.dart';
import '../widgets/character_links.dart';
import '../widgets/desktop_book.dart';
import '../widgets/desktop_shell.dart';
import 'character_actions.dart';
import 'character_group_screen.dart';

/// Port of CharacterScreen.kt: the characters of one group, as expandable
/// cards.
///
/// Tap a card to expand it. Long-press (or right-click, or the Edit button
/// inside an expanded card) to edit or delete it. The round + adds a
/// character; the tabs at the bottom switch group, and the last tab adds a new
/// group.
class CharacterScreen extends ConsumerStatefulWidget {
  const CharacterScreen({
    super.key,
    required this.storyId,
    required this.initialGroupId,
  });

  final int storyId;
  final int initialGroupId;

  @override
  ConsumerState<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends ConsumerState<CharacterScreen> {
  static const _maxContentWidth = 820.0;

  late final PapyrRepository _repo;
  late final CharacterActions _actions;

  /// The story's current id. A story created offline gets its real id when it
  /// is sent to the server, which can happen while this screen is open.
  int get _storyId => _repo.resolveStoryId(widget.storyId);

  /// The selected group's current id (see [_storyId]).
  int get _groupId => _repo.resolveGroupId(_selectedGroupId);

  late int _selectedGroupId;

  /// The character just opened through a link: its card expands and scrolls
  /// into view.
  int? _highlightId;
  Timer? _highlightTimer;

  /// Scroll position of the phone's card list (see [_openLinked]).
  final ScrollController _listScroll = ScrollController();

  /// The filter box: only characters containing every typed word are shown.
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _listScroll.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _repo = ref.read(repositoryProvider);
    _actions = ref.read(characterActionsProvider);
    _selectedGroupId = widget.initialGroupId;
    unawaited(_repo.refreshStoryData(_storyId));
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  // ── Links between characters ──────────────────────────────────────────────

  List<StoryCharacter> get _allCharacters =>
      ref.read(allCharactersProvider(_storyId)).valueOrNull ??
      const <StoryCharacter>[];

  /// Everyone a character can link to (not itself), with their group's name.
  List<LinkTarget> _linkTargets({int? excludeId}) {
    final groups = ref.read(groupsProvider(_storyId)).valueOrNull ??
        const <CharacterGroup>[];
    final groupName = {for (final g in groups) g.id: g.name};
    return [
      for (final c in _allCharacters)
        if (c.id != excludeId)
          LinkTarget(c.name, groupName[c.groupId] ?? ''),
    ];
  }

  /// A link was tapped: show that character in its own group.
  void _openLinked(StoryCharacter target) {
    _highlightTimer?.cancel();
    _filterController.clear();
    setState(() {
      _filter = '';
      _selectedGroupId = target.groupId;
      _highlightId = target.id;
    });
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _highlightId = null);
    });
    // The phone's list builds cards lazily, so move roughly to the card first;
    // the card then scrolls itself exactly into view.
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || !_listScroll.hasClients) return;
      final list = ref.read(charactersProvider(_groupId)).valueOrNull;
      final i = list?.indexWhere((c) => c.id == target.id) ?? -1;
      if (i <= 0) return;
      final max = _listScroll.position.maxScrollExtent;
      _listScroll.jumpTo((i * 62.0).clamp(0.0, max));
    });
  }

  /// After a rename, points the links that used the old name at the new one.
  Future<void> _renameLinks(int renamedId, String oldName, String newName) async {
    for (final c in _allCharacters) {
      if (c.id == renamedId) continue;
      final description = renameLinkInText(c.description, oldName, newName);
      final attributes = {
        for (final e in c.attributes.entries)
          e.key: renameLinkInText(e.value, oldName, newName),
      };
      var changed = description != c.description;
      for (final e in attributes.entries) {
        if (e.value != c.attributes[e.key]) changed = true;
      }
      if (changed) {
        await _actions.updateCharacter(
          c.copyWith(description: description, attributes: attributes),
        );
      }
    }
  }

  Widget _card(StoryCharacter character, CharacterIndex index) {
    return _CharacterCard(
      key: ValueKey(character.id),
      character: character,
      index: index,
      backlinks: backlinksTo(character, _allCharacters),
      highlight: character.id == _highlightId,
      onOpenLink: _openLinked,
      onEdit: () => _editCharacter(character),
    );
  }

  Future<void> _addCharacter() async {
    final result = await showDialog<CharacterFormResult>(
      context: context,
      builder: (_) => CharacterEditDialog(
        title: 'New Item',
        confirmText: 'Add',
        linkTargets: _linkTargets(),
      ),
    );
    if (result == null) return;
    await _actions.addCharacter(
      storyId: _storyId,
      groupId: _groupId,
      name: result.name,
      description: result.description,
      attributes: result.attributes,
    );
  }

  Future<void> _editCharacter(StoryCharacter character) async {
    final result = await showDialog<CharacterFormResult>(
      context: context,
      builder: (_) => CharacterEditDialog(
        title: 'Edit Character',
        confirmText: 'Save',
        initial: character,
        canDelete: true,
        linkTargets: _linkTargets(excludeId: character.id),
      ),
    );
    if (result == null) return;
    if (result.delete) {
      await _confirmDeleteCharacter(character);
      return;
    }
    await _actions.updateCharacter(
      character.copyWith(
        name: result.name,
        description: result.description,
        attributes: result.attributes,
      ),
    );
    // Keep links from other characters working if the name changed.
    if (result.name.trim() != character.name.trim()) {
      await _renameLinks(character.id, character.name, result.name);
    }
  }

  Future<void> _confirmDeleteCharacter(StoryCharacter character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorBackground,
        title: const Text(
          'Delete character?',
          style: TextStyle(color: cardTitleColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '"${character.name}" will be permanently deleted.',
          style: const TextStyle(color: cardTitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
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
    if (confirmed == true) await _actions.deleteCharacter(character);
  }

  /// The Android app had a deleteGroup action but no button for it.
  Future<void> _confirmDeleteGroup(
    CharacterGroup group,
    List<CharacterGroup> groups,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorBackground,
        title: const Text(
          'Delete group?',
          style: TextStyle(color: cardTitleColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '"${group.name}" and all of its characters will be permanently '
          'deleted.',
          style: const TextStyle(color: cardTitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
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
    if (confirmed != true) return;

    await _actions.deleteGroup(group);
    if (!mounted) return;
    final remaining = groups.where((g) => g.id != group.id).toList();
    if (remaining.isEmpty) {
      Navigator.of(context).pop(); // back to the group picker
    } else {
      setState(() => _selectedGroupId = remaining.first.id);
    }
  }

  void _openGroupPicker() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CharacterGroupScreen(storyId: _storyId),
      ),
    );
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  /// Keeps the characters whose name, description or attributes (trait names
  /// and values) contain every word typed in the filter box, ignoring case.
  List<StoryCharacter> _applyFilter(List<StoryCharacter> all) {
    final words = _filter
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return all;
    return [
      for (final c in all)
        if (_matchesAll(c, words)) c,
    ];
  }

  bool _matchesAll(StoryCharacter c, List<String> words) {
    final text = StringBuffer()
      ..write(c.name)
      ..write('\n')
      ..write(c.description);
    for (final e in c.attributes.entries) {
      text
        ..write('\n')
        ..write(e.key)
        ..write('\n')
        ..write(e.value);
    }
    final haystack = text.toString().toLowerCase();
    return words.every(haystack.contains);
  }

  Widget _filterField({double? width}) {
    final field = TextField(
      controller: _filterController,
      cursorColor: darkPink,
      style: const TextStyle(color: cardTitleColor, fontSize: 14),
      textInputAction: TextInputAction.search,
      onChanged: (v) => setState(() => _filter = v),
      decoration: InputDecoration(
        hintText: 'Filter characters',
        hintStyle: TextStyle(color: darkPink.withValues(alpha: 0.5)),
        isDense: true,
        filled: true,
        fillColor: lightPink,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        prefixIcon: const Icon(Icons.search, color: darkPink, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        suffixIcon: _filter.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear filter',
                icon: const Icon(Icons.close, color: darkPink, size: 18),
                onPressed: () {
                  _filterController.clear();
                  setState(() => _filter = '');
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }

  Widget _buildNoMatches() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Text(
          'No characters match "$_filter"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: darkPink.withValues(alpha: 0.55),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Windows layout ───────────────────────────────────────────────────────

  Widget _buildDesktop(
    List<CharacterGroup> groups,
    List<StoryCharacter> characters,
    CharacterGroup? selectedGroup,
  ) {
    final shown = _applyFilter(characters);
    final index = CharacterIndex(
      ref.watch(allCharactersProvider(_storyId)).valueOrNull ??
          const <StoryCharacter>[],
    );
    return Scaffold(
      backgroundColor: colorBackground,
      body: DesktopShell(
        title: selectedGroup?.name ??
            ref.watch(storyProvider(_storyId)).valueOrNull?.title ??
            'Characters',
        child: DesktopBook(
          onBookmarkClick: () => backToDocument(context),
          child: Stack(
            children: [
              Positioned.fill(
                top: DesktopBook.arcBottom + 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(60, 0, 60, 14),
                      child: Row(
                        children: [
                          Tooltip(
                            message: 'Add character',
                            child: InkWell(
                              onTap: _addCharacter,
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child:
                                    Icon(Icons.add, color: darkPink, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              selectedGroup?.name ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkPink,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _filterField(width: 240),
                          if (selectedGroup != null)
                            PopupMenuButton<String>(
                              tooltip: 'Group options',
                              icon: Icon(Icons.more_vert,
                                  color: darkPink.withValues(alpha: 0.6)),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _confirmDeleteGroup(selectedGroup, groups);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete group'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: shown.isEmpty
                          ? (characters.isEmpty
                              ? _buildEmpty()
                              : _buildNoMatches())
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.fromLTRB(60, 0, 60, 120),
                              child: Wrap(
                                spacing: 36,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: [
                                  for (final character in shown)
                                    SizedBox(
                                      width: 340,
                                      child: _card(character, index),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 28,
                right: 28,
                bottom: 0,
                child: SizedBox(
                  height: 82,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final group in groups)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ArchTab(
                            tooltip: group.name,
                            color:
                                group.id == _groupId ? darkPink : mediumPink,
                            icon: groupIcon(group.iconIndex),
                            iconColor: group.id == _groupId
                                ? colorBackground
                                : Colors.black.withValues(alpha: 0.7),
                            onTap: () =>
                                setState(() => _selectedGroupId = group.id),
                          ),
                        ),
                      _ArchTab(
                        tooltip: 'Add character group',
                        color: lighterPink,
                        icon: Icons.add,
                        iconColor: darkPink,
                        onTap: _openGroupPicker,
                      ),
                    ],
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
    final groups = ref.watch(groupsProvider(_storyId)).valueOrNull ??
        const <CharacterGroup>[];
    final characters =
        ref.watch(charactersProvider(_groupId)).valueOrNull ??
            const <StoryCharacter>[];
    final selectedGroup =
        groups.where((g) => g.id == _groupId).firstOrNull;

    if (useDesktopLayout(context)) {
      return _buildDesktop(groups, characters, selectedGroup);
    }

    final shown = _applyFilter(characters);
    final index = CharacterIndex(
      ref.watch(allCharactersProvider(_storyId)).valueOrNull ??
          const <StoryCharacter>[],
    );

    final width = MediaQuery.sizeOf(context).width;
    final sidePadding =
        width > _maxContentWidth + 40 ? (width - _maxContentWidth) / 2 : 20.0;

    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          Column(
            children: [
              BookTopHeader(onBookmarkClick: () => backToDocument(context)),

              // Round + (add character) and the group name.
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: sidePadding,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Add character',
                      child: Material(
                        color: darkPink,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _addCharacter,
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(Icons.add,
                                color: colorBackground, size: 22),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedGroup?.name ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkPink,
                        ),
                      ),
                    ),
                    if (selectedGroup != null)
                      PopupMenuButton<String>(
                        tooltip: 'Group options',
                        icon: Icon(
                          Icons.more_vert,
                          color: darkPink.withValues(alpha: 0.6),
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDeleteGroup(selectedGroup, groups);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete group'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Filter by name, description or attributes.
              Padding(
                padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 10),
                child: _filterField(),
              ),

              // Character cards.
              Expanded(
                child: shown.isEmpty
                    ? (characters.isEmpty ? _buildEmpty() : _buildNoMatches())
                    : ListView.separated(
                        controller: _listScroll,
                        padding:
                            EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 120),
                        itemCount: shown.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          return _card(shown[i], index);
                        },
                      ),
              ),
            ],
          ),

          // Bottom tabs: one per group, then the add-group tab.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 82,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final group in groups)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _ArchTab(
                          tooltip: group.name,
                          color: group.id == _groupId
                              ? darkPink
                              : mediumPink,
                          icon: groupIcon(group.iconIndex),
                          iconColor: group.id == _groupId
                              ? colorBackground
                              : Colors.black.withValues(alpha: 0.7),
                          onTap: () =>
                              setState(() => _selectedGroupId = group.id),
                        ),
                      ),
                    _ArchTab(
                      tooltip: 'Add character group',
                      color: lighterPink,
                      icon: Icons.add,
                      iconColor: darkPink,
                      onTap: _openGroupPicker,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: mediumPink, size: 52),
            const SizedBox(height: 8),
            Text(
              'No items yet',
              style: TextStyle(
                color: darkPink.withValues(alpha: 0.45),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom tab ───────────────────────────────────────────────────────────────

class _ArchTab extends StatelessWidget {
  const _ArchTab({
    required this.tooltip,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String tooltip;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: archTabShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 65,
            height: 82,
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
      ),
    );
  }
}

// ── Character card ───────────────────────────────────────────────────────────

class _CharacterCard extends StatefulWidget {
  const _CharacterCard({
    super.key,
    required this.character,
    required this.onEdit,
    required this.index,
    required this.onOpenLink,
    this.backlinks = const [],
    this.highlight = false,
  });

  final StoryCharacter character;
  final VoidCallback onEdit;

  /// Resolves `[[Name]]` links in the text.
  final CharacterIndex index;
  final ValueChanged<StoryCharacter> onOpenLink;

  /// Characters whose text links to this one.
  final List<StoryCharacter> backlinks;

  /// True while this card was just opened through a link: it expands and
  /// scrolls into view.
  final bool highlight;

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard> {
  late bool _expanded = widget.highlight;

  @override
  void initState() {
    super.initState();
    if (widget.highlight) _scrollIntoView();
  }

  @override
  void didUpdateWidget(_CharacterCard old) {
    super.didUpdateWidget(old);
    if (widget.highlight && !old.highlight) {
      setState(() => _expanded = true);
      _scrollIntoView();
    }
  }

  void _scrollIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final character = widget.character;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: lighterPink,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        onLongPress: widget.onEdit,
        onSecondaryTap: widget.onEdit, // right-click on Windows
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      character.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: darkPink,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 22,
                    color: darkPink.withValues(alpha: 0.6),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: _expanded
                    ? _buildDetails(character)
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(StoryCharacter character) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (character.description.trim().isNotEmpty) ...[
            LinkedText(
              character.description,
              index: widget.index,
              onOpen: widget.onOpenLink,
              style: const TextStyle(fontSize: 14, height: 20 / 14, color: darkPink),
            ),
            const SizedBox(height: 8),
          ],
          Divider(height: 1, color: mediumPink.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          for (final entry in character.attributes.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: LinkedText(
                entry.value,
                index: widget.index,
                onOpen: widget.onOpenLink,
                style: const TextStyle(fontSize: 13, color: darkPink),
                leading: [
                  TextSpan(
                    text: '${entry.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          if (widget.backlinks.isNotEmpty) ...[
            const SizedBox(height: 8),
            LinkedText(
              widget.backlinks.map((c) => linkToken(c.name)).join(', '),
              index: widget.index,
              onOpen: widget.onOpenLink,
              style: TextStyle(
                fontSize: 12,
                color: darkPink.withValues(alpha: 0.75),
              ),
              leading: const [
                TextSpan(
                  text: 'Linked from: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
          // Long-press is awkward with a mouse, so there is also a button.
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit, size: 16, color: darkPink),
              label: const Text('Edit', style: TextStyle(color: darkPink)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add / edit dialog ────────────────────────────────────────────────────────

class CharacterFormResult {
  const CharacterFormResult({
    required this.name,
    required this.description,
    required this.attributes,
  }) : delete = false;

  /// The user tapped the delete icon.
  const CharacterFormResult.deleteRequest()
      : name = '',
        description = '',
        attributes = const {},
        delete = true;

  final String name;
  final String description;
  final Map<String, String> attributes;
  final bool delete;
}

class _AttributeRow {
  _AttributeRow([String key = '', String value = ''])
      : key = TextEditingController(text: key),
        value = TextEditingController(text: value);

  final TextEditingController key;
  final TextEditingController value;

  void dispose() {
    key.dispose();
    value.dispose();
  }
}

class CharacterEditDialog extends StatefulWidget {
  const CharacterEditDialog({
    super.key,
    required this.title,
    required this.confirmText,
    this.initial,
    this.canDelete = false,
    this.linkTargets = const [],
  });

  final String title;
  final String confirmText;
  final StoryCharacter? initial;
  final bool canDelete;

  /// Characters the text can link to. Empty hides the link buttons.
  final List<LinkTarget> linkTargets;

  @override
  State<CharacterEditDialog> createState() => _CharacterEditDialogState();
}

class _CharacterEditDialogState extends State<CharacterEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final List<_AttributeRow> _rows;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _rows = (initial != null && initial.attributes.isNotEmpty)
        ? [
            for (final e in initial.attributes.entries)
              _AttributeRow(e.key, e.value),
          ]
        : [_AttributeRow()];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// A small "link" button inside a text field.
  Widget? _linkButton(TextEditingController controller) {
    if (widget.linkTargets.isEmpty) return null;
    return IconButton(
      tooltip: 'Link to a character',
      iconSize: 18,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      icon: const Icon(Icons.link, color: darkPink),
      onPressed: () => _insertLink(controller),
    );
  }

  /// Inserts `[[Name]]` where the cursor is in [controller].
  Future<void> _insertLink(TextEditingController controller) async {
    final name = await pickCharacterToLink(context, widget.linkTargets);
    if (name == null || !mounted) return;
    final text = controller.text;
    final sel = controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final token = linkToken(name);
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, token),
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final attributes = <String, String>{};
    for (final row in _rows) {
      final key = row.key.text.trim();
      if (key.isNotEmpty) attributes[key] = row.value.text;
    }
    Navigator.pop(
      context,
      CharacterFormResult(
        name: name,
        description: _description.text,
        attributes: attributes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(color: darkPink);

    return AlertDialog(
      scrollable: true,
      backgroundColor: colorBackground,
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: cardTitleColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.canDelete)
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              onPressed: () =>
                  Navigator.pop(context, const CharacterFormResult.deleteRequest()),
            ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              cursorColor: darkPink,
              style: textStyle,
              decoration: fieldDecoration('Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 8,
              cursorColor: darkPink,
              style: textStyle,
              decoration: fieldDecoration('Description').copyWith(
                suffixIcon: _linkButton(_description),
                helperText: widget.linkTargets.isEmpty
                    ? null
                    : 'Use the link button to mention another character.',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Attributes',
              style: TextStyle(
                color: cardTitleColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            // Drag the handle on the left to change the order of the
            // attributes; the card and the server keep that order.
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  _rows.insert(newIndex, _rows.removeAt(oldIndex));
                });
              },
              children: [
                for (var i = 0; i < _rows.length; i++)
                  Padding(
                    key: ObjectKey(_rows[i]),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.drag_handle,
                                  size: 22, color: darkPink),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _rows[i].key,
                            cursorColor: darkPink,
                            style: textStyle,
                            decoration: fieldDecoration('Trait'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _rows[i].value,
                            cursorColor: darkPink,
                            style: textStyle,
                            decoration: fieldDecoration('Value').copyWith(
                              suffixIcon: _linkButton(_rows[i].value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: 'Add attribute',
                child: Material(
                  color: mediumPink,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setState(() => _rows.add(_AttributeRow())),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(Icons.add, size: 18, color: darkPink),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: cardTitleColor)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: darkPink,
            foregroundColor: colorBackground,
          ),
          onPressed: _save,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

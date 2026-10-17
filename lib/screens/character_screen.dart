import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../providers.dart';
import '../repository/papyr_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/book_top_header.dart';
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

  @override
  void initState() {
    super.initState();
    _repo = ref.read(repositoryProvider);
    _actions = ref.read(characterActionsProvider);
    _selectedGroupId = widget.initialGroupId;
    unawaited(_repo.refreshStoryData(_storyId));
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _addCharacter() async {
    final result = await showDialog<CharacterFormResult>(
      context: context,
      builder: (_) => const CharacterEditDialog(
        title: 'New Item',
        confirmText: 'Add',
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

              // Character cards.
              Expanded(
                child: characters.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding:
                            EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 120),
                        itemCount: characters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final character = characters[i];
                          return _CharacterCard(
                            key: ValueKey(character.id),
                            character: character,
                            onEdit: () => _editCharacter(character),
                          );
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
  });

  final StoryCharacter character;
  final VoidCallback onEdit;

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard> {
  bool _expanded = false;

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
            Text(
              character.description,
              style: const TextStyle(fontSize: 14, height: 20 / 14, color: darkPink),
            ),
            const SizedBox(height: 8),
          ],
          Divider(height: 1, color: mediumPink.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          for (final entry in character.attributes.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, color: darkPink),
                  children: [
                    TextSpan(
                      text: '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(text: entry.value),
                  ],
                ),
              ),
            ),
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
  });

  final String title;
  final String confirmText;
  final StoryCharacter? initial;
  final bool canDelete;

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
              decoration: fieldDecoration('Description'),
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
            for (final row in _rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: row.key,
                        cursorColor: darkPink,
                        style: textStyle,
                        decoration: fieldDecoration('Trait'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: row.value,
                        cursorColor: darkPink,
                        style: textStyle,
                        decoration: fieldDecoration('Value'),
                      ),
                    ),
                  ],
                ),
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

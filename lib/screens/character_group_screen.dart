import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../providers.dart';
import '../repository/papyr_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/book_top_header.dart';
import '../widgets/desktop_book.dart';
import '../widgets/desktop_shell.dart';
import 'character_actions.dart';
import 'character_screen.dart';

/// Port of CharacterGroupScreen.kt: a grid of the story's character groups.
/// Tap a group to open it; the arch button at the bottom left creates one and
/// opens it straight away.
class CharacterGroupScreen extends ConsumerStatefulWidget {
  const CharacterGroupScreen({super.key, required this.storyId});

  final int storyId;

  @override
  ConsumerState<CharacterGroupScreen> createState() =>
      _CharacterGroupScreenState();
}

class _CharacterGroupScreenState extends ConsumerState<CharacterGroupScreen> {
  static const _maxContentWidth = 820.0;

  late final PapyrRepository _repo;
  late final CharacterActions _actions;

  /// The story's current id. A story created offline gets its real id when it
  /// is sent to the server, which can happen while this screen is open.
  int get _storyId => _repo.resolveStoryId(widget.storyId);


  @override
  void initState() {
    super.initState();
    _repo = ref.read(repositoryProvider);
    _actions = ref.read(characterActionsProvider);
    // Pull the latest groups and characters; the streams update the UI.
    unawaited(_repo.refreshStoryData(_storyId));
  }

  void _openGroup(int groupId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CharacterScreen(
          storyId: _storyId,
          initialGroupId: groupId,
        ),
      ),
    );
  }

  Future<void> _createGroup(int currentCount) async {
    final result = await showDialog<CreateGroupResult>(
      context: context,
      builder: (_) => const CreateGroupDialog(),
    );
    if (result == null) return;
    final id = await _actions.createGroup(
      _storyId,
      result.name,
      result.iconIndex,
      currentCount,
    );
    if (!mounted) return;
    _openGroup(id); // straight into the new group, like the Android app
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider(_storyId)).valueOrNull ??
        const <CharacterGroup>[];
    if (useDesktopLayout(context)) return _buildDesktop(groups);

    final width = MediaQuery.sizeOf(context).width;
    final sidePadding =
        width > _maxContentWidth + 56 ? (width - _maxContentWidth) / 2 : 28.0;

    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          Column(
            children: [
              BookTopHeader(onBookmarkClick: () => backToDocument(context)),
              const SizedBox(height: 24),
              Expanded(
                child: groups.isEmpty
                    ? _buildEmpty()
                    : GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                            sidePadding, 0, sidePadding, 100),
                        // Two columns on a phone, more on a wide window.
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: groups.length,
                        itemBuilder: (context, i) => _GroupTile(
                          group: groups[i],
                          onTap: () => _openGroup(groups[i].id),
                        ),
                      ),
              ),
            ],
          ),
          // Add button: arch shape, bottom left.
          Positioned(
            left: 28,
            bottom: 0,
            child: Tooltip(
              message: 'Add character group',
              child: Material(
                color: darkPink,
                borderRadius: archTabShape,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _createGroup(groups.length),
                  child: const SizedBox(
                    width: 70,
                    height: 100,
                    child: Icon(Icons.add, color: colorBackground, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Windows look: groups as tiles laid out across the open book.
  Widget _buildDesktop(List<CharacterGroup> groups) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: DesktopShell(
        child: DesktopBook(
          onBookmarkClick: () => backToDocument(context),
          child: Stack(
            children: [
              Positioned.fill(
                top: DesktopBook.arcBottom + 30,
                child: groups.isEmpty
                    ? _buildEmpty()
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(70, 10, 70, 110),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 130,
                          mainAxisSpacing: 28,
                          crossAxisSpacing: 28,
                        ),
                        itemCount: groups.length,
                        itemBuilder: (context, i) => _GroupTile(
                          group: groups[i],
                          onTap: () => _openGroup(groups[i].id),
                        ),
                      ),
              ),
              Positioned(
                left: 28,
                bottom: 0,
                child: Tooltip(
                  message: 'Add character group',
                  child: Material(
                    color: darkPink,
                    borderRadius: archTabShape,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _createGroup(groups.length),
                      child: const SizedBox(
                        width: 70,
                        height: 100,
                        child:
                            Icon(Icons.add, color: colorBackground, size: 28),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups, color: mediumPink, size: 64),
          const SizedBox(height: 12),
          Text(
            'No character groups yet',
            style: TextStyle(
              color: darkPink.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          Text(
            'Tap + to create one',
            style: TextStyle(
              color: darkPink.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final CharacterGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: group.name,
      child: Material(
        color: mediumPink,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Icon(
              groupIcon(group.iconIndex),
              size: 52,
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Create group dialog ──────────────────────────────────────────────────────

class CreateGroupResult {
  const CreateGroupResult(this.name, this.iconIndex);
  final String name;
  final int iconIndex;
}

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _name = TextEditingController();
  int _selectedIcon = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, CreateGroupResult(name, _selectedIcon));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colorBackground,
      title: const Text(
        'New Group',
        style: TextStyle(color: cardTitleColor, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              cursorColor: darkPink,
              style: const TextStyle(color: cardTitleColor),
              decoration: fieldDecoration('Group name'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose an icon',
              style: TextStyle(color: cardTitleColor, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < characterGroupIcons.length; i++)
                  InkWell(
                    onTap: () => setState(() => _selectedIcon = i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: i == _selectedIcon ? darkPink : mediumPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        characterGroupIcons[i],
                        size: 22,
                        color: i == _selectedIcon
                            ? colorBackground
                            : Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
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
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

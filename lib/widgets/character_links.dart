import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemMouseCursors;

import '../data/app_database.dart';
import '../theme/app_theme.dart';

/// Links between characters live inside the normal text. `[[Name]]` in a
/// description or an attribute value is a link to the character called Name
/// (in any group of the same story), so nothing changes on the server and
/// the links work on every device.
final RegExp characterLinkPattern = RegExp(r'\[\[([^\[\]\n]+?)\]\]');

const Color characterLinkColor = Color(0xFF2B5C9E);

String linkToken(String name) => '[[${name.trim()}]]';

String _key(String name) => name.trim().toLowerCase();

/// Finds characters by name (ignoring case). If two characters share a name,
/// the first one wins.
class CharacterIndex {
  CharacterIndex(Iterable<StoryCharacter> all) {
    for (final c in all) {
      _byName.putIfAbsent(_key(c.name), () => c);
    }
  }

  final Map<String, StoryCharacter> _byName = {};

  StoryCharacter? find(String name) => _byName[_key(name)];
}

/// The names (lower case) that [c]'s description and attribute values link to.
Set<String> linkedNames(StoryCharacter c) {
  final texts = [c.description, ...c.attributes.values];
  return {
    for (final t in texts)
      for (final m in characterLinkPattern.allMatches(t)) _key(m.group(1)!),
  };
}

/// The characters whose text links to [target].
List<StoryCharacter> backlinksTo(
  StoryCharacter target,
  Iterable<StoryCharacter> all,
) {
  final key = _key(target.name);
  return [
    for (final c in all)
      if (c.id != target.id && linkedNames(c).contains(key)) c,
  ];
}

/// Replaces `[[old]]` with `[[new]]` in [text] (ignoring case).
String renameLinkInText(String text, String oldName, String newName) {
  final pattern = RegExp(
    r'\[\[\s*' + RegExp.escape(oldName.trim()) + r'\s*\]\]',
    caseSensitive: false,
  );
  return text.replaceAll(pattern, linkToken(newName));
}

/// Text in which every `[[Name]]` that matches a character is a tappable link.
/// Names that match nobody (for example a deleted character) are shown as
/// plain text.
class LinkedText extends StatefulWidget {
  const LinkedText(
    this.text, {
    super.key,
    required this.style,
    required this.index,
    required this.onOpen,
    this.leading = const [],
  });

  final String text;
  final TextStyle style;
  final CharacterIndex index;
  final ValueChanged<StoryCharacter> onOpen;

  /// Spans shown before the text (for example a bold "Trait: ").
  final List<InlineSpan> leading;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final spans = <InlineSpan>[...widget.leading];
    final text = widget.text;
    var last = 0;
    for (final m in characterLinkPattern.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final name = m.group(1)!.trim();
      final target = widget.index.find(name);
      if (target == null) {
        spans.add(TextSpan(text: name));
      } else {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onOpen(target);
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: name,
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
          style: const TextStyle(
            color: characterLinkColor,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: characterLinkColor,
          ),
        ));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}

/// A character that can be linked to, with the name of its group.
class LinkTarget {
  const LinkTarget(this.name, this.groupName);

  final String name;
  final String groupName;
}

/// Lets the user pick a character to link to. Returns its name, or null.
Future<String?> pickCharacterToLink(
  BuildContext context,
  List<LinkTarget> targets,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => _LinkPickerDialog(targets: targets),
  );
}

class _LinkPickerDialog extends StatefulWidget {
  const _LinkPickerDialog({required this.targets});

  final List<LinkTarget> targets;

  @override
  State<_LinkPickerDialog> createState() => _LinkPickerDialogState();
}

class _LinkPickerDialogState extends State<_LinkPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final t in widget.targets)
        if (q.isEmpty ||
            t.name.toLowerCase().contains(q) ||
            t.groupName.toLowerCase().contains(q))
          t,
    ];
    return AlertDialog(
      backgroundColor: colorBackground,
      title: const Text('Link to…',
          style: TextStyle(color: cardTitleColor, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 360,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              cursorColor: darkPink,
              style: const TextStyle(color: cardTitleColor),
              decoration: fieldDecoration('Search'),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: shown.isEmpty
                  ? const Center(
                      child: Text('No characters to link to.',
                          style: TextStyle(color: cardBodyColor)),
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        title: Text(shown[i].name,
                            style: const TextStyle(color: cardTitleColor)),
                        subtitle: Text(shown[i].groupName,
                            style: const TextStyle(color: cardBodyColor)),
                        onTap: () => Navigator.pop(context, shown[i].name),
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
      ],
    );
  }
}

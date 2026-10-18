import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../theme/app_theme.dart';
import 'spell_checker.dart';

/// Walks through the misspelled words of the document one at a time, like the
/// classic "Check spelling" window.
Future<void> showSpellCheck(
  BuildContext context,
  QuillController controller,
  SpellChecker checker,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SpellCheckDialog(controller: controller, checker: checker),
  );
}

class _SpellCheckDialog extends StatefulWidget {
  const _SpellCheckDialog({required this.controller, required this.checker});

  final QuillController controller;
  final SpellChecker checker;

  @override
  State<_SpellCheckDialog> createState() => _SpellCheckDialogState();
}

class _SpellCheckDialogState extends State<_SpellCheckDialog> {
  final _change = TextEditingController();
  final Set<String> _ignored = {};

  Misspelling? _current;
  List<String> _suggestions = const [];
  String _before = '';
  String _after = '';
  int _from = 0;
  int _changes = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Selecting text in the editor while this dialog is still being built
    // would rebuild the editor mid-build, so do that after the first frame.
    _advance(select: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = _current;
      if (mounted && m != null) _selectInEditor(m);
    });
  }

  @override
  void dispose() {
    _change.dispose();
    super.dispose();
  }

  /// Finds the next misspelled word at or after [_from].
  void _selectInEditor(Misspelling m) {
    widget.controller.updateSelection(
      TextSelection(baseOffset: m.start, extentOffset: m.end),
      ChangeSource.local,
    );
  }

  void _advance({bool select = true}) {
    final text = widget.controller.document.toPlainText();
    final found = widget.checker.findMisspellings(
      text,
      from: _from,
      ignored: _ignored,
      limit: 1,
    );
    if (found.isEmpty) {
      _current = null;
      _done = true;
      return;
    }
    final m = found.first;
    final suggestions = widget.checker.suggest(m.word);

    // Select the word in the editor too.
    if (select) _selectInEditor(m);

    String clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ');
    final beforeStart = m.start - 40 < 0 ? 0 : m.start - 40;
    final afterEnd = m.end + 40 > text.length ? text.length : m.end + 40;
    _before = clean(text.substring(beforeStart, m.start));
    _after = clean(text.substring(m.end, afterEnd));

    _current = m;
    _suggestions = suggestions;
    _change.text = suggestions.isEmpty ? m.word : suggestions.first;
    _change.selection =
        TextSelection(baseOffset: 0, extentOffset: _change.text.length);
  }

  void _next() => setState(_advance);

  void _replace() {
    final m = _current;
    final text = _change.text.trim();
    if (m == null || text.isEmpty) return;
    widget.controller.replaceText(
      m.start,
      m.end - m.start,
      text,
      TextSelection.collapsed(offset: m.start + text.length),
    );
    _changes++;
    _from = m.start + text.length;
    _next();
  }

  void _ignoreOnce() {
    final m = _current;
    if (m == null) return;
    _from = m.end;
    _next();
  }

  void _ignoreAll() {
    final m = _current;
    if (m == null) return;
    _ignored.add(m.word.toLowerCase().replaceAll('’', "'"));
    _from = m.end;
    _next();
  }

  Future<void> _addToDictionary() async {
    final m = _current;
    if (m == null) return;
    await widget.checker.addWord(m.word);
    if (!mounted) return;
    _from = m.end;
    _next();
  }

  Future<void> _openMyWords() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MyWordsDialog(checker: widget.checker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = _current;
    return AlertDialog(
      backgroundColor: colorBackground,
      title: const Text('Check spelling',
          style: TextStyle(color: cardTitleColor, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: _done || m == null ? _buildDone() : _buildWord(m),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _openMyWords,
          child: const Text('My words…', style: TextStyle(color: darkPink)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: darkPink,
            foregroundColor: colorBackground,
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(_done ? 'Done' : 'Close'),
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _changes == 0
            ? 'No more spelling mistakes found.'
            : 'Spell check finished. $_changes '
                '${_changes == 1 ? 'change' : 'changes'} made.',
        style: const TextStyle(color: cardTitleColor, fontSize: 15),
      ),
    );
  }

  Widget _buildWord(Misspelling m) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Not in dictionary',
            style: TextStyle(color: cardBodyColor, fontSize: 12)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: const TextStyle(color: cardTitleColor, fontSize: 15),
            children: [
              TextSpan(text: '…$_before'),
              TextSpan(
                text: m.word,
                style: const TextStyle(
                  color: Color(0xFFB3261E),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.wavy,
                ),
              ),
              TextSpan(text: '$_after…'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _change,
          cursorColor: darkPink,
          style: const TextStyle(color: cardTitleColor),
          decoration: fieldDecoration('Change to'),
          onSubmitted: (_) => _replace(),
        ),
        const SizedBox(height: 10),
        if (_suggestions.isEmpty)
          const Text('No suggestions',
              style: TextStyle(color: cardBodyColor, fontSize: 13))
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in _suggestions)
                ActionChip(
                  label: Text(s),
                  backgroundColor: lighterPink,
                  side: BorderSide.none,
                  onPressed: () => setState(() {
                    _change.text = s;
                    _change.selection = TextSelection.collapsed(offset: s.length);
                  }),
                ),
            ],
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: darkPink,
                foregroundColor: colorBackground,
              ),
              onPressed: _replace,
              child: const Text('Change'),
            ),
            OutlinedButton(
              onPressed: _ignoreOnce,
              child: const Text('Ignore'),
            ),
            OutlinedButton(
              onPressed: _ignoreAll,
              child: const Text('Ignore all'),
            ),
            OutlinedButton(
              onPressed: _addToDictionary,
              child: const Text('Add to dictionary'),
            ),
          ],
        ),
      ],
    );
  }
}

/// The words the user added: add new ones, or remove ones added by mistake.
class _MyWordsDialog extends StatefulWidget {
  const _MyWordsDialog({required this.checker});

  final SpellChecker checker;

  @override
  State<_MyWordsDialog> createState() => _MyWordsDialogState();
}

class _MyWordsDialogState extends State<_MyWordsDialog> {
  final _input = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final ok = await widget.checker.addWord(_input.text);
    if (!mounted) return;
    setState(() {
      _error = ok ? null : 'Use letters (and apostrophes) only.';
      if (ok) _input.clear();
    });
  }

  Future<void> _remove(String word) async {
    await widget.checker.removeWord(word);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.checker.personalWords;
    return AlertDialog(
      backgroundColor: colorBackground,
      title: const Text('My words',
          style: TextStyle(color: cardTitleColor, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 360,
        height: 340,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    cursorColor: darkPink,
                    style: const TextStyle(color: cardTitleColor),
                    decoration: fieldDecoration('New word').copyWith(
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: darkPink,
                    foregroundColor: colorBackground,
                  ),
                  onPressed: _add,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: words.isEmpty
                  ? const Center(
                      child: Text('No words added yet.',
                          style: TextStyle(color: cardBodyColor)),
                    )
                  : ListView.builder(
                      itemCount: words.length,
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        title: Text(words[i],
                            style: const TextStyle(color: cardTitleColor)),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close, color: darkPink),
                          onPressed: () => _remove(words[i]),
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
          child: const Text('Close', style: TextStyle(color: cardTitleColor)),
        ),
      ],
    );
  }
}

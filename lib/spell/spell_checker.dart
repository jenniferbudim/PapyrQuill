import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// A word the checker does not know, with its position in the text.
class Misspelling {
  const Misspelling(this.start, this.end, this.word);

  final int start;
  final int end;
  final String word;
}

/// A plain dictionary spell checker (no AI): a list of English words plus the
/// user's own words. Suggestions are the dictionary words that are one or two
/// edits away from the misspelled word.
class SpellChecker {
  SpellChecker._(this._words, this._personal, this._prefs);

  /// For tests: build a checker from a list of words, without assets.
  @visibleForTesting
  SpellChecker.forTest(Iterable<String> words,
      {Iterable<String> personal = const []})
      : _words = {for (final w in words) w.toLowerCase()},
        _personal = {for (final w in personal) w.toLowerCase()},
        _prefs = null;

  static const _assetPath = 'assets/dictionary/en_words.txt';
  static const _personalKey = 'personal_dictionary';
  static const _alphabet = [
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', //
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', "'",
  ];

  static final _wordPattern =
      RegExp("[\\p{L}]+(?:['’][\\p{L}]+)*", unicode: true);

  static Future<SpellChecker>? _loading;

  /// Loads the dictionary once and reuses it afterwards.
  static Future<SpellChecker> load() => _loading ??= _doLoad();

  static Future<SpellChecker> _doLoad() async {
    final text = await rootBundle.loadString(_assetPath);
    final words = <String>{};
    for (final line in text.split('\n')) {
      final w = line.trim();
      if (w.isNotEmpty) words.add(w);
    }
    SharedPreferences? prefs;
    var personal = <String>{};
    try {
      prefs = await SharedPreferences.getInstance();
      personal = (prefs.getStringList(_personalKey) ?? const <String>[]).toSet();
    } catch (_) {
      // Without preferences the personal words last until the app closes.
    }
    return SpellChecker._(words, personal, prefs);
  }

  final Set<String> _words;
  final Set<String> _personal;
  final SharedPreferences? _prefs;

  // ── Checking ──────────────────────────────────────────────────────────────

  static String _normalize(String word) =>
      word.toLowerCase().replaceAll('’', "'");

  bool _known(String w) => _words.contains(w) || _personal.contains(w);

  bool isCorrect(String word) {
    final w = _normalize(word);
    if (w.isEmpty || _known(w)) return true;
    // Possessives: "Jinwoo's" is fine when "Jinwoo" is.
    if (w.endsWith("'s") && _known(w.substring(0, w.length - 2))) return true;
    return false;
  }

  /// The misspelled words in [text], in order, starting at [from]. Words in
  /// [ignored] (lower case), single letters, ALL CAPS words and words stuck to
  /// digits are skipped.
  List<Misspelling> findMisspellings(
    String text, {
    int from = 0,
    Set<String> ignored = const {},
    int? limit,
  }) {
    final result = <Misspelling>[];
    for (final m in _wordPattern.allMatches(text, from)) {
      final word = m.group(0)!;
      if (word.length < 2) continue;
      if (word == word.toUpperCase() && word != word.toLowerCase()) continue;
      if (m.start > 0 && _isDigit(text.codeUnitAt(m.start - 1))) continue;
      if (m.end < text.length && _isDigit(text.codeUnitAt(m.end))) continue;
      if (ignored.contains(_normalize(word))) continue;
      if (isCorrect(word)) continue;
      result.add(Misspelling(m.start, m.end, word));
      if (limit != null && result.length >= limit) break;
    }
    return result;
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  // ── Suggestions ───────────────────────────────────────────────────────────

  Iterable<String> _edits1(String w) sync* {
    for (var i = 0; i < w.length; i++) {
      yield w.substring(0, i) + w.substring(i + 1); // delete a letter
    }
    for (var i = 0; i < w.length - 1; i++) {
      yield w.substring(0, i) + w[i + 1] + w[i] + w.substring(i + 2); // swap
    }
    for (var i = 0; i < w.length; i++) {
      for (final c in _alphabet) {
        if (c != w[i]) yield w.substring(0, i) + c + w.substring(i + 1);
      }
    }
    for (var i = 0; i <= w.length; i++) {
      for (final c in _alphabet) {
        yield w.substring(0, i) + c + w.substring(i);
      }
    }
  }

  /// Up to [max] dictionary words close to [word], best first, written with the
  /// same capitalization as [word].
  List<String> suggest(String word, {int max = 6}) {
    final w = _normalize(word);
    if (w.isEmpty) return const [];

    final distance = <String, int>{};
    for (final c in _edits1(w)) {
      if (c.isNotEmpty && c != w && _known(c)) distance[c] = 1;
    }
    // Two edits away only when one edit found little, to keep it quick.
    if (distance.length < 3 && w.length <= 14) {
      for (final c1 in _edits1(w)) {
        for (final c2 in _edits1(c1)) {
          if (c2.isNotEmpty &&
              c2 != w &&
              !distance.containsKey(c2) &&
              _known(c2)) {
            distance[c2] = 2;
          }
        }
      }
    }

    int rank(String s) =>
        distance[s]! * 100 + (s[0] == w[0] ? 0 : 10) + (s.length - w.length).abs();
    final list = distance.keys.toList()
      ..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : a.compareTo(b);
      });
    return [for (final s in list.take(max)) matchCase(word, s)];
  }

  /// Writes [suggestion] with the capitalization of [original].
  static String matchCase(String original, String suggestion) {
    if (original.isEmpty || suggestion.isEmpty) return suggestion;
    if (original.length > 1 &&
        original == original.toUpperCase() &&
        original != original.toLowerCase()) {
      return suggestion.toUpperCase();
    }
    final first = original.substring(0, 1);
    if (first != first.toLowerCase()) {
      return suggestion.substring(0, 1).toUpperCase() + suggestion.substring(1);
    }
    return suggestion;
  }

  // ── The user's own words ──────────────────────────────────────────────────

  List<String> get personalWords => _personal.toList()..sort();

  /// Returns false if [word] is not a usable word (letters and apostrophes).
  Future<bool> addWord(String word) async {
    final w = _normalize(word.trim());
    if (!RegExp(r"^[\p{L}]+(?:'[\p{L}]+)*$", unicode: true).hasMatch(w)) {
      return false;
    }
    _personal.add(w);
    await _savePersonal();
    return true;
  }

  Future<void> removeWord(String word) async {
    _personal.remove(_normalize(word));
    await _savePersonal();
  }

  Future<void> _savePersonal() async {
    try {
      await _prefs?.setStringList(_personalKey, personalWords);
    } catch (_) {
      // Keep the change for this run even if it cannot be saved.
    }
  }
}

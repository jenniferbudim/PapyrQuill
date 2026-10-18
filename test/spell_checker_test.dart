import 'package:flutter_test/flutter_test.dart';
import 'package:papyrquill/spell/spell_checker.dart';

void main() {
  final checker = SpellChecker.forTest(
    ['the', 'quick', 'brown', 'fox', 'received', "don't", 'weird', 'hello'],
  );

  test('knows words, ignores case', () {
    expect(checker.isCorrect('The'), isTrue);
    expect(checker.isCorrect("Don’t"), isTrue);
    expect(checker.isCorrect('Foxs'), isFalse);
  });

  test('possessive of a known word is fine', () {
    expect(checker.isCorrect("fox's"), isTrue);
  });

  test('finds misspellings with positions and skips noise', () {
    const text = 'The quikc fox NASA 3rd';
    final found = checker.findMisspellings(text);
    expect(found.map((m) => m.word), ['quikc']);
    expect(found.single.start, 4);
    expect(found.single.end, 9);
  });

  test('suggests close words and keeps capitalization', () {
    expect(checker.suggest('quikc').first, 'quick');
    expect(checker.suggest('Recieved').first, 'Received');
    expect(checker.suggest('wierd').first, 'weird');
  });

  test('personal words are accepted', () async {
    final c = SpellChecker.forTest(['the'], personal: ['jinwoo']);
    expect(c.isCorrect('Jinwoo'), isTrue);
    expect(c.findMisspellings('the Jinwoo'), isEmpty);
  });
}

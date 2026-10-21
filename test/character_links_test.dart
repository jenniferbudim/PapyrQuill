import 'package:flutter_test/flutter_test.dart';
import 'package:papyrquill/data/app_database.dart';
import 'package:papyrquill/widgets/character_links.dart';

StoryCharacter _c(int id, String name,
        {String description = '', Map<String, String> attributes = const {}}) =>
    StoryCharacter(
      id: id,
      storyId: 1,
      groupId: 1,
      name: name,
      description: description,
      attributes: attributes,
    );

void main() {
  final bla = _c(1, 'BLA');
  final a = _c(2, 'Character A', attributes: {'From': 'Born in [[bla]]'});
  final b = _c(3, 'B', description: 'Visited [[ BLA ]] and [[Nowhere]].');

  test('index finds characters ignoring case and spaces', () {
    final index = CharacterIndex([bla, a]);
    expect(index.find('bla'), bla);
    expect(index.find(' BLA '), bla);
    expect(index.find('Nowhere'), isNull);
  });

  test('linkedNames reads description and attribute values', () {
    expect(linkedNames(a), {'bla'});
    expect(linkedNames(b), {'bla', 'nowhere'});
  });

  test('backlinks list the characters that mention the target', () {
    final names = backlinksTo(bla, [bla, a, b]).map((c) => c.name).toList();
    expect(names, ['Character A', 'B']);
  });

  test('renaming a link keeps the rest of the text', () {
    expect(renameLinkInText('From [[bla]] and [[Other]]', 'BLA', 'Place X'),
        'From [[Place X]] and [[Other]]');
  });
}

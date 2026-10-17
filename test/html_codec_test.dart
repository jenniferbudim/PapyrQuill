import 'package:flutter_test/flutter_test.dart';
import 'package:papyrquill/editor/html_codec.dart';

void main() {
  group('opsToHtml', () {
    test('bold text inside a paragraph', () {
      final html = opsToHtml([
        {'insert': 'Hello '},
        {
          'insert': 'world',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);
      expect(html, '<p>Hello <b>world</b></p>');
    });

    test('nested formatting closes in reverse order', () {
      final html = opsToHtml([
        {
          'insert': 'x',
          'attributes': {'bold': true, 'italic': true, 'underline': true},
        },
        {'insert': '\n'},
      ]);
      expect(html, '<p><b><i><u>x</u></i></b></p>');
    });

    test('alignment is written as an inline style', () {
      final html = opsToHtml([
        {'insert': 'Hi'},
        {
          'insert': '\n',
          'attributes': {'align': 'center'},
        },
      ]);
      expect(html, '<p style="text-align: center;">Hi</p>');
    });

    test('empty line becomes <p><br></p>', () {
      expect(opsToHtml([
        {'insert': '\n'},
      ]), '<p><br></p>');
    });

    test('consecutive bullets share one <ul>', () {
      final html = opsToHtml([
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'b'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
      ]);
      expect(html, '<ul><li>a</li><li>b</li></ul>');
    });

    test('special characters are escaped', () {
      final html = opsToHtml([
        {'insert': 'a < b & c'},
        {'insert': '\n'},
      ]);
      expect(html, '<p>a &lt; b &amp; c</p>');
    });
  });

  group('htmlToOps', () {
    test('bold text inside a paragraph', () {
      expect(htmlToOps('<p>Hello <b>world</b></p>'), [
        {'insert': 'Hello '},
        {
          'insert': 'world',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);
    });

    test('formatting written as CSS (span style) is understood', () {
      expect(htmlToOps('<p><span style="font-weight: bold;">x</span></p>'), [
        {
          'insert': 'x',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);
    });

    test('text-align on a paragraph', () {
      expect(htmlToOps('<p style="text-align: center;">Hi</p>'), [
        {'insert': 'Hi'},
        {
          'insert': '\n',
          'attributes': {'align': 'center'},
        },
      ]);
    });

    test('an empty paragraph keeps exactly one blank line', () {
      expect(htmlToOps('<p>a</p><p><br></p><p>b</p>'), [
        {'insert': 'a'},
        {'insert': '\n'},
        {'insert': '\n'},
        {'insert': 'b'},
        {'insert': '\n'},
      ]);
    });

    test('bulleted list', () {
      expect(htmlToOps('<ul><li>a</li><li>b</li></ul>'), [
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'b'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
      ]);
    });

    test('empty input gives a single newline', () {
      expect(htmlToOps(''), [
        {'insert': '\n'},
      ]);
    });

    test('plain text without tags still becomes one line', () {
      expect(htmlToOps('Just text'), [
        {'insert': 'Just text'},
        {'insert': '\n'},
      ]);
    });
  });

  group('htmlToPlainText', () {
    test('keeps line breaks between paragraphs and drops tags', () {
      expect(
        htmlToPlainText('<p>Hello <b>world</b></p><p>Next</p>'),
        'Hello world\nNext',
      );
    });

    test('decodes entities', () {
      expect(htmlToPlainText('<p>Wow&excl;</p>'), 'Wow!');
    });

    test('empty content gives an empty string', () {
      expect(htmlToPlainText(''), '');
    });
  });

  test('round trip keeps formatting, alignment and lists', () {
    const html =
        '<p>Intro <b>bold</b> and <i>italic</i></p>'
        '<p style="text-align: right;">Right</p>'
        '<ul><li>one</li><li>two</li></ul>'
        '<p><br></p>'
        '<p>End</p>';
    expect(opsToHtml(htmlToOps(html)), html);
  });
}

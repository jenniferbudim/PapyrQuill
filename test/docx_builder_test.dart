import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:papyrquill/export/docx_builder.dart';

void main() {
  group('crc32', () {
    test('matches the standard check value', () {
      expect(crc32(utf8.encode('123456789')), 0xCBF43926);
    });

    test('empty input is zero', () {
      expect(crc32(const <int>[]), 0);
    });
  });

  group('zipStore', () {
    test('writes a valid local header, entries and end record', () {
      final bytes = zipStore({
        'a.txt': utf8.encode('hello'),
        'dir/b.txt': utf8.encode('world!'),
      });

      // Starts with "PK\x03\x04".
      expect(bytes.sublist(0, 4), [0x50, 0x4B, 0x03, 0x04]);

      // The end-of-central-directory record is the last 22 bytes.
      final eocd = bytes.length - 22;
      expect(bytes.sublist(eocd, eocd + 4), [0x50, 0x4B, 0x05, 0x06]);
      // Entry count (2 bytes, little endian) at offset 10 of the record.
      expect(bytes[eocd + 10], 2);
      expect(bytes[eocd + 11], 0);

      // Stored (uncompressed), so the text is visible in the bytes.
      final asText = latin1.decode(bytes);
      expect(asText, contains('hello'));
      expect(asText, contains('world!'));
      expect(asText, contains('dir/b.txt'));
    });
  });

  group('DocxBuilder', () {
    test('plain text becomes one paragraph with one run', () {
      final b = DocxBuilder()
        ..body([
          {'insert': 'Hi\n'},
        ]);
      expect(
        b.bodyXml,
        '<w:p><w:r><w:t xml:space="preserve">Hi</w:t></w:r></w:p>',
      );
    });

    test('bold run', () {
      final b = DocxBuilder()
        ..body([
          {
            'insert': 'x',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ]);
      expect(
        b.bodyXml,
        '<w:p><w:r><w:rPr><w:b/></w:rPr>'
        '<w:t xml:space="preserve">x</w:t></w:r></w:p>',
      );
    });

    test('run properties are written in schema order', () {
      final b = DocxBuilder()
        ..body([
          {
            'insert': 'x',
            'attributes': {
              'underline': true,
              'strike': true,
              'italic': true,
              'bold': true,
            },
          },
          {'insert': '\n'},
        ]);
      expect(
        b.bodyXml,
        contains('<w:rPr><w:b/><w:i/><w:strike/><w:u w:val="single"/></w:rPr>'),
      );
    });

    test('centered paragraph', () {
      final b = DocxBuilder()
        ..body([
          {'insert': 'Hi'},
          {
            'insert': '\n',
            'attributes': {'align': 'center'},
          },
        ]);
      expect(
        b.bodyXml,
        '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>'
        '<w:r><w:t xml:space="preserve">Hi</w:t></w:r></w:p>',
      );
    });

    test('bullet item has a marker and a hanging indent', () {
      final b = DocxBuilder()
        ..body([
          {'insert': 'a'},
          {
            'insert': '\n',
            'attributes': {'list': 'bullet'},
          },
        ]);
      expect(
        b.bodyXml,
        '<w:p><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>'
        '<w:r><w:t xml:space="preserve">• </w:t></w:r>'
        '<w:r><w:t xml:space="preserve">a</w:t></w:r></w:p>',
      );
    });

    test('numbered items count up and restart after other text', () {
      final b = DocxBuilder()
        ..body([
          {'insert': 'a'},
          {
            'insert': '\n',
            'attributes': {'list': 'ordered'},
          },
          {'insert': 'b'},
          {
            'insert': '\n',
            'attributes': {'list': 'ordered'},
          },
          {'insert': 'plain\n'},
          {'insert': 'c'},
          {
            'insert': '\n',
            'attributes': {'list': 'ordered'},
          },
        ]);
      final xml = b.bodyXml;
      expect(xml, contains('>1. </w:t>'));
      expect(xml, contains('>2. </w:t>'));
      // The third item starts over at 1.
      expect('>1. </w:t>'.allMatches(xml).length, 2);
    });

    test('special characters are escaped and invalid ones dropped', () {
      final b = DocxBuilder()
        ..body([
          {'insert': 'a & b < c \u0001 d\n'},
        ]);
      expect(b.bodyXml, contains('a &amp; b &lt; c  d'));
    });

    test('blank line is an empty paragraph', () {
      final b = DocxBuilder()..blank();
      expect(b.bodyXml, '<w:p></w:p>');
    });

    test('build() produces a zip containing the Word parts', () {
      final bytes = (DocxBuilder()..heading('Title', points: 20)).build();
      expect(bytes.sublist(0, 4), [0x50, 0x4B, 0x03, 0x04]);
      final asText = latin1.decode(bytes);
      expect(asText, contains('[Content_Types].xml'));
      expect(asText, contains('word/document.xml'));
      expect(asText, contains('word/styles.xml'));
      expect(asText, contains('<w:sz w:val="40"/>'));
    });
  });
}

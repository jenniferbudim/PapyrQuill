// Builds a .docx file from Quill ops. Plain Dart (no Flutter, no packages), so
// it is unit tested on its own: see test/docx_builder_test.dart.
//
// A .docx is a zip of a few XML files. The zip here uses the "stored" method
// (no compression), which every zip reader and Word accept.
//
// Compared with the Android app's export (plain text lines), this keeps bold,
// italic, underline, strikethrough, alignment, headings and lists.

import 'dart:convert';
import 'dart:typed_data';

import '../editor/html_codec.dart';

const _wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

class DocxBuilder {
  final StringBuffer _body = StringBuffer();

  /// The XML for everything added so far (exposed for tests).
  String get bodyXml => _body.toString();

  /// A bold (by default) heading line, e.g. the story or chapter title.
  void heading(
    String text, {
    required int points,
    bool bold = true,
    bool italic = false,
  }) {
    _paragraph(
      runs: _run(text, bold: bold, italic: italic, halfPoints: points * 2),
    );
  }

  /// A plain paragraph (used for the story description).
  void plain(String text, {int points = 12, bool italic = false}) {
    _paragraph(runs: _run(text, italic: italic, halfPoints: points * 2));
  }

  /// An empty paragraph.
  void blank() => _paragraph(runs: '');

  /// Chapter text, keeping its formatting.
  void body(List<dynamic> ops) {
    final counters = <int, int>{}; // numbered list counters by indent level

    for (final line in splitOpsIntoLines(ops)) {
      final attrs = line.attrs;
      final list = attrs['list'];
      final isList = list == 'bullet' ||
          list == 'ordered' ||
          list == 'checked' ||
          list == 'unchecked';
      final indentRaw = attrs['indent'];
      final indent = indentRaw is int && indentRaw > 0 ? indentRaw : 0;

      var prefix = '';
      if (isList) {
        counters.removeWhere((level, _) => level > indent);
        switch (list) {
          case 'ordered':
            final n = (counters[indent] ?? 0) + 1;
            counters[indent] = n;
            prefix = '$n. ';
          case 'checked':
            prefix = '☑ ';
          case 'unchecked':
            prefix = '☐ ';
          default:
            prefix = '• ';
        }
      } else {
        counters.clear();
      }

      // Heading lines are bold and larger.
      final header = attrs['header'];
      final headingHalfPoints = switch (header) {
        1 => 32,
        2 => 28,
        3 => 26,
        _ => null,
      };

      final runs = StringBuffer();
      if (prefix.isNotEmpty) runs.write(_run(prefix));
      for (final segment in line.segments) {
        final a = segment.attrs;
        runs.write(_run(
          segment.text,
          bold: a['bold'] == true || headingHalfPoints != null,
          italic: a['italic'] == true,
          underline: a['underline'] == true,
          strike: a['strike'] == true,
          halfPoints: headingHalfPoints,
        ));
      }

      final pPr = StringBuffer();
      if (isList) {
        pPr.write('<w:ind w:left="${720 + 360 * indent}" w:hanging="360"/>');
      }
      final jc = switch (attrs['align']) {
        'center' => 'center',
        'right' => 'right',
        'justify' => 'both',
        _ => null,
      };
      if (jc != null) pPr.write('<w:jc w:val="$jc"/>');

      _paragraph(pPr: pPr.toString(), runs: runs.toString());
    }
  }

  // ── XML helpers ───────────────────────────────────────────────────────────

  void _paragraph({String pPr = '', required String runs}) {
    _body
      ..write('<w:p>')
      ..write(pPr.isEmpty ? '' : '<w:pPr>$pPr</w:pPr>')
      ..write(runs)
      ..write('</w:p>');
  }

  /// One run of text. The properties are written in the order the Word schema
  /// requires: b, i, strike, sz, u.
  String _run(
    String text, {
    bool bold = false,
    bool italic = false,
    bool strike = false,
    bool underline = false,
    int? halfPoints,
  }) {
    final rPr = StringBuffer();
    if (bold) rPr.write('<w:b/>');
    if (italic) rPr.write('<w:i/>');
    if (strike) rPr.write('<w:strike/>');
    if (halfPoints != null) {
      rPr.write('<w:sz w:val="$halfPoints"/><w:szCs w:val="$halfPoints"/>');
    }
    if (underline) rPr.write('<w:u w:val="single"/>');
    return '<w:r>${rPr.isEmpty ? '' : '<w:rPr>$rPr</w:rPr>'}'
        '<w:t xml:space="preserve">${_escapeXml(text)}</w:t></w:r>';
  }

  // ── Output ────────────────────────────────────────────────────────────────

  Uint8List build() {
    const header = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

    final contentTypes = '$header'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
        '</Types>';

    final rootRels = '$header'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';

    final documentRels = '$header'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>';

    // Calibri 12pt, as the Android export used 12pt body text.
    final styles = '$header'
        '<w:styles xmlns:w="$_wNs">'
        '<w:docDefaults>'
        '<w:rPrDefault><w:rPr>'
        '<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Calibri" w:cs="Calibri"/>'
        '<w:sz w:val="24"/><w:szCs w:val="24"/>'
        '</w:rPr></w:rPrDefault>'
        '<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr></w:pPrDefault>'
        '</w:docDefaults>'
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
        '<w:name w:val="Normal"/><w:qFormat/>'
        '</w:style>'
        '</w:styles>';

    // A4 page with 2.54 cm margins.
    final document = '$header'
        '<w:document xmlns:w="$_wNs"><w:body>'
        '$_body'
        '<w:sectPr>'
        '<w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" '
        'w:header="708" w:footer="708" w:gutter="0"/>'
        '</w:sectPr>'
        '</w:body></w:document>';

    return zipStore({
      '[Content_Types].xml': utf8.encode(contentTypes),
      '_rels/.rels': utf8.encode(rootRels),
      'word/document.xml': utf8.encode(document),
      'word/_rels/document.xml.rels': utf8.encode(documentRels),
      'word/styles.xml': utf8.encode(styles),
    });
  }
}

/// Escapes text for XML and drops characters XML cannot hold.
String _escapeXml(String s) {
  final sb = StringBuffer();
  for (final rune in s.runes) {
    // Allowed XML 1.0 characters: tab, newline, CR, and 0x20 and up
    // (excluding surrogates and 0xFFFE / 0xFFFF).
    final ok = rune == 0x9 ||
        rune == 0xA ||
        rune == 0xD ||
        (rune >= 0x20 && rune <= 0xD7FF) ||
        (rune >= 0xE000 && rune <= 0xFFFD) ||
        (rune >= 0x10000 && rune <= 0x10FFFF);
    if (!ok) continue;
    switch (rune) {
      case 0x26:
        sb.write('&amp;');
      case 0x3C:
        sb.write('&lt;');
      case 0x3E:
        sb.write('&gt;');
      case 0x22:
        sb.write('&quot;');
      default:
        sb.writeCharCode(rune);
    }
  }
  return sb.toString();
}

// ════════════════════════════════════════════════════════════════════════════
//  Minimal zip writer (stored, no compression)
// ════════════════════════════════════════════════════════════════════════════

/// Zips [files] (name -> content) without compression. Entries keep the map's
/// insertion order; names are written as UTF-8.
Uint8List zipStore(Map<String, List<int>> files) {
  final out = BytesBuilder();
  final central = BytesBuilder();
  var count = 0;

  files.forEach((name, data) {
    final nameBytes = utf8.encode(name);
    final crc = crc32(data);
    final offset = out.length;

    // Local file header
    _u32(out, 0x04034b50); // signature
    _u16(out, 20); // version needed
    _u16(out, 0x0800); // flags: names are UTF-8
    _u16(out, 0); // method: stored
    _u16(out, 0); // mod time
    _u16(out, 0x21); // mod date: 1980-01-01
    _u32(out, crc);
    _u32(out, data.length); // compressed size
    _u32(out, data.length); // uncompressed size
    _u16(out, nameBytes.length);
    _u16(out, 0); // extra field length
    out.add(nameBytes);
    out.add(data);

    // Central directory header
    _u32(central, 0x02014b50); // signature
    _u16(central, 20); // version made by
    _u16(central, 20); // version needed
    _u16(central, 0x0800); // flags
    _u16(central, 0); // method
    _u16(central, 0); // mod time
    _u16(central, 0x21); // mod date
    _u32(central, crc);
    _u32(central, data.length);
    _u32(central, data.length);
    _u16(central, nameBytes.length);
    _u16(central, 0); // extra field length
    _u16(central, 0); // comment length
    _u16(central, 0); // disk number start
    _u16(central, 0); // internal attributes
    _u32(central, 0); // external attributes
    _u32(central, offset); // offset of the local header
    central.add(nameBytes);

    count++;
  });

  final centralOffset = out.length;
  final centralBytes = central.toBytes();
  out.add(centralBytes);

  // End of central directory record
  _u32(out, 0x06054b50);
  _u16(out, 0); // this disk
  _u16(out, 0); // disk with the central directory
  _u16(out, count); // entries on this disk
  _u16(out, count); // total entries
  _u32(out, centralBytes.length);
  _u32(out, centralOffset);
  _u16(out, 0); // comment length

  return out.toBytes();
}

void _u16(BytesBuilder b, int v) {
  b.addByte(v & 0xFF);
  b.addByte((v >> 8) & 0xFF);
}

void _u32(BytesBuilder b, int v) {
  b.addByte(v & 0xFF);
  b.addByte((v >> 8) & 0xFF);
  b.addByte((v >> 16) & 0xFF);
  b.addByte((v >> 24) & 0xFF);
}

final List<int> _crcTable = () {
  final table = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
    table[n] = c;
  }
  return table;
}();

/// Standard CRC-32 (the one zip uses).
int crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final byte in data) {
    c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

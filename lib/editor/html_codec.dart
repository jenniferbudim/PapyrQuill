// Converts between the HTML stored in the database / sent to the server and
// Quill "ops" (the JSON form of a Quill Delta used by flutter_quill).
//
// This file is plain Dart (no Flutter), so it can be unit tested on its own:
// see test/html_codec_test.dart.
//
// Why a hand-written codec instead of a package: the Android app saved HTML
// produced by compose-rich-editor (<b>, <i>, <u>, <s>, <ul><li>, <br>, and
// <p style="text-align: ...">), and that same HTML must keep working in both
// apps and on the server. Writing both directions here means the output format
// is exactly what the Android editor can read back.
//
// Supported: bold, italic, underline, strikethrough, links, paragraph
// alignment (center/right/justify), headings (h1-h3), bulleted and numbered
// lists (nested), and blank lines. Anything else (colors, images, tables) is
// dropped, but the text is kept.

import 'dart:math' as math;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

typedef Ops = List<Map<String, dynamic>>;

// ════════════════════════════════════════════════════════════════════════════
//  HTML -> ops
// ════════════════════════════════════════════════════════════════════════════

Ops htmlToOps(String html) {
  final fragment = html_parser.parseFragment(html);
  final converter = _HtmlToOps();
  converter.run(fragment.nodes);
  return converter.ops;
}

class _Block {
  _Block(this.attrs);

  /// Block attributes written on the line's closing "\n" (align, list, ...).
  final Map<String, dynamic> attrs;

  /// True once this block has already closed at least one line.
  bool emitted = false;
}

class _Ctx {
  const _Ctx(this.inline, this.block, this.listDepth);

  final Map<String, dynamic> inline;
  final _Block block;
  final int listDepth;
}

class _HtmlToOps {
  final Ops ops = [];
  bool _lineHasContent = false;

  void run(List<dom.Node> nodes) {
    final root = _Ctx(const {}, _Block({}), 0);
    _walk(nodes, root);
    if (_lineHasContent) _endLine(const {});
    if (ops.isEmpty) ops.add({'insert': '\n'});
  }

  // ── Emitting ops ──────────────────────────────────────────────────────────

  void _text(String text, Map<String, dynamic> inline) {
    if (text.isEmpty) return;
    if (ops.isNotEmpty) {
      final last = ops.last;
      final lastInsert = last['insert'];
      if (lastInsert is String &&
          !lastInsert.endsWith('\n') &&
          _sameAttrs(last['attributes'], inline)) {
        last['insert'] = lastInsert + text;
        _lineHasContent = true;
        return;
      }
    }
    ops.add({
      'insert': text,
      if (inline.isNotEmpty) 'attributes': Map<String, dynamic>.from(inline),
    });
    _lineHasContent = true;
  }

  void _endLine(Map<String, dynamic> block) {
    ops.add({
      'insert': '\n',
      if (block.isNotEmpty) 'attributes': Map<String, dynamic>.from(block),
    });
    _lineHasContent = false;
  }

  bool _sameAttrs(dynamic a, Map<String, dynamic> b) {
    final am = a is Map ? a : const {};
    if (am.length != b.length) return false;
    for (final key in b.keys) {
      if (!am.containsKey(key) || am[key] != b[key]) return false;
    }
    return true;
  }

  // ── Walking the tree ──────────────────────────────────────────────────────

  void _walk(List<dom.Node> nodes, _Ctx ctx) {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is dom.Text) {
        _handleText(node.data, ctx);
      } else if (node is dom.Element) {
        _handleElement(node, nodes, i, ctx);
      }
    }
  }

  void _handleText(String data, _Ctx ctx) {
    var t = data.replaceAll(RegExp(r'[ \t\r\n\f]+'), ' ');
    if (!_lineHasContent) t = t.replaceFirst(RegExp(r'^ +'), '');
    _text(t, ctx.inline);
  }

  void _handleElement(
    dom.Element el,
    List<dom.Node> siblings,
    int index,
    _Ctx ctx,
  ) {
    final tag = el.localName ?? '';
    switch (tag) {
      case 'script':
      case 'style':
        return;
      case 'br':
        // A <br> that only pads an empty block is ignored; otherwise it ends
        // the current line (Quill has no soft line breaks).
        if (_lineHasContent || _hasContentAfter(siblings, index)) {
          _endLine(ctx.block.attrs);
          ctx.block.emitted = true;
        }
        return;
      case 'p':
      case 'div':
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
      case 'blockquote':
      case 'pre':
      case 'section':
      case 'article':
        _block(el, ctx, _blockAttrs(el));
        return;
      case 'ul':
      case 'ol':
        _list(el, ctx, ctx.listDepth);
        return;
      case 'li':
        // <li> outside a list: treat it as a bullet item.
        _listItem(el, ctx, 'bullet', ctx.listDepth);
        return;
      default:
        // Inline element: carry its formatting down to the children.
        _walk(el.nodes, _Ctx(_mergeInline(ctx.inline, el), ctx.block, ctx.listDepth));
    }
  }

  bool _hasContentAfter(List<dom.Node> siblings, int index) {
    for (var i = index + 1; i < siblings.length; i++) {
      final n = siblings[i];
      if (n is dom.Element) return true;
      if (n is dom.Text && n.data.trim().isNotEmpty) return true;
    }
    return false;
  }

  void _closeDanglingLine(_Ctx ctx) {
    if (_lineHasContent) {
      _endLine(ctx.block.attrs);
      ctx.block.emitted = true;
    }
  }

  void _finish(_Block block) {
    // Close the open line, or emit one blank line for an empty block.
    if (_lineHasContent || !block.emitted) _endLine(block.attrs);
  }

  void _block(dom.Element el, _Ctx ctx, Map<String, dynamic> attrs) {
    _closeDanglingLine(ctx);
    final block = _Block(attrs);
    _walk(
      el.nodes,
      _Ctx(_mergeInline(ctx.inline, el), block, ctx.listDepth),
    );
    _finish(block);
    ctx.block.emitted = true;
  }

  void _list(dom.Element el, _Ctx ctx, int depth) {
    _closeDanglingLine(ctx);
    final type = el.localName == 'ol' ? 'ordered' : 'bullet';
    for (final child in el.nodes) {
      if (child is! dom.Element) continue;
      if (child.localName == 'li') {
        _listItem(child, ctx, type, depth);
      } else if (child.localName == 'ul' || child.localName == 'ol') {
        _list(child, ctx, depth + 1);
      }
    }
    ctx.block.emitted = true;
  }

  void _listItem(dom.Element li, _Ctx ctx, String type, int depth) {
    _closeDanglingLine(ctx);
    final attrs = <String, dynamic>{
      ..._blockAttrs(li),
      'list': type,
      if (depth > 0) 'indent': depth,
    };
    final block = _Block(attrs);
    // Lists nested inside this <li> are one level deeper.
    _walk(
      li.nodes,
      _Ctx(_mergeInline(ctx.inline, li), block, depth + 1),
    );
    _finish(block);
    ctx.block.emitted = true;
  }

  // ── Attributes ────────────────────────────────────────────────────────────

  Map<String, dynamic> _blockAttrs(dom.Element el) {
    final style = _parseStyle(el.attributes['style']);
    final result = <String, dynamic>{};
    final align = (style['text-align'] ?? el.attributes['align'])
        ?.toLowerCase()
        .trim();
    if (align == 'center' || align == 'right' || align == 'justify') {
      result['align'] = align;
    }
    final tag = el.localName ?? '';
    if (RegExp(r'^h[1-6]$').hasMatch(tag)) {
      result['header'] = math.min(int.parse(tag.substring(1)), 3);
    }
    return result;
  }

  Map<String, dynamic> _mergeInline(Map<String, dynamic> inline, dom.Element el) {
    final m = Map<String, dynamic>.from(inline);
    switch (el.localName) {
      case 'b':
      case 'strong':
        m['bold'] = true;
      case 'i':
      case 'em':
        m['italic'] = true;
      case 'u':
      case 'ins':
        m['underline'] = true;
      case 's':
      case 'strike':
      case 'del':
        m['strike'] = true;
      case 'a':
        final href = el.attributes['href'];
        if (href != null && href.isNotEmpty) m['link'] = href;
    }

    // Formatting written as CSS (for example <span style="font-weight: bold">).
    final style = _parseStyle(el.attributes['style']);
    final weight = style['font-weight']?.toLowerCase().trim();
    if (weight != null &&
        (weight == 'bold' ||
            weight == 'bolder' ||
            (int.tryParse(weight) ?? 0) >= 600)) {
      m['bold'] = true;
    }
    if ((style['font-style'] ?? '').toLowerCase().contains('italic')) {
      m['italic'] = true;
    }
    final decoration =
        '${style['text-decoration'] ?? ''} ${style['text-decoration-line'] ?? ''}'
            .toLowerCase();
    if (decoration.contains('underline')) m['underline'] = true;
    if (decoration.contains('line-through')) m['strike'] = true;
    return m;
  }

  Map<String, String> _parseStyle(String? style) {
    final result = <String, String>{};
    if (style == null) return result;
    for (final declaration in style.split(';')) {
      final colon = declaration.indexOf(':');
      if (colon <= 0) continue;
      final key = declaration.substring(0, colon).trim().toLowerCase();
      final value = declaration.substring(colon + 1).trim();
      if (key.isNotEmpty) result[key] = value;
    }
    return result;
  }
}

/// Plain text of an HTML chapter, with line breaks kept between paragraphs.
/// Used for chapter previews (Kotlin: Html.fromHtml(...).toString()).
String htmlToPlainText(String html) => htmlToOps(html)
    .map((op) => op['insert'])
    .whereType<String>()
    .join()
    .trim();

// ════════════════════════════════════════════════════════════════════════════
//  ops -> HTML
// ════════════════════════════════════════════════════════════════════════════

class OpsSegment {
  OpsSegment(this.text, this.attrs);
  final String text;
  final Map<String, dynamic> attrs;
}

class OpsLine {
  OpsLine(this.segments, this.attrs);
  final List<OpsSegment> segments;

  /// Attributes of the closing "\n": these hold the block formatting.
  final Map<String, dynamic> attrs;
}

/// Splits Quill ops into lines. Each line has its inline segments and the
/// attributes of its closing "\n" (alignment, list, header, indent).
List<OpsLine> splitOpsIntoLines(List<dynamic> ops) {
  final lines = <OpsLine>[];
  var segments = <OpsSegment>[];
  for (final raw in ops) {
    if (raw is! Map) continue;
    final insert = raw['insert'];
    if (insert is! String) continue; // embeds (images, ...) are not supported
    final attrs = _attrMap(raw['attributes']);
    final parts = insert.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) segments.add(OpsSegment(parts[i], attrs));
      if (i < parts.length - 1) {
        lines.add(OpsLine(segments, attrs));
        segments = <OpsSegment>[];
      }
    }
  }
  if (segments.isNotEmpty) lines.add(OpsLine(segments, const {}));
  return lines;
}

String opsToHtml(List<dynamic> ops) {
  final lines = splitOpsIntoLines(ops);
  if (lines.isEmpty) return '<p><br></p>';

  // 2. Render the lines, grouping list items.
  final sb = StringBuffer();
  final stack = <String>[]; // open list tags, outermost first

  void closeListsTo(int depth) {
    while (stack.length > depth) {
      sb.write('</li></${stack.removeLast()}>');
    }
  }

  for (final line in lines) {
    final style = _blockStyle(line.attrs);
    final inner = _renderInline(line.segments);
    final list = line.attrs['list'];

    if (list == 'bullet' ||
        list == 'ordered' ||
        list == 'checked' ||
        list == 'unchecked') {
      final tag = list == 'ordered' ? 'ol' : 'ul';
      final indent = line.attrs['indent'];
      final depth = indent is int && indent > 0 ? indent : 0;

      if (stack.length > depth + 1) closeListsTo(depth + 1);
      if (stack.length == depth + 1 && stack.last != tag) closeListsTo(depth);
      if (stack.length == depth + 1) {
        sb.write('</li>'); // next item at the same level
      } else {
        while (stack.length < depth + 1) {
          sb.write('<$tag>');
          stack.add(tag);
        }
      }
      // The <li> stays open so a deeper list can nest inside it.
      sb.write('<li$style>${inner.isEmpty ? '' : inner}');
      continue;
    }

    closeListsTo(0);
    final header = line.attrs['header'];
    final tag = header is int && header >= 1 && header <= 6 ? 'h$header' : 'p';
    sb.write('<$tag$style>${inner.isEmpty ? '<br>' : inner}</$tag>');
  }
  closeListsTo(0);
  return sb.toString();
}

Map<String, dynamic> _attrMap(dynamic raw) {
  if (raw is! Map) return const {};
  return raw.map((k, v) => MapEntry(k.toString(), v));
}

String _blockStyle(Map<String, dynamic> attrs) {
  final align = attrs['align'];
  if (align == 'center' || align == 'right' || align == 'justify') {
    return ' style="text-align: $align;"';
  }
  return '';
}

String _renderInline(List<OpsSegment> segments) {
  final sb = StringBuffer();
  for (final seg in segments) {
    final open = StringBuffer();
    final closers = <String>[];

    void wrap(String tag, [String attributes = '']) {
      open.write('<$tag$attributes>');
      closers.add('</$tag>');
    }

    final link = seg.attrs['link'];
    if (link is String && link.isNotEmpty) {
      wrap('a', ' href="${_escape(link, quotes: true)}"');
    }
    if (seg.attrs['bold'] == true) wrap('b');
    if (seg.attrs['italic'] == true) wrap('i');
    if (seg.attrs['underline'] == true) wrap('u');
    if (seg.attrs['strike'] == true) wrap('s');

    sb
      ..write(open)
      ..write(_escape(seg.text))
      ..write(closers.reversed.join());
  }
  return sb.toString();
}

String _escape(String s, {bool quotes = false}) {
  var r = s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  if (quotes) r = r.replaceAll('"', '&quot;');
  return r;
}

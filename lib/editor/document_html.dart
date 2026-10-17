import 'package:flutter_quill/flutter_quill.dart';

import 'html_codec.dart';

/// Loads stored HTML into a Quill document.
Document htmlToDocument(String html) => Document.fromJson(htmlToOps(html));

/// Serializes a Quill document to the HTML format stored and synced.
String documentToHtml(Document document) =>
    opsToHtml(document.toDelta().toJson());

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';
import '../editor/html_codec.dart';
import 'docx_builder.dart';

const _docxMime =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

/// One chapter as a .docx: title (20pt bold), a blank line, then the text.
/// [ops] is the chapter's Quill content (Document.toDelta().toJson()).
Uint8List buildChapterDocx(String title, List<dynamic> ops) {
  final doc = DocxBuilder()
    ..heading(title, points: 20)
    ..blank()
    ..body(ops);
  return doc.build();
}

/// The whole story as a .docx: title (26pt), description (italic), then every
/// chapter in document order.
Uint8List buildStoryDocx({
  required String storyTitle,
  required String description,
  required List<Chapter> chapters,
}) {
  final doc = DocxBuilder()
    ..heading(storyTitle, points: 26)
    ..blank();

  if (description.trim().isNotEmpty) {
    doc
      ..plain(description, italic: true)
      ..blank();
  }

  for (final chapter in chapters) {
    doc
      ..heading(chapter.title, points: 16)
      ..blank()
      ..body(htmlToOps(chapter.contentHtml))
      ..blank()
      ..blank();
  }
  return doc.build();
}

/// Android / iOS: opens the share sheet, like the Android app did.
/// Windows and other desktops: opens a "Save as" dialog.
Future<void> deliverDocx(
  BuildContext context, {
  required String title,
  required Uint8List bytes,
}) async {
  // Grab this before the awaits below.
  final messenger = ScaffoldMessenger.of(context);
  final fileName = '${_safeFileName(title)}.docx';

  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          subject: title,
          files: [XFile(file.path, mimeType: _docxMime, name: fileName)],
        ),
      );
    } else {
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save "$title" as',
        fileName: fileName,
        bytes: bytes,
      );
      if (saved != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Saved $fileName')));
      }
    }
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Could not export: $e')));
  }
}

/// Removes characters Windows and Android do not allow in file names, but
/// keeps accented and non-Latin letters (the Android app stripped those).
String _safeFileName(String title) {
  final cleaned =
      title.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '').trim();
  return cleaned.isEmpty ? 'document' : cleaned;
}

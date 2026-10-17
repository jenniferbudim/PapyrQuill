import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Asks for a new chapter title. Returns the trimmed title, or null when the
/// dialog was cancelled or the title is empty or unchanged.
Future<String?> askChapterTitle(BuildContext context, String current) async {
  final controller = TextEditingController(text: current);
  controller.selection =
      TextSelection(baseOffset: 0, extentOffset: current.length);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colorBackground,
      title: const Text('Rename Chapter',
          style: TextStyle(color: cardTitleColor)),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: fieldDecoration('Chapter Title'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: darkPink)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: darkPink,
            foregroundColor: colorBackground,
          ),
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  final title = result?.trim();
  if (title == null || title.isEmpty || title == current) return null;
  return title;
}

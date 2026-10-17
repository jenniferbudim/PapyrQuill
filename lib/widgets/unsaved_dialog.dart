import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// What the user picked when asked about unsaved changes.
enum LeaveChoice { save, discard, keepEditing }

/// "You have unsaved changes" dialog. Closing it any other way counts as
/// [LeaveChoice.keepEditing], so nothing is ever lost by accident.
Future<LeaveChoice> askUnsavedChanges(
  BuildContext context, {
  String message =
      'You have changes that are not saved yet. Save them before leaving?',
}) async {
  final choice = await showDialog<LeaveChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colorBackground,
      title:
          const Text('Unsaved changes', style: TextStyle(color: cardTitleColor)),
      content: Text(message, style: const TextStyle(color: cardBodyColor)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, LeaveChoice.keepEditing),
          child: const Text('Keep editing',
              style: TextStyle(color: cardBodyColor)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, LeaveChoice.discard),
          child: Text('Discard',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: darkPink,
            foregroundColor: colorBackground,
          ),
          onPressed: () => Navigator.pop(ctx, LeaveChoice.save),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  return choice ?? LeaveChoice.keepEditing;
}

import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../editor/document_html.dart';
import '../export/docx_exporter.dart';
import '../providers.dart';
import '../repository/papyr_repository.dart';
import '../spell/spell_check_dialog.dart';
import '../spell/spell_checker.dart';
import '../theme/app_theme.dart';
import '../widgets/app_tabs.dart';
import '../widgets/desktop_shell.dart';
import '../widgets/rename_dialog.dart';
import '../widgets/unsaved_dialog.dart';
import 'document_screen.dart';

/// Port of EditorScreen.kt + EditorViewModel.kt.
///
/// Behavior carried over from the Android app:
///  - opens the local copy immediately, then pulls the latest chapter from the
///    server;
///  - auto-saves 2 seconds after typing stops, and on back / manual save;
///  - toolbar: bold, italic, underline, strikethrough, alignment cycle,
///    bulleted list, save; undo / redo and share in the app bar.
///
/// Differences:
///  - undo/redo uses flutter_quill's built-in history instead of the manual
///    snapshot stacks;
///  - server content that arrives after load is only applied if you haven't
///    started typing yet, so it can't overwrite your edits;
///  - also saves when the app goes to the background, and Ctrl+S works on
///    Windows.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.chapterId});

  final int chapterId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with WidgetsBindingObserver {
  static const _autoSaveDelay = Duration(seconds: 2);

  /// Space between the text and the left / right screen edge.
  static const double _sideMargin = 32;

  /// Editor text size relative to the default.
  static const double _textZoom = 1.25;

  late final PapyrRepository _repo;
  QuillController? _controller;

  /// The editor's focus, so Android can keep the cursor active after an
  /// auto-save (see [_restoreFocusIfLost]).
  final FocusNode _editorFocus = FocusNode(debugLabel: 'chapter editor');
  StreamSubscription<dynamic>? _changesSub;
  Timer? _saveTimer;

  Chapter? _chapter;
  String _lastSavedHtml = '';

  /// True when the user has edited since the last load or save. Backed by a
  /// notifier so the back-button guard (PopScope) reacts to changes.
  final ValueNotifier<bool> _dirtyNotifier = ValueNotifier<bool>(false);
  bool get _dirty => _dirtyNotifier.value;
  set _dirty(bool value) => _dirtyNotifier.value = value;

  late final LeaveGuardHolder _guard;
  Future<bool> Function()? _previousLeaveGuard;

  /// Asks before the Windows window is closed with unsaved changes.
  AppLifecycleListener? _exitListener;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(repositoryProvider);
    WidgetsBinding.instance.addObserver(this);
    _exitListener = AppLifecycleListener(onExitRequested: _onExitRequested);
    _guard = LeaveGuardHolder.of(context);
    _previousLeaveGuard = _guard.check;
    _guard.check = _confirmLeave;
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Hand the check back to the screen underneath, if there is one.
    if (_guard.check == _confirmLeave) {
      _guard.check = _previousLeaveGuard;
    }
    _saveTimer?.cancel();
    // _save reads the document synchronously before its first await, so it is
    // safe to dispose the controller right after starting it.
    unawaited(_save());
    _changesSub?.cancel();
    _exitListener?.dispose();
    _controller?.dispose();
    _editorFocus.dispose();
    _dirtyNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_save());
    }
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> _load() async {
    // 1. Local copy first, so the editor isn't blank while waiting.
    final local = await _repo.getChapterById(widget.chapterId);
    if (!mounted || local == null) return;
    _chapter = local;

    final controller = QuillController(
      document: htmlToDocument(local.contentHtml),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller = controller;
    _lastSavedHtml = documentToHtml(controller.document);
    _listenToChanges();
    setState(() {});

    // 2. Latest copy from the server (may have been edited elsewhere).
    final fresh = await _repo.refreshChapter(widget.chapterId);
    if (!mounted) return;
    if (fresh == null) {
      // Say so instead of silently showing an old (maybe empty) copy.
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text(
              'Could not load the latest text from the server. Showing the '
              'copy saved on this device.'),
        ));
      return;
    }
    _chapter = fresh;
    // "Has the user typed anything yet?" is answered by comparing the text,
    // not by the dirty flag, which an editor event could set by itself.
    final c = _controller;
    final typed = c != null && documentToHtml(c.document) != _lastSavedHtml;
    final applied = !typed && fresh.contentHtml != local.contentHtml;
    if (applied) {
      _replaceContent(fresh.contentHtml);
    }
    // TEMPORARY diagnostics (the Windows exe has no console): shows what the
    // server sent and what was done with it. Remove once sync is confirmed.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(
          'Sync check: server text ${fresh.contentHtml.length} chars, '
          'local copy ${local.contentHtml.length} chars, '
          '${typed ? "you had typed already" : applied ? "server text applied" : "nothing to change"}. '
          'Editor now has ${_controller?.document.toPlainText().trim().length ?? 0} letters.',
        ),
      ));
    setState(() {});
  }

  void _listenToChanges() {
    _changesSub?.cancel();
    _changesSub = _controller?.document.changes.listen((_) {
      _dirty = true;
      _saveTimer?.cancel();
      _saveTimer = Timer(_autoSaveDelay, () => unawaited(_save()));
    });
  }

  void _replaceContent(String html) {
    final controller = _controller;
    if (controller == null) return;
    _changesSub?.cancel();
    final document = htmlToDocument(html);
    controller.document = document;
    controller.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    _lastSavedHtml = documentToHtml(document);
    _dirty = false;
    _listenToChanges();
  }

  // ── Saving ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    _saveTimer?.cancel();
    final controller = _controller;
    final chapter = _chapter;
    if (controller == null || chapter == null || !_dirty) return;

    final hadFocus = _editorFocus.hasFocus;
    final html = documentToHtml(controller.document);
    _dirty = false;
    _restoreFocusIfLost(hadFocus);
    if (html == _lastSavedHtml) return;

    _lastSavedHtml = html;
    final updated = chapter.copyWith(contentHtml: html);
    _chapter = updated;
    await _repo.updateChapter(updated);
    _restoreFocusIfLost(hadFocus);
  }

  /// Android: after an auto-save the text cursor used to go inactive, so you
  /// had to tap the text again. If the editor had focus when the save started
  /// and lost it by itself, give it back. (Windows is left as it is.)
  void _restoreFocusIfLost(bool hadFocus) {
    if (!hadFocus || defaultTargetPlatform != TargetPlatform.android) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editorFocus.hasFocus) return;
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      if (ModalRoute.of(context)?.isCurrent != true) return;
      _editorFocus.requestFocus();
    });
  }

  // ── Leaving with unsaved changes ──────────────────────────────────────────

  /// Back button / swipe back while there are unsaved changes.
  Future<void> _onBackWithUnsaved() async {
    final choice = await askUnsavedChanges(context);
    if (!mounted) return;
    switch (choice) {
      case LeaveChoice.save:
        await _save();
        if (mounted) Navigator.of(context).pop();
      case LeaveChoice.discard:
        _saveTimer?.cancel();
        _dirty = false; // dispose() then has nothing to save
        Navigator.of(context).pop();
      case LeaveChoice.keepEditing:
        break;
    }
  }

  /// Clicking the logo on Windows: true if it is fine to leave.
  Future<bool> _confirmLeave() async {
    if (!_dirty || !mounted) return true;
    switch (await askUnsavedChanges(context)) {
      case LeaveChoice.save:
        await _save();
        return true;
      case LeaveChoice.discard:
        _saveTimer?.cancel();
        _dirty = false;
        return true;
      case LeaveChoice.keepEditing:
        return false;
    }
  }

  /// The Windows window's close button. (Not sent on Android, where leaving
  /// the app is covered by the auto-save and the save on going to background.)
  Future<AppExitResponse> _onExitRequested() async {
    if (!_dirty || !mounted) return AppExitResponse.exit;
    switch (await askUnsavedChanges(context)) {
      case LeaveChoice.save:
        await _save();
        return AppExitResponse.exit;
      case LeaveChoice.discard:
        _saveTimer?.cancel();
        _dirty = false;
        return AppExitResponse.exit;
      case LeaveChoice.keepEditing:
        return AppExitResponse.cancel;
    }
  }

  /// Renames the chapter. Any typing not yet saved is saved first, so the
  /// rename never writes an older copy of the text.
  Future<void> _rename() async {
    final chapter = _chapter;
    if (chapter == null) return;
    final title = await askChapterTitle(context, chapter.title);
    if (title == null || !mounted) return;
    await _save();
    final latest = _chapter ?? chapter;
    final updated = latest.copyWith(title: title);
    setState(() => _chapter = updated);
    await _repo.updateChapter(updated);
  }

  Future<void> _manualSave() async {
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
      );
  }

  /// "Check spelling": walks through the unknown words, one at a time.
  Future<void> _checkSpelling() async {
    final controller = _controller;
    if (controller == null) return;
    final SpellChecker checker;
    try {
      checker = await SpellChecker.load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('The dictionary could not be loaded.'),
        ));
      return;
    }
    if (!mounted) return;
    if (checker.findMisspellings(controller.document.toPlainText(), limit: 1)
        .isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('No spelling mistakes found.'),
          duration: Duration(seconds: 2),
        ));
      return;
    }
    await showSpellCheck(context, controller, checker);
  }

  /// Exports what is on screen right now (including unsaved edits).
  Future<void> _shareDocx() async {
    final controller = _controller;
    if (controller == null) return;
    final title = _chapter?.title ?? 'Chapter';
    final bytes = buildChapterDocx(
      title,
      controller.document.toDelta().toJson(),
    );
    await deliverDocx(context, title: title, bytes: bytes);
  }

  // ── Formatting ────────────────────────────────────────────────────────────

  void _toggle(QuillController c, Attribute attribute) {
    final active = c.getSelectionStyle().attributes.containsKey(attribute.key);
    c.formatSelection(active ? Attribute.clone(attribute, null) : attribute);
  }

  void _toggleBullets(QuillController c) {
    final current = c.getSelectionStyle().attributes[Attribute.list.key];
    final active = current == Attribute.ul;
    c.formatSelection(active ? Attribute.clone(Attribute.ul, null) : Attribute.ul);
  }

  /// Cycles left -> center -> right -> justify -> left, like the Android app.
  void _cycleAlignment(QuillController c) {
    final current =
        c.getSelectionStyle().attributes[Attribute.align.key]?.value as String?;
    switch (current) {
      case null:
      case 'left':
        c.formatSelection(Attribute.centerAlignment);
      case 'center':
        c.formatSelection(Attribute.rightAlignment);
      case 'right':
        c.formatSelection(Attribute.justifyAlignment);
      default:
        // Back to left: remove the alignment attribute.
        c.formatSelection(Attribute.clone(Attribute.align, null));
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _dirtyNotifier,
      builder: (context, dirty, child) => PopScope(
        canPop: !dirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_onBackWithUnsaved());
        },
        child: child!,
      ),
      child: _buildEditor(context),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final controller = _controller;
    if (useDesktopLayout(context)) return _buildDesktop(context, controller);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _manualSave,
      },
      child: Scaffold(
        backgroundColor: colorBackground,
        appBar: AppBar(
          backgroundColor: mediumPink,
          foregroundColor: darkPink,
          title: InkWell(
            onTap: _chapter == null ? null : () => unawaited(_rename()),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _chapter?.title ?? 'Loading...',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkPink,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (_chapter != null) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.edit,
                        size: 16, color: darkPink.withValues(alpha: 0.6)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (controller != null)
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Row(
                  children: [
                    IconButton(
                      tooltip: 'Undo',
                      icon: const Icon(Icons.undo),
                      onPressed: controller.hasUndo ? controller.undo : null,
                    ),
                    IconButton(
                      tooltip: 'Redo',
                      icon: const Icon(Icons.redo),
                      onPressed: controller.hasRedo ? controller.redo : null,
                    ),
                  ],
                ),
              ),
            IconButton(
              tooltip: 'Share as DOCX',
              icon: const Icon(Icons.share),
              onPressed: () => unawaited(_shareDocx()),
            ),
          ],
        ),
        body: controller == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                // Keeps lines a comfortable length on wide Windows windows.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  // Text is 25% larger than the editor's default (on top of
                  // any font size set in the phone's settings).
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(
                        MediaQuery.textScalerOf(context).scale(1) *
                            _textZoom,
                      ),
                    ),
                    child: QuillEditor.basic(
                      controller: controller,
                      focusNode: _editorFocus,
                      config: const QuillEditorConfig(
                        placeholder: 'Start writing your story…',
                        expands: true,
                        autoFocus: false,
                        // The margin is inside the editor, so tapping it
                        // still places the cursor, while the text stays well
                        // away from the screen edge (and Android's edge
                        // swipe-back gesture).
                        padding: EdgeInsets.symmetric(
                          horizontal: _sideMargin,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        bottomNavigationBar:
            controller == null ? null : _buildToolbar(controller),
      ),
    );
  }

  // ── Windows layout ───────────────────────────────────────────────────────

  /// Opens another chapter of the same story from the sidebar.
  Future<void> _switchChapter(Chapter target) async {
    if (target.id == _chapter?.id) return;
    await _save();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      instantRoute<void>(EditorScreen(chapterId: target.id)),
    );
  }

  Widget _buildDesktop(BuildContext context, QuillController? controller) {
    final storyId = _chapter?.storyId;
    final chapters = storyId == null
        ? const <Chapter>[]
        : ref.watch(chaptersProvider(storyId)).valueOrNull ??
            const <Chapter>[];
    final selected = chapters.indexWhere((c) => c.id == _chapter?.id);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _manualSave,
      },
      child: Scaffold(
        backgroundColor: colorBackground,
        body: DesktopShell(
          title: _chapter?.title,
          sidebar: SidebarList(
            labels: [for (final c in chapters) c.title],
            selectedIndex: selected,
            onTap: (i) => unawaited(_switchChapter(chapters[i])),
            onOpenInNewTab: (i) => openInNewTab(context, [
              TabPage(DocumentScreen(storyId: chapters[i].storyId),
                  routeName: 'document'),
              TabPage(EditorScreen(chapterId: chapters[i].id)),
            ]),
          ),
          child: controller == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildToolbar(controller, desktop: true),
                    Expanded(
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(
                            MediaQuery.textScalerOf(context).scale(1) *
                                _textZoom,
                          ),
                        ),
                        child: QuillEditor.basic(
                          controller: controller,
                          config: const QuillEditorConfig(
                            placeholder: 'Start writing your story…',
                            expands: true,
                            autoFocus: false,
                            padding: EdgeInsets.fromLTRB(40, 24, 40, 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildToolbar(QuillController c, {bool desktop = false}) {
    return Material(
      color: mediumPink,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          // Buttons must not take focus, or clicking one on Windows would
          // pull the cursor out of the editor.
          child: Focus(
            canRequestFocus: false,
            descendantsAreFocusable: false,
            child: ListenableBuilder(
            listenable: c,
            builder: (context, _) {
              final attrs = c.getSelectionStyle().attributes;
              bool has(Attribute a) => attrs.containsKey(a.key);

              final align = attrs[Attribute.align.key]?.value as String?;
              final alignIcon = switch (align) {
                'center' => Icons.format_align_center,
                'right' => Icons.format_align_right,
                'justify' => Icons.format_align_justify,
                _ => Icons.format_align_left,
              };
              final alignLabel = switch (align) {
                'center' => 'Align center',
                'right' => 'Align right',
                'justify' => 'Justify',
                _ => 'Align left',
              };

              return Row(
                mainAxisAlignment: desktop
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.spaceEvenly,
                children: [
                  _ToolbarButton(
                    icon: Icons.format_bold,
                    tooltip: 'Bold (Ctrl+B)',
                    active: has(Attribute.bold),
                    onPressed: () => _toggle(c, Attribute.bold),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_italic,
                    tooltip: 'Italic (Ctrl+I)',
                    active: has(Attribute.italic),
                    onPressed: () => _toggle(c, Attribute.italic),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_underlined,
                    tooltip: 'Underline (Ctrl+U)',
                    active: has(Attribute.underline),
                    onPressed: () => _toggle(c, Attribute.underline),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_strikethrough,
                    tooltip: 'Strikethrough',
                    active: has(Attribute.strikeThrough),
                    onPressed: () => _toggle(c, Attribute.strikeThrough),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: darkPink.withValues(alpha: 0.4),
                  ),
                  _ToolbarButton(
                    icon: alignIcon,
                    tooltip: alignLabel,
                    onPressed: () => _cycleAlignment(c),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_list_bulleted,
                    tooltip: 'Bulleted list',
                    active: attrs[Attribute.list.key] == Attribute.ul,
                    onPressed: () => _toggleBullets(c),
                  ),
                  _ToolbarButton(
                    icon: Icons.spellcheck,
                    tooltip: 'Check spelling',
                    onPressed: () => unawaited(_checkSpelling()),
                  ),
                  _ToolbarButton(
                    icon: Icons.save,
                    tooltip: 'Save (Ctrl+S)',
                    onPressed: _manualSave,
                  ),
                  if (desktop) ...[
                    const Spacer(),
                    _ToolbarButton(
                      icon: Icons.undo,
                      tooltip: 'Undo',
                      onPressed: c.hasUndo ? c.undo : () {},
                    ),
                    _ToolbarButton(
                      icon: Icons.redo,
                      tooltip: 'Redo',
                      onPressed: c.hasRedo ? c.redo : () {},
                    ),
                    _ToolbarButton(
                      icon: Icons.share,
                      tooltip: 'Share as DOCX',
                      onPressed: () => unawaited(_shareDocx()),
                    ),
                  ],
                ],
              );
            },
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: active ? lighterPink : Colors.transparent,
      ),
      icon: Icon(icon, color: darkPink),
    );
  }
}

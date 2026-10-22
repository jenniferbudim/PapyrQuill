import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

// Browser-style tabs for the Windows (desktop) app.
//
// Every tab has its own Navigator, so a tab keeps its whole stack of screens
// (Home > Story > Chapter ...) and an editor keeps its text and cursor while
// you look at another tab. The phone app never creates any of this.

/// Where the "is it fine to leave?" check of the visible screen is kept. There
/// is one per tab, so closing a tab asks only about that tab's unsaved work.
class LeaveGuardHolder {
  /// Returns true when it is fine to leave (nothing to save, or the user chose
  /// Save / Discard) and false when the user chose to keep editing.
  Future<bool> Function()? check;

  static final LeaveGuardHolder _fallback = LeaveGuardHolder();

  /// The holder of the tab this context is in (or a shared one outside tabs).
  static LeaveGuardHolder of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabScope>()?.tab.guard ??
      _fallback;
}

/// One screen to put in a tab's stack.
class TabPage {
  const TabPage(this.page, {this.routeName});

  final Widget page;

  /// Route name, for screens other screens look for (the Document screen is
  /// called 'document').
  final String? routeName;
}

class AppTab {
  AppTab(this.id, this.pages);

  final int id;

  /// The screens the tab starts with, bottom first.
  final List<TabPage> pages;

  /// Shown on the tab. Screens set it through [TabTitle].
  final ValueNotifier<String> title = ValueNotifier<String>('PapyrQuill');

  final LeaveGuardHolder guard = LeaveGuardHolder();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class TabsController extends ChangeNotifier {
  TabsController({required this.homePage}) {
    _tabs.add(_make(const []));
  }

  /// Builds a fresh Home screen (every tab starts with one at the bottom).
  final Widget Function() homePage;

  final List<AppTab> _tabs = [];
  int _active = 0;
  int _nextId = 1;
  bool _closing = false;

  List<AppTab> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _active;
  AppTab get activeTab => _tabs[_active];

  AppTab _make(List<TabPage> above) =>
      AppTab(_nextId++, [TabPage(homePage()), ...above]);

  /// Opens a tab showing Home with [above] pushed on top of it.
  void openTab(List<TabPage> above, {bool activate = true}) {
    _tabs.add(_make(above));
    if (activate) _active = _tabs.length - 1;
    notifyListeners();
  }

  void activate(int index) {
    if (index < 0 || index >= _tabs.length || index == _active) return;
    _active = index;
    notifyListeners();
  }

  /// Moves to the next (1) or previous (-1) tab, wrapping around.
  void step(int delta) => activate((_active + delta) % _tabs.length);

  /// Closes [tab] after its screen has had a chance to ask about unsaved
  /// changes. Closing the last tab leaves a fresh Home tab.
  Future<void> close(AppTab tab) async {
    if (_closing) return;
    final index = _tabs.indexOf(tab);
    if (index < 0) return;
    _closing = true;
    try {
      final previous = activeTab;
      if (previous != tab) {
        // Show the tab first so the person sees what the question is about.
        _active = index;
        notifyListeners();
        await WidgetsBinding.instance.endOfFrame;
      }
      final ok = await tab.guard.check?.call() ?? true;
      if (!ok) return;
      final i = _tabs.indexOf(tab);
      if (i < 0) return;
      _tabs.removeAt(i);
      if (_tabs.isEmpty) {
        _tabs.add(_make(const []));
        _active = 0;
      } else if (previous != tab && _tabs.contains(previous)) {
        _active = _tabs.indexOf(previous);
      } else {
        _active = math.min(i, _tabs.length - 1);
      }
      notifyListeners();
    } finally {
      _closing = false;
    }
  }
}

class TabScope extends InheritedWidget {
  const TabScope({
    super.key,
    required this.controller,
    required this.tab,
    required super.child,
  });

  final TabsController controller;
  final AppTab tab;

  static TabScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabScope>();

  @override
  bool updateShouldNotify(TabScope oldWidget) =>
      oldWidget.tab != tab || oldWidget.controller != controller;
}

/// Opens [pages] (on top of Home) in a new tab. Does nothing outside tabs.
void openInNewTab(BuildContext context, List<TabPage> pages) {
  context.getInheritedWidgetOfExactType<TabScope>()?.controller.openTab(pages);
}

/// True while Ctrl is held, so Ctrl+click can mean "open in a new tab".
bool isCtrlPressed() => HardwareKeyboard.instance.isControlPressed;

/// Calls [onMiddleClick] when the mouse's middle button is pressed on [child].
class MiddleClickable extends StatelessWidget {
  const MiddleClickable({
    super.key,
    required this.onMiddleClick,
    required this.child,
  });

  final VoidCallback onMiddleClick;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kMiddleMouseButton) {
          onMiddleClick();
        }
      },
      child: child,
    );
  }
}

/// Puts [title] on the tab while this screen is the one being shown.
class TabTitle extends StatelessWidget {
  const TabTitle({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = TabScope.maybeOf(context);
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (scope != null && current && scope.tab.title.value != title) {
      final notifier = scope.tab.title;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (notifier.value != title) notifier.value = title;
      });
    }
    return child;
  }
}

/// The tab strip plus the tabs' contents. Ctrl+T new tab, Ctrl+W close,
/// Ctrl+Tab / Ctrl+Shift+Tab next / previous, Ctrl+1..9 jump to a tab.
class TabsHost extends StatefulWidget {
  const TabsHost({super.key, required this.homeBuilder});

  final Widget Function() homeBuilder;

  @override
  State<TabsHost> createState() => _TabsHostState();
}

class _TabsHostState extends State<TabsHost> {
  late final TabsController _controller =
      TabsController(homePage: widget.homeBuilder);
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  static final List<LogicalKeyboardKey> _digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    // A dialog is open: leave the keys alone.
    if (_route?.isCurrent != true) return false;
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed || keyboard.isAltPressed) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyT) {
      _controller.openTab(const []);
      return true;
    }
    if (key == LogicalKeyboardKey.keyW) {
      unawaited(_controller.close(_controller.activeTab));
      return true;
    }
    if (key == LogicalKeyboardKey.tab) {
      _controller.step(keyboard.isShiftPressed ? -1 : 1);
      return true;
    }
    final digit = _digits.indexOf(key);
    if (digit >= 0) {
      // Ctrl+9 is the last tab, as in browsers.
      _controller.activate(
          digit == 8 ? _controller.tabs.length - 1 : digit);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _controller.tabs;
    final active = _controller.activeIndex;
    return Material(
      color: colorBackground,
      child: Column(
        children: [
          _TabStrip(controller: _controller),
          Expanded(
            child: IndexedStack(
              index: active,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  KeyedSubtree(
                    key: ValueKey<int>(tabs[i].id),
                    // A tab you are not looking at must not take the keys.
                    child: ExcludeFocus(
                      excluding: i != active,
                      child: TabScope(
                        controller: _controller,
                        tab: tabs[i],
                        // Each Navigator needs its own hero controller.
                        child: HeroControllerScope.none(
                          child: Navigator(
                            key: tabs[i].navigatorKey,
                            onGenerateInitialRoutes: (navigator, _) => [
                              for (final p in tabs[i].pages)
                                PageRouteBuilder<void>(
                                  settings: RouteSettings(name: p.routeName),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                  pageBuilder: (_, __, ___) => p.page,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.controller});

  final TabsController controller;

  static const double _plusWidth = 44;

  @override
  Widget build(BuildContext context) {
    final tabs = controller.tabs;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: darkPink, width: 3)),
      ),
      child: Material(
        color: mediumPink,
        child: SizedBox(
          height: 37,
          child: LayoutBuilder(
            builder: (context, box) {
              final width = ((box.maxWidth - _plusWidth) / tabs.length)
                  .clamp(110.0, 220.0)
                  .toDouble();
              return Row(
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < tabs.length; i++)
                            SizedBox(
                              width: width,
                              height: 37,
                              child: _TabButton(
                                tab: tabs[i],
                                selected: i == controller.activeIndex,
                                onTap: () => controller.activate(i),
                                onClose: () =>
                                    unawaited(controller.close(tabs[i])),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'New tab (Ctrl+T)',
                    child: InkWell(
                      canRequestFocus: false,
                      onTap: () => controller.openTab(const []),
                      child: const SizedBox(
                        width: _plusWidth,
                        height: 37,
                        child: Icon(Icons.add, size: 20, color: cardTitleColor),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Light pink for tabs that are not the active one.
const Color _inactiveTabPink = Color(0xFFF6CCE5);

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(8),
      topRight: Radius.circular(8),
    );
    return MiddleClickable(
      // Middle-click closes a tab, as in a browser.
      onMiddleClick: onClose,
      child: Padding(
        padding: const EdgeInsets.only(top: 5, left: 2, right: 2),
        child: Material(
          color: selected ? darkPink : _inactiveTabPink,
          borderRadius: radius,
          child: InkWell(
            canRequestFocus: false,
            borderRadius: radius,
            onTap: onTap,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: tab.title,
                    builder: (context, title, _) => Text(
                      title.isEmpty ? 'PapyrQuill' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Handlee',
                        fontSize: 14,
                        color: selected
                            ? Colors.white
                            : cardTitleColor,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Close tab (Ctrl+W)',
                  child: InkWell(
                    canRequestFocus: false,
                    onTap: onClose,
                    child: Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: selected ? Colors.white : cardTitleColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_tabs.dart';

/// True when the Windows (desktop) layouts should be used: a desktop platform
/// and a window wide enough for the sidebar. Tests and phones use the mobile
/// layouts.
bool useDesktopLayout(BuildContext context) =>
    isDesktopPlatform() && MediaQuery.sizeOf(context).width >= 700;

/// True on Windows, Linux and macOS (where the tabs are used).
bool isDesktopPlatform() {
  final p = defaultTargetPlatform;
  return p == TargetPlatform.windows ||
      p == TargetPlatform.linux ||
      p == TargetPlatform.macOS;
}

/// A page route that swaps screens without any animation, used when the
/// sidebar switches to another story or chapter so it feels like in-place
/// navigation.
Route<T> instantRoute<T>(Widget page, {String? name}) => PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => page,
    );

const double kSidebarWidth = 170;

/// The left column of every Windows screen: the logo on beige, an optional
/// list underneath, then the pink and dark pink strips, then [child].
class DesktopShell extends StatelessWidget {
  const DesktopShell({
    super.key,
    required this.child,
    this.sidebar,
    this.title,
  });

  final Widget child;

  /// Shown on this screen's tab.
  final String? title;

  /// Shown under the logo (for example the list of stories).
  final Widget? sidebar;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: kSidebarWidth,
          child: ColoredBox(
            color: cardBeige,
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Clicking the logo goes back to the Home screen.
                Tooltip(
                  message: 'Home',
                  child: InkWell(
                    canRequestFocus: false,
                    onTap: () async {
                      // Give the current screen a chance to ask about unsaved
                      // changes first.
                      final ok = await LeaveGuardHolder.of(context).check?.call() ?? true;
                      if (!ok || !context.mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 118,
                      fit: BoxFit.contain,
                      semanticLabel: 'Papyr Quill',
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Expanded(child: sidebar ?? const SizedBox.shrink()),
              ],
            ),
          ),
        ),
        Container(width: 9, color: mediumPink),
        Container(width: 3, color: darkPink),
        Expanded(child: child),
      ],
    );
    final tabTitle = title;
    return tabTitle == null ? row : TabTitle(title: tabTitle, child: row);
  }
}

/// The list in the sidebar: thin lines between rows, the selected row shaded.
class SidebarList extends StatelessWidget {
  const SidebarList({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTap,
    this.onSecondaryTap,
    this.onOpenInNewTab,
  });

  final List<String> labels;
  final int selectedIndex;
  final void Function(int index) onTap;

  /// Right-click on a row (for example "rename").
  final void Function(int index)? onSecondaryTap;

  /// Middle-click or Ctrl+click on a row: open it in a new tab.
  final void Function(int index)? onOpenInNewTab;

  Widget _line() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: sidebarDivider.withValues(alpha: 0.8),
      );

  @override
  Widget build(BuildContext context) {
    // The rows must never take keyboard focus, or the arrow keys would move a
    // highlight through the list instead of the text cursor.
    return ExcludeFocus(
      child: ListView(
      padding: EdgeInsets.zero,
      children: [
        _line(),
        for (var i = 0; i < labels.length; i++)
          Column(
            children: [
              Material(
                color: i == selectedIndex ? sidebarSelected : Colors.transparent,
                child: MiddleClickable(
                  onMiddleClick: () => onOpenInNewTab?.call(i),
                  child: InkWell(
                  canRequestFocus: false,
                  onTap: () {
                    if (onOpenInNewTab != null && isCtrlPressed()) {
                      onOpenInNewTab!(i);
                    } else {
                      onTap(i);
                    }
                  },
                  onSecondaryTap:
                      onSecondaryTap == null ? null : () => onSecondaryTap!(i),
                  child: Container(
                    height: 40,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: cardTitleColor,
                      ),
                    ),
                  ),
                ),
                ),
              ),
              _line(),
            ],
          ),
      ],
    ),
    );
  }
}

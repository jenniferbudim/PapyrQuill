import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Icons a character group can use. The group stores the index (0-5), as in
/// the Kotlin app, so keep the order.
const List<IconData> characterGroupIcons = [
  Icons.person, // 0: person / character
  Icons.language, // 1: globe / world
  Icons.emoji_events, // 2: trophy / crown
  Icons.auto_fix_high, // 3: magic wand
  Icons.monetization_on, // 4: coins
  Icons.psychology, // 5: mind / brain
];

IconData groupIcon(int index) =>
    index >= 0 && index < characterGroupIcons.length
        ? characterGroupIcons[index]
        : Icons.person;

/// Goes back to the Document screen, which is opened with the route name
/// "document" (see home_screen.dart).
void backToDocument(BuildContext context) {
  Navigator.of(context).popUntil(
    (route) => route.settings.name == 'document' || route.isFirst,
  );
}

/// Arch ("tombstone") shape used by the bottom tabs and the add button.
const BorderRadius archTabShape = BorderRadius.only(
  topLeft: Radius.circular(50),
  topRight: Radius.circular(50),
);

/// The open-book arch at the top of the character screens, with the bookmark
/// (upside down, top right) that returns to the Document screen.
class BookTopHeader extends StatelessWidget {
  const BookTopHeader({super.key, required this.onBookmarkClick});

  final VoidCallback onBookmarkClick;

  Widget _pages({
    required double height,
    required Color color,
    required double radius,
  }) {
    final r = Radius.circular(radius);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          // Left page: rounded at its top-right, curving up to the spine.
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(topRight: r),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          // Right page: rounded at its top-left.
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(topLeft: r),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 90,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: _pages(height: 70, color: darkPink, radius: 64),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _pages(height: 40, color: colorBackground, radius: 84),
            ),
            Positioned(
              top: 0,
              right: 20,
              child: Tooltip(
                message: 'Back to document',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBookmarkClick,
                  child: SizedBox(
                    width: 50,
                    height: 100,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: Image.asset(
                        'assets/images/bookmark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

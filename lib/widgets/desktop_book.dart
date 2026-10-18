import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The open-book backdrop of the Windows character screens: a cream strip on
/// top, two dark pink page arcs, pale pink pages with a lighter diagonal on
/// the right page, and the bookmark at the top right (it returns to the
/// document).
class DesktopBook extends StatelessWidget {
  const DesktopBook({
    super.key,
    required this.child,
    required this.onBookmarkClick,
  });

  final Widget child;
  final VoidCallback onBookmarkClick;

  /// Where the page arcs meet, so screens can place content below them.
  static const double arcBottom = 100;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _BookPainter()),
        child,
        Positioned(
          top: 26,
          right: math.max(24, width * 0.06),
          child: Tooltip(
            message: 'Back to document',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBookmarkClick,
              child: SizedBox(
                width: 70,
                height: 105,
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
    );
  }
}

class _BookPainter extends CustomPainter {
  const _BookPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const edgeY = 54.0;
    const centerY = 88.0;

    canvas.drawRect(Offset.zero & size, Paint()..color = bookCream);

    // The top edge of the two pages: each rises a little, then dips to the
    // spine in the middle.
    final arc = Path()
      ..moveTo(0, edgeY)
      ..cubicTo(w * 0.18, edgeY - 22, w * 0.36, edgeY - 14, w * 0.5, centerY)
      ..cubicTo(w * 0.64, edgeY - 14, w * 0.82, edgeY - 22, w, edgeY);

    final pages = Path.from(arc)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(pages, Paint()..color = lightPink);

    // Lighter diagonal across the right page.
    final shade = Path()
      ..moveTo(w * 0.5, centerY)
      ..lineTo(w, h * 0.92)
      ..lineTo(w, h)
      ..lineTo(w * 0.5 + 12, h)
      ..close();
    canvas.drawPath(shade, Paint()..color = bookShade);

    canvas.drawPath(
      arc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round
        ..color = darkPink,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

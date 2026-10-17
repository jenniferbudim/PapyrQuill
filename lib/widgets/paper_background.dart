import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Port of PaperBackground in SplashScreen.kt: the paper texture at 20%
/// opacity behind [child].
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: colorBackground),
        Opacity(
          opacity: 0.2,
          child: Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            // A missing or broken image must never block the app.
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        child,
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../widgets/app_tabs.dart';
import '../widgets/desktop_shell.dart';
import '../widgets/paper_background.dart';
import 'home_screen.dart';

/// Port of SplashScreen.kt: the logo on the paper background for one second,
/// then the home screen (which replaces the splash, so Back never returns
/// here). The startup sync runs during that second.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start the sync now so it overlaps with the splash. The home screen
    // watches the same provider, so it does not run twice.
    ref.read(startupSyncProvider);
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          // Windows (desktop) gets browser-style tabs; phones go straight to
          // Home.
          pageBuilder: (_, __, ___) => isDesktopPlatform()
              ? TabsHost(homeBuilder: () => const HomeScreen())
              : const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: FractionallySizedBox(
            // Half the width, as in Kotlin, but capped for wide Windows
            // windows where half the width would be huge.
            widthFactor: 0.5,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Smaller on Windows, where the window is much wider.
                maxWidth: isDesktopPlatform() ? 220 : 360,
              ),
              child: Image.asset(
                'assets/images/logo.png',
                semanticLabel: 'Papyr Quill Logo',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

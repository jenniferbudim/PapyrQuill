import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_config.dart';
import 'providers.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiConfig = await ApiConfig.load();
  runApp(
    ProviderScope(
      overrides: [apiConfigProvider.overrideWithValue(apiConfig)],
      child: const PapyrQuillApp(),
    ),
  );
}

class PapyrQuillApp extends StatelessWidget {
  const PapyrQuillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PapyrQuill',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // flutter_quill needs its localization delegates.
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      home: const SplashScreen(),
    );
  }
}

// Smoke test: the app starts on the splash screen and moves on to Home.
// This replaces the counter test that `flutter create` generates
// (test/widget_test.dart), which does not apply to this app.

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrquill/data/app_database.dart';
import 'package:papyrquill/main.dart';
import 'package:papyrquill/network/api_config.dart';
import 'package:papyrquill/network/api_models.dart';
import 'package:papyrquill/network/remote_data_source.dart';
import 'package:papyrquill/providers.dart';
import 'package:papyrquill/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every call fails at once, as if the server were unreachable.
class UnreachableServer extends RemoteDataSource {
  UnreachableServer() : super(Dio());

  @override
  Future<List<StoryDto>?> getAllStories() async => null;
}

void main() {
  testWidgets('starts on the splash screen, then shows Home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = await ApiConfig.load();
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigProvider.overrideWithValue(config),
          databaseProvider.overrideWithValue(db),
          remoteDataSourceProvider.overrideWithValue(UnreachableServer()),
        ],
        child: const PapyrQuillApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    // One second on the splash, then the fade to Home.
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Search documents'), findsOneWidget);

    // Remove the widgets before closing the database.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await db.close();
  });
}

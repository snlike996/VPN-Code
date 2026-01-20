// Basic widget tests for the app entry point.
//
// These tests verify that the splash screen renders on startup and that
// localized status text is visible while initialization runs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pixi_vpn/main.dart';
import 'package:pixi_vpn/ui/shared/splash/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows splash screen on launch', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const V2rayGuard());

    // Verify the splash screen is visible with its status text.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('正在处理...'), findsOneWidget);

    // Ensure the app uses the expected theme baseline.
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.debugShowCheckedModeBanner, false);
  });
}

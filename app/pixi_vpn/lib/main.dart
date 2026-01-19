import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pixi_vpn/ui/shared/splash/splash_screen.dart';
import 'di_container.dart' as di;
import 'main_windows.dart' as windows;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if (GetPlatform.isWindows) {
    await windows.bootstrap();
    return;
  }
  if (GetPlatform.isAndroid || GetPlatform.isIOS) {
    MobileAds.instance.initialize();
  }
  // Check if Firebase is already initialized
  if (GetPlatform.isAndroid || GetPlatform.isIOS) {
    await Firebase.initializeApp();
  }
  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await di.init();
  runApp(const V2rayGuard());
}

class V2rayGuard extends StatelessWidget {
  const V2rayGuard({super.key});

  @override
  Widget build(BuildContext context) {
    List<NavigatorObserver> observers = [];

    // Only add Firebase Analytics on mobile
    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      observers.add(FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance));
    }

    return GetMaterialApp(
      navigatorObservers: observers,
      title: 'TSVPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE8E8E8),
        fontFamily: 'SF Pro',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 12.0, height: 1.2), // Standard text
          bodyLarge: TextStyle(fontSize: 14.0, height: 1.2, fontWeight: FontWeight.bold), // Large text
        ),
      ),
      home: SplashScreen(),
    );
  }
}

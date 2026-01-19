import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pixi_vpn/ui/shared/home/v2_home_screen.dart';
import 'package:pixi_vpn/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixi_vpn/utils/link_launcher.dart';
import 'dart:math' as math;
// Import controllers to use typed Get.find
import 'package:pixi_vpn/controller/app_update_controller.dart';
import 'package:pixi_vpn/controller/general_setting_controller.dart';
import 'package:pixi_vpn/controller/app_setting_controller.dart';
// Import onboarding screen so splash can route to it on first run
import 'package:pixi_vpn/ui/shared/splash/on_boarding_screen.dart';


// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  final List<CountryFlag> _flags = [];
  AppUpdateController? _appUpdateController;
  GeneralSettingController? _generalSettingController;
  AppSettingController? _appSettingController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Initialize floating flags
    _flags.addAll([
      CountryFlag('🇵🇰', 0.15, 0.15, 2.0, 0.3),
      CountryFlag('🇦🇪', 0.85, 0.2, 2.5, 0.4),
      CountryFlag('🇩🇪', 0.8, 0.65, 3.0, 0.35),
      CountryFlag('🇺🇸', 0.1, 0.7, 2.2, 0.45),
      CountryFlag('🇫🇷', 0.15, 0.45, 2.8, 0.25),
      CountryFlag('🇬🇧', 0.85, 0.45, 2.3, 0.35),
    ]);

    _initializeApp();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Attempt to get controllers only if registered to prevent runtime errors
    if (Get.isRegistered<AppUpdateController>()) {
      _appUpdateController = Get.find<AppUpdateController>();
    } else {
      if (kDebugMode) print('AppUpdateController not registered yet');
    }

    if (Get.isRegistered<GeneralSettingController>()) {
      _generalSettingController = Get.find<GeneralSettingController>();
    } else {
      if (kDebugMode) print('GeneralSettingController not registered yet');
    }

    if (Get.isRegistered<AppSettingController>()) {
      _appSettingController = Get.find<AppSettingController>();
    } else {
      if (kDebugMode) print('AppSettingController not registered yet');
    }

    try {
      // Optimization: app update info is critical for forced-update UX, so fetch it first
      // with a short timeout. Other settings (general/app) are fetched in background so
      // they don't block splash navigation.
      if (_appUpdateController != null) {
        try {
          await _appUpdateController!.getUpdateData().timeout(const Duration(seconds: 2));
        } catch (e) {
          if (kDebugMode) print('App update fetch timeout or error: $e');
        }
      }

      // Start general & app settings fetch in background (do not await) to avoid blocking
      if (_generalSettingController != null) {
        _generalSettingController!.getGeneralData().catchError((e) {
          if (kDebugMode) print('General setting fetch failed: $e');
        });
      }
      if (_appSettingController != null) {
        _appSettingController!.getAppSettingData().catchError((e) {
          if (kDebugMode) print('App setting fetch failed: $e');
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching initial data: $e');
    }

    // Small delay for splash screen visibility
    await Future.delayed(const Duration(milliseconds: 500));

    // Check for app updates after data is fetched
    // Check update data; _checkForUpdates will use cached data from controller if available.
    bool updateDialogShown = await _checkForUpdates();

    // If force update dialog is shown (blocking) then don't navigate
    if (updateDialogShown) {
      return;
    }

    // Wait for remaining splash screen duration - Removed delay for instant transition
    // await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if onboarding is completed
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // if (!onboardingCompleted) {
    //   // First time user - show onboarding
    //   Get.off(() => const OnBoardingScreen(), transition: Transition.fade);
    //   return;
    // }

    // Proceed to selected protocol / home screen
    await _navigateToSelectedProtocol();
  }

  Future<bool> _checkForUpdates() async {
    try {
      final updateData = (_appUpdateController == null || _appUpdateController!.appUpdateData == null)
          ? null
          : _appUpdateController!.appUpdateData;

      if (updateData == null) return false;

      // Get current app version. PackageInfo not available in this build environment, default to '1.0.0'
      String currentVersion = '1.0.0';

      // Get remote version info
      String remoteVersion = updateData['app_version'] ?? '1.0.0';
      String forceUpdate = updateData['force_update'] ?? '0';
      String popupTitle = updateData['popup_title'] ?? '发现新版本!';
      String popupContent = updateData['popup_content'] ?? '请更新应用以获取新功能!';
      String appUrl = updateData['app_url'] ?? '';

      // Compare versions
      if (_isUpdateRequired(currentVersion, remoteVersion)) {
        if (!mounted) return false;

        bool isForced = forceUpdate == '1';

        await _showUpdateDialog(
          title: popupTitle,
          content: popupContent,
          appUrl: appUrl,
          isForceUpdate: isForced,
        );

        // Return true only if it's a forced update (to block navigation)
        return isForced;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for updates: $e');
      }
      return false;
    }
  }

  bool _isUpdateRequired(String currentVersion, String remoteVersion) {
    try {
      List<int> current = currentVersion.split('.').map(int.parse).toList();
      List<int> remote = remoteVersion.split('.').map(int.parse).toList();

      // Pad with zeros if needed
      while (current.length < 3) {
        current.add(0);
      }
      while (remote.length < 3) {
        remote.add(0);
      }

      // Compare major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (remote[i] > current[i]) return true;
        if (remote[i] < current[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showUpdateDialog({
    required String title,
    required String content,
    required String appUrl,
    required bool isForceUpdate,
  }) async {
    // Use Get.dialog (GetX) to show the same dialog content. Returns when dialog is closed.
    await Get.dialog(
      PopScope(
        canPop: !isForceUpdate,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff2fd9fc), Color(0xFF5FB563)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(content, style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.95), height: 1.4), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (appUrl.isNotEmpty) {
                        final uri = Uri.parse(appUrl);
                        await launchExternalLink(uri);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.download_rounded), SizedBox(width: 8), Text('立即更新')]),
                  ),
                ),
                if (!isForceUpdate) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: Text('稍后再说', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: !isForceUpdate,
    );

    // If user selected Maybe Later (non-forced), continue navigation from caller
  }
  Future<void> _navigateToSelectedProtocol() async {
    Get.off(() => const V2HomeScreen(), transition: Transition.fade);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Subtle pattern background
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: SubtlePatternPainter(),
            ),
            // Animated floating flags
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Stack(
                  children: _flags.map((flag) {
                    return Positioned(
                      left: MediaQuery.of(context).size.width * flag.x,
                      top: MediaQuery.of(context).size.height *
                          (flag.y +
                              math.sin(_floatingController.value *
                                  4 *
                                  math.pi *
                                  flag.speed) *
                                  0.04),
                      child: Opacity(
                        opacity: flag.opacity,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.appPrimaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              flag.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            // Logo with pulse animation
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.05),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.appPrimaryColor.withValues(alpha: 0.3 * _pulseController.value),
                                blurRadius: 40 + (20 * _pulseController.value),
                                spreadRadius: 10 + (10 * _pulseController.value),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            "assets/images/app_logo.png",
                            height: 160,
                            width: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Processing text at bottom
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.appPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '正在处理...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.appPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Country Flag data class
class CountryFlag {
  final String emoji;
  final double x;
  final double y;
  final double speed;
  final double opacity;

  CountryFlag(this.emoji, this.x, this.y, this.speed, this.opacity);
}

// Subtle Pattern Painter for white background
class SubtlePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.appPrimaryColor.withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Add some decorative circles at intersections
    final accentPaint = Paint()
      ..color = AppColors.appPrimaryColor.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          2.0,
          accentPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

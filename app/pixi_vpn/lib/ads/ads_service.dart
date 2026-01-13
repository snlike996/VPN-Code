// ad_helper.dart
import 'package:get/get.dart';
import 'package:pixi_vpn/controller/app_setting_controller.dart';

class AdHelper {

  // Read controller if available
  static AppSettingController? get _ctrl => Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;

  // Whether any admob ad type is enabled (based on controller flags). Falls back to false.
  static bool get isAdmobEnabled {
    final c = _ctrl;
    if (c == null) return false; // fallback: do not show ads when controller not available
    return c.admobBannerEnabled || c.admobNativeEnabled || c.admobInterstitialEnabled || c.admobRewardedEnabled || c.admobOpenEnabled;
  }

  static String get bannerAdUnitId {
    // prefer controller value if present
    final c = _ctrl;
    final idFromController = c?.admobBannerAd;
    if (idFromController != null && idFromController.isNotEmpty) return idFromController;

    // No static fallbacks — return empty so caller can handle lack of id
    return '';
  }

  static String get interstitialAdUnitId {
    final c = _ctrl;
    final idFromController = c?.admobInterstitialAd;
    if (idFromController != null && idFromController.isNotEmpty) return idFromController;

    return '';
  }

  static String get rewardedAdUnitId {
    final c = _ctrl;
    final idFromController = c?.admobRewardedAd;
    if (idFromController != null && idFromController.isNotEmpty) return idFromController;

    return '';
  }

  static String get nativeBannerAdUnitId {
    final c = _ctrl;
    final idFromController = c?.admobNativeAd;
    if (idFromController != null && idFromController.isNotEmpty) return idFromController;

    return '';
  }

  static String get appOpenAdUnitId {
    final c = _ctrl;
    final idFromController = c?.admobOpenAd;
    if (idFromController != null && idFromController.isNotEmpty) return idFromController;

    return '';
  }

}

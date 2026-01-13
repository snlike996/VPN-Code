import 'dart:developer';
import 'package:get/get.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/app_setting_repo.dart';

class AppSettingController extends GetxController {
  final SettingRepo settingRepo;

  AppSettingController({required this.settingRepo});

  @override
  void onInit() {
    super.onInit();
    // Load persisted admob config so UI can use them immediately
    _loadPersistedAdmobConfig();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingAdmob = false;
  bool get isLoadingAdmob => _isLoadingAdmob;

  dynamic appSettingData;
  dynamic admobData;

  // Exposed admob fields for easy access
  String admobAppId = '';
  String admobNativeAd = '';
  bool admobNativeEnabled = false;
  String admobBannerAd = '';
  bool admobBannerEnabled = false;
  String admobOpenAd = '';
  bool admobOpenEnabled = false;
  String admobRewardedAd = '';
  bool admobRewardedEnabled = false;
  String admobInterstitialAd = '';
  bool admobInterstitialEnabled = false;

  Future<void> getAppSettingData() async {
    _isLoading = true;
    update();

    ApiResponse apiResponse = await settingRepo.getAppSettingData();

    _isLoading = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        appSettingData = apiResponse.response!.data;

        // Persist commonly used fields to SharedPreferences for easy access elsewhere
        try {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('rate_app_url', (appSettingData['rate_app_url'] ?? '').toString());
          await prefs.setString('share_app_url', (appSettingData['share_app_url'] ?? '').toString());
          await prefs.setString('more_app_url', (appSettingData['more_app_url'] ?? '').toString());
          await prefs.setString('about_us', (appSettingData['about_us'] ?? '').toString());
          await prefs.setString('terms_conditions', (appSettingData['terms_conditions'] ?? '').toString());
          await prefs.setString('privacy_policy', (appSettingData['privacy_policy'] ?? '').toString());
          await prefs.setString('ads_setting', (appSettingData['ads_setting'] ?? '').toString());

          // also keep raw data for debugging or complex use
          await prefs.setString('app_setting_data_raw', appSettingData.toString());

          // if ads_setting indicates admob, fetch admob config (skip on macOS per requirement)
          final adsSetting = (appSettingData['ads_setting'] ?? '').toString().toLowerCase();
          if (adsSetting == 'admob' && !_isDesktop) {
            getAdmobData();
          } else if (_isDesktop) {
            // Explicitly disable ads on macOS
            admobNativeEnabled = false;
            admobBannerEnabled = false;
            admobOpenEnabled = false;
            admobRewardedEnabled = false;
            admobInterstitialEnabled = false;
            update();
          }
        } catch (e) {
          log('Failed to persist app_setting data to prefs: $e');
        }

      } catch (e) {
        log('Failed to parse: $e');
      }
    } else {
      log('Failed to load data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }

  Future<void> getAdmobData() async {
    _isLoadingAdmob = true;
    update();

    ApiResponse apiResponse = await settingRepo.getAdmobData();

    _isLoadingAdmob = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        admobData = apiResponse.response!.data;

        // Parse fields safely and expose them as typed properties
        try {
          final data = admobData as Map<String, dynamic>;

          admobAppId = (data['admob_app_id'] ?? '').toString();

          admobNativeAd = (data['admob_native_ad'] ?? '').toString();
          admobNativeEnabled = (data['admob_native_enabled'] ?? '0').toString() == '1';

          admobBannerAd = (data['admob_banner_ad'] ?? '').toString();
          admobBannerEnabled = (data['admob_banner_enabled'] ?? '0').toString() == '1';

          admobOpenAd = (data['admob_open_ad'] ?? '').toString();
          admobOpenEnabled = (data['admob_open_enabled'] ?? '0').toString() == '1';

          admobRewardedAd = (data['admob_rewarded_ad'] ?? '').toString();
          admobRewardedEnabled = (data['admob_rewarded_enabled'] ?? '0').toString() == '1';

          admobInterstitialAd = (data['admob_interstitial_ad'] ?? '').toString();
          admobInterstitialEnabled = (data['admob_interstitial_enabled'] ?? '0').toString() == '1';

          // Persist to SharedPreferences for cross-app availability
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('admob_app_id', admobAppId);

          await prefs.setString('admob_native_ad', admobNativeAd);
          await prefs.setBool('admob_native_enabled', admobNativeEnabled);

          await prefs.setString('admob_banner_ad', admobBannerAd);
          await prefs.setBool('admob_banner_enabled', admobBannerEnabled);

          await prefs.setString('admob_open_ad', admobOpenAd);
          await prefs.setBool('admob_open_enabled', admobOpenEnabled);

          await prefs.setString('admob_rewarded_ad', admobRewardedAd);
          await prefs.setBool('admob_rewarded_enabled', admobRewardedEnabled);

          await prefs.setString('admob_interstitial_ad', admobInterstitialAd);
          await prefs.setBool('admob_interstitial_enabled', admobInterstitialEnabled);
        } catch (e) {
          log('Failed to parse admob fields: $e');
        }

      } catch (e) {
        log('Failed to parse: $e');
      }
    } else {
      log('Failed to load data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }

  // Load from SharedPreferences so ad ids & flags are available immediately on app start
  Future<void> _loadPersistedAdmobConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      admobAppId = prefs.getString('admob_app_id') ?? admobAppId;

      admobNativeAd = prefs.getString('admob_native_ad') ?? admobNativeAd;
      admobNativeEnabled = prefs.getBool('admob_native_enabled') ?? admobNativeEnabled;

      admobBannerAd = prefs.getString('admob_banner_ad') ?? admobBannerAd;
      admobBannerEnabled = prefs.getBool('admob_banner_enabled') ?? admobBannerEnabled;

      admobOpenAd = prefs.getString('admob_open_ad') ?? admobOpenAd;
      admobOpenEnabled = prefs.getBool('admob_open_enabled') ?? admobOpenEnabled;

      admobRewardedAd = prefs.getString('admob_rewarded_ad') ?? admobRewardedAd;
      admobRewardedEnabled = prefs.getBool('admob_rewarded_enabled') ?? admobRewardedEnabled;

      admobInterstitialAd = prefs.getString('admob_interstitial_ad') ?? admobInterstitialAd;
      admobInterstitialEnabled = prefs.getBool('admob_interstitial_enabled') ?? admobInterstitialEnabled;

      // Trigger UI update
      update();
    } catch (e) {
      log('Failed to load persisted admob config: $e');
    }
  }

  // Convenience getters
  bool get _isDesktop => GetPlatform.isMacOS;

  bool get isAnyAdEnabled =>
      !_isDesktop &&
      (admobBannerEnabled ||
          admobNativeEnabled ||
          admobInterstitialEnabled ||
          admobRewardedEnabled ||
          admobOpenEnabled);

  bool get shouldShowBanner => isAnyAdEnabled && admobBannerEnabled && admobBannerAd.isNotEmpty;
  bool get shouldShowNative => isAnyAdEnabled && admobNativeEnabled && admobNativeAd.isNotEmpty;
  bool get shouldShowInterstitial => isAnyAdEnabled && admobInterstitialEnabled && admobInterstitialAd.isNotEmpty;
  bool get shouldShowRewarded => isAnyAdEnabled && admobRewardedEnabled && admobRewardedAd.isNotEmpty;
  bool get shouldShowAppOpen => isAnyAdEnabled && admobOpenEnabled && admobOpenAd.isNotEmpty;
}

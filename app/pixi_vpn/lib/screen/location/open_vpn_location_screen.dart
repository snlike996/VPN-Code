import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pixi_vpn/screen/home/open_vpn_home_screen.dart';
import 'package:pixi_vpn/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../ads/ads_service.dart';
import '../../controller/open_vpn_controller.dart';
import '../../controller/auth_controller.dart';
import '../../controller/profile_controller.dart';
import '../../controller/app_setting_controller.dart';
import '../auth/signin_screen.dart';
import '../in_app_purchase/in_app_purchase_screen.dart';

class OpenVpnLocationScreen extends StatefulWidget {
  const OpenVpnLocationScreen({super.key});

  @override
  State<OpenVpnLocationScreen> createState() => _OpenVpnLocationScreenState();
}

class _OpenVpnLocationScreenState extends State<OpenVpnLocationScreen> {

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  void _createInterstitialAd() {
    final unitId = AdHelper.interstitialAdUnitId;
    if (unitId.isEmpty) return;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) return;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); _createInterstitialAd(); },
      onAdFailedToShowFullScreenContent: (ad, err) { ad.dispose(); _createInterstitialAd(); },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void _createRewardedAd() {
    final unitId = AdHelper.rewardedAdUnitId;
    if (unitId.isEmpty) return;
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) { _rewardedAd = ad; _numRewardedLoadAttempts = 0; },
        onAdFailedToLoad: (err) { _rewardedAd = null; _numRewardedLoadAttempts++; if (_numRewardedLoadAttempts < 3) _createRewardedAd(); },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) return;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); _createRewardedAd(); },
      onAdFailedToShowFullScreenContent: (ad, err) { ad.dispose(); _createRewardedAd(); },
    );
    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) { /* handle reward */ });
    _rewardedAd = null;
  }

  Future<void> saveOpenVpnServerData(
      dynamic serverId,
      String serverName,
      String username,
      String password,
      String config,
      String isPremium,
      String countryCode,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Encode each string to Base64
    String encodeBase64(String input) => base64Encode(utf8.encode(input));

    prefs.setInt('id', serverId);
    prefs.setString('name_O', encodeBase64(serverName));
    prefs.setString('username_O', encodeBase64(username));
    prefs.setString('password_O', encodeBase64(password));
    prefs.setString('link_O', encodeBase64(config));
    prefs.setString('isPremium_O', encodeBase64(isPremium));
    prefs.setString('country_code_O', encodeBase64(countryCode));
  }

  void checkAuthAndFetchProfile() async {
    String token = await Get.find<AuthController>().getAuthToken();
    if (token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<ProfileController>().getProfileData().then((value) {
          if (value == 200) {
            final profile = Get.find<ProfileController>().profileData;

            final isPremium = profile["isPremium"].toString() == "1";

            // Parse expired_date into DateTime
            final expiredDate = DateTime.tryParse(profile["expired_date"].toString());

            // Get today's date/time
            final now = DateTime.now();

            if (isPremium && expiredDate != null && expiredDate.isAfter(now)) {
              log("Premium valid until: $expiredDate");
            } else {
              //Either not premium or expired
              if(isPremium){
                Get.find<ProfileController>().cancelSubscriptionData();
              }
              log("Premium expired or not active");
            }

            log("log data>>>$profile");
          }
        });
      });
    }
  }


  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
      if (appCtrl != null) {
        if (appCtrl.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) _createInterstitialAd();
        if (appCtrl.shouldShowRewarded && AdHelper.rewardedAdUnitId.isNotEmpty) _createRewardedAd();
      }

      Get.find<OpenVpnController>().getOpenVpnData();
    });
    checkAuthAndFetchProfile();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return GetBuilder<OpenVpnController>(builder: (openVpnController) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          title: Text(
            'VPN 位置',
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.white, Colors.white, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    style: GoogleFonts.poppins(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: '搜索位置...',
                      hintStyle: GoogleFonts.roboto(fontSize: 16, color: Colors.black.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, color: Colors.black), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }))
                          : null,
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),

                Expanded(
                  child: GetBuilder<OpenVpnController>(builder: (ctrl) {
                    final isLoading = ctrl.isLoadingOpenVpn;
                    final vpnServers = ctrl.vpnServers;

                    if (isLoading) {
                      return Center(child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2));
                    }

                    return FutureBuilder<String>(
                      future: Future.value(Get.find<AuthController>().getAuthToken()),
                      builder: (context, snapshot) {
                        final token = snapshot.data ?? '';
                        final isLoggedIn = token.isNotEmpty;

                        // Sort servers: free first
                        final sorted = List.from(vpnServers);
                        sorted.sort((a, b) { if (a.isPremium == b.isPremium) return 0; return a.isPremium ? 1 : -1; });

                        // Filter by search
                        final filtered = _searchQuery.isEmpty
                            ? sorted
                            : sorted.where((s) => s.name.toLowerCase().contains(_searchQuery) || s.cityName.toLowerCase().contains(_searchQuery) || s.countryCode.toLowerCase().contains(_searchQuery)).toList();

                        if (filtered.isEmpty) {
                          return Center(child: Text(_searchQuery.isEmpty ? '未找到服务器' : '未找到匹配的服务器', style: GoogleFonts.poppins(color: Colors.black)));
                        }

                        return GetBuilder<ProfileController>(builder: (profileController) {
                          final profileData = profileController.profileData;
                          bool isPremiumUser = false;
                          if (profileData != null) {
                            final isPremium = profileData["isPremium"].toString() == "1";
                            final expiredDate = DateTime.tryParse(profileData["expired_date"].toString());
                            final now = DateTime.now();
                            if (isPremium && expiredDate != null && expiredDate.isAfter(now)) {
                              isPremiumUser = true;
                            }
                          }
                          return ListView.builder(
                            itemCount: filtered.length,
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final countryCode = item.countryCode.toLowerCase();
                              final isLocked = item.isPremium && (!isLoggedIn || !isPremiumUser);
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: GestureDetector(
                                  onTap: () async {
                                    if (item.isPremium) {
                                      if (!isLoggedIn) {
                                        Get.to(() => SignInScreen(), transition: Transition.fadeIn);
                                        return;
                                      }
                                      if (isPremiumUser) {
                                        // Premium user - allow connection
                                        saveOpenVpnServerData(item.id, item.name, item.username ?? '', item.password ?? '', item.config ?? '', item.isPremium.toString(), countryCode);
                                        final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
                                        if (appCtrl != null && appCtrl.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) {
                                          _showInterstitialAd();
                                        }
                                        Fluttertoast.showToast(msg: '服务器已保存', backgroundColor: Colors.green, textColor: Colors.white);
                                        Get.offAll(() => OpenVpnHomeScreen(), transition: Transition.fadeIn);
                                      } else {
                                        // Not premium or expired - show dialog
                                        Get.dialog(
                                          Dialog(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            child: Container(
                                              padding: const EdgeInsets.all(22),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))],
                                              ),
                                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                                Container(
                                                  padding: const EdgeInsets.all(14),
                                                  decoration: BoxDecoration(color: AppColors.appPrimaryColor, shape: BoxShape.circle),
                                                  child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 28),
                                                ),
                                                const SizedBox(height: 16),
                                                Text('高级服务器', style: GoogleFonts.poppins(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                                                const SizedBox(height: 8),
                                                Text('填写支付宝口令红包开通高级会员，获得无限制的安全访问。', style: GoogleFonts.poppins(color: Colors.black.withValues(alpha: 0.72), fontSize: 14, height: 1.4), textAlign: TextAlign.center),
                                                const SizedBox(height: 20),
                                                Column(children: [
                                                  const SizedBox(height: 14),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        Get.back();
                                                        Get.to(() => InAppPurchaseScreen(), transition: Transition.rightToLeftWithFade);
                                                      },
                                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                                      child: Text('填写口令红包', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                                                    ),
                                                  ),
                                                ]),
                                                const SizedBox(height: 6),
                                              ]),
                                            ),
                                          ),
                                          barrierColor: Colors.black.withValues(alpha: 0.4),
                                          barrierDismissible: true,
                                        );
                                      }
                                    } else {
                                      // Free server - allow connection
                                      saveOpenVpnServerData(item.id, item.name, item.username ?? '', item.password ?? '', item.config ?? '', item.isPremium.toString(), countryCode);
                                      final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
                                      if (appCtrl != null && appCtrl.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) {
                                        _showInterstitialAd();
                                      }
                                      Fluttertoast.showToast(msg: '服务器已保存', backgroundColor: Colors.green, textColor: Colors.white);
                                      Get.offAll(() => OpenVpnHomeScreen(), transition: Transition.fadeIn);
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: ClipOval(child: Image.asset('assets/flags/$countryCode.png', height: 32, width: 32, fit: BoxFit.cover)),
                                      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(item.name, style: GoogleFonts.poppins(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(item.cityName, style: GoogleFonts.poppins(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400)),
                                      ]),
                                      trailing: isLocked
                                          ? Image.asset('assets/images/crown.png', height: 30, width: 30)
                                          : const Icon(Icons.chevron_right, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        });
                      },
                    );
                  }),
                ),

              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    try { _searchController.dispose(); } catch (_) {}
    try { _interstitialAd?.dispose(); } catch (_) {}
    try { _rewardedAd?.dispose(); } catch (_) {}
    super.dispose();
  }
}

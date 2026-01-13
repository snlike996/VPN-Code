import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../ads/ads_service.dart';
import '../../controller/wireguard_vpn_controller.dart';
import '../../controller/auth_controller.dart';
import '../../controller/profile_controller.dart';
import '../../controller/app_setting_controller.dart';
import '../home/wg_home_screen.dart';
import '../auth/signin_screen.dart';
import '../in_app_purchase/in_app_purchase_screen.dart';
import 'package:pixi_vpn/utils/app_colors.dart';

class WgLocationScreen extends StatefulWidget {
  const WgLocationScreen({super.key});

  @override
  State<WgLocationScreen> createState() => _WgLocationScreenState();
}

class _WgLocationScreenState extends State<WgLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

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

  Future<void> saveWireGuardServerData(
      dynamic serverId,
      String serverName,
      String serverAddress,
      String config,
      String isPremium,
      String countryCode,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Encode each string to Base64
    String encodeBase64(String input) => base64Encode(utf8.encode(input));
    prefs.setInt('id', serverId);
    prefs.setString('name_w', encodeBase64(serverName));
    prefs.setString('address_w', encodeBase64(serverAddress));
    prefs.setString('link_w', encodeBase64(config));
    prefs.setString('isPremium_w', encodeBase64(isPremium));
    prefs.setString('country_code_w', encodeBase64(countryCode));
  }

  void _createInterstitialAd() {
    final unitId = AdHelper.interstitialAdUnitId;
    if (unitId.isEmpty) return;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) { _interstitialAd = ad; _interstitialAd!.setImmersiveMode(true); },
        onAdFailedToLoad: (err) { _interstitialAd = null; },
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
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) { /* reward */ });
    _rewardedAd = null;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
      if (appCtrl != null) {
        if (appCtrl.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) _createInterstitialAd();
        if (appCtrl.shouldShowRewarded && AdHelper.rewardedAdUnitId.isNotEmpty) _createRewardedAd();
      }

      Get.find<WireGuardVpnController>().getWireGuardVpnData();
    });
    checkAuthAndFetchProfile();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return GetBuilder<WireGuardVpnController>(
        builder: (wireGuardVpnController) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () { Get.back(); },
                            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "VPN 位置",
                            style: GoogleFonts.aBeeZee(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          hintText: "搜索服务器...",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Colors.black, size: 20),
                        ),
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
                      ),
                    ),

                    const SizedBox(height: 8),


                    Expanded(
                      child: GetBuilder<WireGuardVpnController>(
                        builder: (wireGuardVpnController) {
                          final isLoading = wireGuardVpnController.isLoadingWireGuardVpn;
                          final vpnServers = wireGuardVpnController.vpnServers;

                          if (isLoading) return Center(child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2));

                          return FutureBuilder<String>(
                            future: Future.value(Get.find<AuthController>().getAuthToken()),
                            builder: (context, snapshot) {
                              final token = snapshot.data ?? '';
                              final isLoggedIn = token.isNotEmpty;

                              // Sort servers: free servers first, then premium servers
                              final sortedServers = List.from(vpnServers);
                              sortedServers.sort((a, b) {
                                if (a.isPremium == b.isPremium) return 0;
                                return a.isPremium ? 1 : -1; // false (free) comes before true (premium)
                              });

                              // Filter servers based on search query
                              final filteredServers = _searchQuery.isEmpty
                                  ? sortedServers
                                  : sortedServers.where((server) {
                                      return server.name.toLowerCase().contains(_searchQuery) ||
                                             server.cityName.toLowerCase().contains(_searchQuery) ||
                                             server.countryCode.toLowerCase().contains(_searchQuery);
                                    }).toList();

                              if (filteredServers.isEmpty) {
                                return Center(
                                  child: Text(
                                    _searchQuery.isEmpty ? "未找到服务器" : "未找到匹配的服务器",
                                    style: GoogleFonts.poppins(color: Colors.black),
                                  ),
                                );
                              }

                              // In build, before ListView.builder, update premium logic:
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
                                  itemCount: filteredServers.length,
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final item = filteredServers[index];
                                    final countryCode = item.countryCode.toLowerCase();
                                    final isLocked = item.isPremium && (!isLoggedIn || !isPremiumUser);

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      child: GestureDetector(
                                        onTap: () async {
                                          // Check if user is logged in first (required for both free and premium)
                                          if (!isLoggedIn) {
                                            Fluttertoast.showToast(
                                              msg: '请先登录以选择服务器',
                                              backgroundColor: Colors.orange,
                                              textColor: Colors.white,
                                            );
                                            Get.to(() => SignInScreen(), transition: Transition.fadeIn);
                                            return;
                                          }

                                          // User is logged in, now check if server is premium
                                          if (item.isPremium) {
                                            final isPremiumUser = profileData != null && (profileData['isPremium'] == 1 || profileData['isPremium'] == '1');
                                            if (isPremiumUser) {
                                              // Premium user - allow connection to premium server
                                              saveWireGuardServerData(
                                                item.id,
                                                item.name,
                                                item.address ?? '',
                                                item.config ?? '',
                                                item.isPremium.toString(),
                                                countryCode,
                                              );
                                              final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
                                              if (appCtrl != null && appCtrl.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) {
                                                _showInterstitialAd();
                                              }
                                              Fluttertoast.showToast(msg: '服务器已保存', backgroundColor: Colors.green, textColor: Colors.white);
                                              Get.offAll(() => WGHomeScreen(), transition: Transition.fadeIn);
                                            } else {
                                              // Not premium user - show upgrade dialog
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
                                                      Text('观看广告以连接我们的高级服务器，或升级为高级会员以获得无限制的安全访问。', style: GoogleFonts.poppins(color: Colors.black.withValues(alpha: 0.72), fontSize: 14, height: 1.4), textAlign: TextAlign.center),
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
                                                            child: Text('购买高级版', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
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
                                            // Free server - logged in user can connect
                                            saveWireGuardServerData(
                                              item.id,
                                              item.name,
                                              item.address ?? '',
                                              item.config ?? '',
                                              item.isPremium.toString(),
                                              countryCode,
                                            );
                                            final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
                                            if (appCtrl != null && appCtrl.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) {
                                              _showInterstitialAd();
                                            }
                                            Fluttertoast.showToast(msg: '服务器已保存', backgroundColor: Colors.green, textColor: Colors.white);
                                            Get.offAll(() => WGHomeScreen(), transition: Transition.fadeIn);
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white, // keep card white on white scaffold but with subtle border
                                            border: Border.all(
                                              color: Colors.black.withValues(alpha: 0.06),
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            leading: ClipOval(
                                              child: Image.asset(
                                                'assets/flags/$countryCode.png',
                                                height: 32,
                                                width: 32,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            title: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.cityName,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.black54,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                        },
                      ),
                    ),


                  ],
                ),
              ),
            ),
          );
        }
    );
  }

}


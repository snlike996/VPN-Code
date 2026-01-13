import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pixi_vpn/controller/v2ray_vpn_controller.dart';
import 'package:pixi_vpn/screen/auth/signin_screen.dart';
import 'package:pixi_vpn/screen/home/v2_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixi_vpn/utils/app_colors.dart';
import '../../ads/ads_service.dart';
import '../../controller/auth_controller.dart';
import '../../controller/profile_controller.dart';
import '../../controller/app_setting_controller.dart';
import '../in_app_purchase/in_app_purchase_screen.dart';

class V2LocationScreen extends StatefulWidget {
  const V2LocationScreen({super.key});

  @override
  State<V2LocationScreen> createState() => _V2LocationScreenState();
}

class _V2LocationScreenState extends State<V2LocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> saveV2rayServerData(
      dynamic serverId,
      String serverName,
      String config,
      String isPremium,
      String countryCode,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Encode each string to Base64
    String encodeBase64(String input) => base64Encode(utf8.encode(input));

    prefs.setInt('id', serverId);
    prefs.setString('name_v', encodeBase64(serverName));
    prefs.setString('link_v', encodeBase64(config));
    prefs.setString('isPremium_v', encodeBase64(isPremium));
    prefs.setString('country_code_v', encodeBase64(countryCode));
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

  InterstitialAd? _interstitialAd;

  @override
  void dispose() {
    _searchController.dispose();
    // dispose ads if created
    try { _interstitialAd?.dispose(); } catch (_) {}
    try { _rewardedAd?.dispose(); } catch (_) {}
    super.dispose();
  }

  void _createInterstitialAd() {
    final unitId = AdHelper.interstitialAdUnitId;
    if (unitId.isEmpty || kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      if (kDebugMode) print('Interstitial ad skipped (unsupported platform or missing ID)');
      return;
    }
    InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            if (kDebugMode) {
              print('$ad loaded');
            }
            _interstitialAd = ad;
            _interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (kDebugMode) {
              print('InterstitialAd failed to load: $error.');
            }
            _interstitialAd = null;
          },
        ));
  }
  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      log('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          log('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        log('\$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        log('\$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  void _createRewardedAd() {
    final unitId = AdHelper.rewardedAdUnitId;
    if (unitId.isEmpty || kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      if (kDebugMode) print('Rewarded ad skipped (unsupported platform or missing ID)');
      return;
    }
    RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            log('\$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            log('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < 3) {
              _createRewardedAd();
            }
          },
        ));
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      log('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          log('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        log('\$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        log('\$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          log('\$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
        });
    _rewardedAd = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load ads only if enabled in AppSettingController and IDs are present
      final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
      if (appCtrl != null) {
        if (appCtrl.shouldShowRewarded && AdHelper.rewardedAdUnitId.isNotEmpty) {
          _createRewardedAd();
        }
        if (appCtrl.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) {
          _createInterstitialAd();
        }
      }

      Get.find<V2rayVpnController>().getV2rayVpnData();
      checkAuthAndFetchProfile();
    });
  }


  @override
  Widget build(BuildContext context) {
    return GetBuilder<V2rayVpnController>(
        builder: (v2rayVpnController) {
          return GetBuilder<ProfileController>(
            builder: (profileController) {
              return Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  centerTitle: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  leading:  IconButton(
                    onPressed: () { Get.back(); },
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                  ),
                  title: Text(
                    "VPN 位置",
                    style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                ),

                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.white
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Search Field
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            style: GoogleFonts.poppins(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: '搜索位置...',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                              prefixIcon: const Icon(Icons.search, color: Colors.black),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.black),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.03),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: GetBuilder<V2rayVpnController>(
                            builder: (v2rayVpnController) {
                              final isLoading = v2rayVpnController.isLoadingV2rayVpn;
                              final vpnServers = v2rayVpnController.vpnServers;

                              if (isLoading) {
                                return Center(
                                  child: CircularProgressIndicator(color: AppColors.appPrimaryColor,
                                    strokeWidth: 2,),
                                );
                              }

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

                                  return ListView.builder(
                                    itemCount: filteredServers.length,
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final item = filteredServers[index];
                                      final countryCode = item.countryCode.toLowerCase();
                                      final profileData = profileController.profileData;
                                      final isPremiumUser = profileData != null && profileData["isPremium"] == 1;
                                      final isLocked = item.isPremium && (!isLoggedIn || !isPremiumUser);

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (item.isPremium) {
                                              // Check if user is logged in
                                              if (token.isEmpty) {
                                                // Not logged in - navigate to login screen
                                                Get.to(() => SignInScreen(), transition: Transition.fadeIn);
                                              } else {
                                                // Logged in - check if premium
                                                final profileData = profileController.profileData;
                                                final isPremiumUser = profileData != null && profileData["isPremium"] == 1;
                                                if (isPremiumUser) {
                                                  // Premium user - allow connection
                                                  saveV2rayServerData(
                                                    item.id,
                                                    item.name,
                                                    item.config,
                                                    item.isPremium.toString(),
                                                    countryCode,
                                                  );
                                                  // show interstitial only if enabled
                                                  final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
                                                  if (appCtrl != null && appCtrl.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) {
                                                    _showInterstitialAd();
                                                  }
                                                  Get.snackbar("提示", '服务器已保存', backgroundColor: Colors.green, colorText: Colors.white);
                                                  // Return to previous screen without forcing selection
                                                  Get.offAll(()=> V2HomeScreen(),transition: Transition.leftToRight);
                                                } else {
                                                  // Logged in but not premium - show in-app purchase
                                                  Get.dialog(
                                                    Dialog(
                                                      backgroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(22),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(20),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withValues(alpha: 0.06),
                                                              blurRadius: 12,
                                                              offset: const Offset(0, 6),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            // ---- ICON ----
                                                            Container(
                                                              padding: const EdgeInsets.all(14),
                                                              decoration: BoxDecoration(
                                                                color: AppColors.appPrimaryColor,
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: const Icon(
                                                                Icons.lock_outline_rounded,
                                                                color: Colors.white,
                                                                size: 28,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 16),

                                                            // ---- TITLE ----
                                                            Text(
                                                              "高级服务器",
                                                              style: GoogleFonts.poppins(
                                                                color: Colors.black,
                                                                fontSize: 20,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                            const SizedBox(height: 8),

                                                            // ---- DESCRIPTION ----
                                                            Text(
                                                              "观看广告以连接我们的高级服务器，或升级为高级会员以获得无限制的安全访问。",
                                                              style: GoogleFonts.poppins(
                                                                color: Colors.black.withValues(alpha: 0.72),
                                                                fontSize: 14,
                                                                height: 1.4,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                            const SizedBox(height: 20),

                                                            // ---- BUTTONS ----
                                                            Column(
                                                              children: [

                                                                // Buy Premium Button (Gold Highlight)
                                                                SizedBox(
                                                                  width: double.infinity,
                                                                  child: ElevatedButton(
                                                                    onPressed: () {
                                                                      Get.back();
                                                                      // Navigate to In-App Purchase
                                                                      Get.to(() => InAppPurchaseScreen(),
                                                                          transition: Transition.rightToLeftWithFade);
                                                                    },
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: const Color(0xFFFFC107), // Gold color
                                                                      foregroundColor: Colors.black,
                                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(14),
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      "购买高级版",
                                                                      style: GoogleFonts.poppins(
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.w500,
                                                                        color: Colors.black,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),

                                                            const SizedBox(height: 6),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    barrierColor: Colors.black.withValues(alpha: 0.4),
                                                    barrierDismissible: true,
                                                  );

                                                }
                                              }
                                            } else {
                                              // Free server - allow connection
                                              saveV2rayServerData(
                                                item.id,
                                                item.name,
                                                item.config,
                                                item.isPremium.toString(),
                                                countryCode,
                                              );
                                              final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
                                              if (appCtrl != null && appCtrl.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) {
                                                _showInterstitialAd();
                                              }
                                              Get.snackbar("提示", '服务器已保存', backgroundColor: Colors.green, colorText: Colors.white);
                                              // Return to previous screen without forcing selection
                                              Get.offAll(()=> V2HomeScreen(),transition: Transition.leftToRight);
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
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
                                              leading: ClipOval(
                                                child: Image.asset(
                                                  "assets/flags/$countryCode.png",
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
                                                  Text(
                                                    item.cityName,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black54,
                                                      fontSize: 15,
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
            },
          );
        }
    );
  }


}

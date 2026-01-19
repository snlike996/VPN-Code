import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pixi_vpn/controller/v2ray_vpn_controller.dart';
import 'package:pixi_vpn/model/country_item.dart';
import 'package:pixi_vpn/ui/shared/auth/signin_screen.dart';
import 'package:pixi_vpn/utils/app_colors.dart';
import '../../ads/ads_service.dart';
import '../../controller/auth_controller.dart';
import '../../controller/app_setting_controller.dart';
import 'v2_nodes_screen.dart';

class V2LocationScreen extends StatefulWidget {
  const V2LocationScreen({super.key});

  @override
  State<V2LocationScreen> createState() => _V2LocationScreenState();
}

class _V2LocationScreenState extends State<V2LocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';


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

      Get.find<V2rayVpnController>().getCountries();
    });
  }


  @override
  Widget build(BuildContext context) {
    return GetBuilder<V2rayVpnController>(
        builder: (v2rayVpnController) {
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
                              final isLoading = v2rayVpnController.isLoadingCountries;
                              final countries = v2rayVpnController.countries;

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

                                  if (v2rayVpnController.countriesError != null) {
                                    return Center(
                                      child: Text(
                                        v2rayVpnController.countriesError!,
                                        style: GoogleFonts.poppins(color: Colors.black54),
                                      ),
                                    );
                                  }

                                  final sortedCountries = List<CountryItem>.from(countries);
                                  sortedCountries.sort((a, b) => a.name
                                      .toLowerCase()
                                      .compareTo(b.name.toLowerCase()));

                                  final filteredCountries = _searchQuery.isEmpty
                                      ? sortedCountries
                                      : sortedCountries.where((country) {
                                          final haystack = [
                                            country.name,
                                            country.code,
                                          ].join(' ').toLowerCase();
                                          return haystack.contains(_searchQuery);
                                        }).toList();

                                  if (filteredCountries.isEmpty) {
                                    return Center(
                                      child: Text(
                                        _searchQuery.isEmpty ? "未找到国家" : "未找到匹配的国家",
                                        style: GoogleFonts.poppins(color: Colors.black),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: filteredCountries.length,
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final item = filteredCountries[index];

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!isLoggedIn) {
                                              Get.to(() => SignInScreen(), transition: Transition.fadeIn);
                                              return;
                                            }

                                            final appCtrl = Get.isRegistered<AppSettingController>()
                                                ? Get.find<AppSettingController>()
                                                : null;
                                            if (appCtrl != null &&
                                                appCtrl.shouldShowInterstitial &&
                                                AdHelper.interstitialAdUnitId.isNotEmpty) {
                                              _showInterstitialAd();
                                            }

                                            Get.to(() => V2NodesScreen(country: item),
                                                transition: Transition.rightToLeft);
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
                                                  "assets/flags/${item.code}.png",
                                                  height: 32,
                                                  width: 32,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => CircleAvatar(
                                                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                                                    child: const Icon(Icons.public, color: Colors.black87, size: 18),
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                item.name,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                item.code.toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black54,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                                ],
                                              ),
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
        }
    );
  }

}

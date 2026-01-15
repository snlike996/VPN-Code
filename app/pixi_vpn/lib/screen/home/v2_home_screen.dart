import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pixi_vpn/screen/location/v2_location_screen.dart';
import 'package:pixi_vpn/screen/setting/live_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixi_vpn/utils/link_launcher.dart';
import '../../ads/ads_service.dart';
import '../../controller/active_server_controller.dart';
import '../../controller/app_setting_controller.dart';
import '../../controller/contact_controller.dart';
import '../../controller/v2ray_vpn_controller.dart';
import '../profile/profile_screen.dart';
import '../setting/dynamic_content_screen.dart';
import '../setting/help_center_screen.dart';
import '../setting/select_protocol_screen.dart';

enum VPNStatus { disconnected, connecting, connected, disconnecting }

class V2HomeScreen extends StatefulWidget {
  const V2HomeScreen({super.key});

  @override
  State<V2HomeScreen> createState() => _VPNHomePageState();
}

class _VPNHomePageState extends State<V2HomeScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _waveController;

// State variables
  String serverName = '';

  dynamic config;
  dynamic id;
  dynamic isPremium;
  String? countryCode;
  bool isConnect = false;
  bool isProcessing = false;

  // Network ping
  double? pingMs;
  bool loading = false;

  // Selected location
  String _selectedCountry = '选择位置';
  String _selectedFlag = '🌍';

  // Quick connect servers (not currently displayed) - removed unused field to silence warnings

  // ValueNotifier that holds the current V2Ray status (single source of truth)
  final ValueNotifier<V2RayStatus> v2rayStatus = ValueNotifier<V2RayStatus>(V2RayStatus());

  // V2Ray instance (initialized in initState)
  late V2ray v2ray;

  //ads

  InterstitialAd? _interstitialAd;

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  void _createInterstitialAd() {
    final unitId = AdHelper.interstitialAdUnitId;
    if (unitId.isEmpty) {
      if (kDebugMode) print('Interstitial ad unit id missing - skipping load');
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
        log('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        log('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void _loadBannerAd() {
    final unitId = AdHelper.bannerAdUnitId;
    if (unitId.isEmpty) {
      if (kDebugMode) print('Banner ad unit id missing - skipping banner load');
      _isBannerAdReady = false;
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: unitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  NativeAd? _nativeAd;
  //bool _isAdLoaded = false;

  void _loadAd() {
    final unitId = AdHelper.nativeBannerAdUnitId;
    if (unitId.isEmpty) {
      if (kDebugMode) print('Native ad unit id missing - skipping native ad load');
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: unitId,
      request: const AdRequest(),
      // No factoryId needed when using templates
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            //_isAdLoaded = true;
          });
          log('Native ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          log('Failed to load native ad: $error');
        },
      ),
    )..load();
  }

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  void _createRewardedAd() {
    final unitId = AdHelper.rewardedAdUnitId;
    if (unitId.isEmpty) {
      if (kDebugMode) print('Rewarded ad unit id missing - skipping rewarded load');
      return;
    }
    RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            log('$ad loaded.');
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
        log('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        log('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          log('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
        });
    _rewardedAd = null;
  }

  @override
  void initState() {
    super.initState();

    // Initialize V2Ray and listen for status changes
    v2ray = V2ray(
      onStatusChanged: (status) {
        if (kDebugMode) {
          print('V2Ray status changed: ${status.state}');
        }

        // update the ValueNotifier so UI rebuilds via ValueListenableBuilder
        v2rayStatus.value = status;

        // Keep a simple local flag for any non-UI logic (not used by UI rendering)
        setState(() {
          isConnect = status.state == 'CONNECTED';
        });
      },
    );

    // Initialize native service
    v2ray.initialize(
      notificationIconResourceType: "drawable",
      notificationIconResourceName: "ic_notification",
    );

    _initializeApp();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Only initialize ads if AppSettingController indicates admob is enabled
    AppSettingController? appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;

    // Native (small) ad
    if (appCtrl != null && appCtrl.shouldShowNative) {
      _loadAd();
    }

    // Rewarded
    if (appCtrl != null && appCtrl.shouldShowRewarded) {
      _createRewardedAd();
    }

    // Banner
    if (appCtrl != null && appCtrl.shouldShowBanner) {
      _loadBannerAd();
    }

    // Interstitial
    if (appCtrl != null && appCtrl.shouldShowInterstitial) {
      _createInterstitialAd();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    v2rayStatus.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      final controller = Get.find<V2rayVpnController>();

      // Load config from SharedPreferences
      await _loadConfigData();

      // If no config or server name is loaded, just fetch server list and do not auto-select.
      if (config.isEmpty || serverName.isEmpty) {
        if (kDebugMode) {
          print('No server selected. Fetching server list...');
        }

        // Fetch server list from API; do NOT auto-save or auto-select any server.
        await controller.getV2rayVpnData();

        // If no servers available, inform the user.
        if (controller.vpnServers.isEmpty) {
          Fluttertoast.showToast(
            msg: "暂无可用VPN服务器",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 12.0,
          );
        }
      } else {
        if (kDebugMode) {
          print('Server already selected: $serverName');
        }

        // Still fetch servers for quick connect list (we don't store them locally)
        await controller.getV2rayVpnData();
      }

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error during app initialization: $e');
      }
    }
  }

  Future<void> _loadConfigData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      id = prefs.getInt('id');
      serverName = _decodeBase64(prefs.getString('name_v'));
      config = _decodeBase64(prefs.getString('link_v'));
      isPremium = _decodeBase64(prefs.getString('isPremium_v'));
      countryCode = _decodeBase64(prefs.getString('country_code_v'));

      // Update selected country and flag
      if (serverName.isNotEmpty) {
        _selectedCountry = serverName;
        _selectedFlag = _getFlagEmoji(countryCode ?? '');
      }

      if (kDebugMode) {
        print('Loaded id: $id');
        print('Loaded server: $serverName');
        print('Config: $config');
        print('Config length: ${config?.length ?? 0}');
      }

      // If any required data is missing, don't validate yet
      if (serverName.isEmpty || config == null || config.toString().isEmpty) {
        if (kDebugMode) {
          print('Missing server data. Will fetch from API...');
        }
        return;
      }

      // Validate V2Ray config format (should contain vmess://, vless://, ss://, trojan://, etc.)
      final validProtocols = ['vmess://', 'vless://', 'ss://', 'trojan://', 'socks://', 'http://'];
      final configStr = config.toString().trim();
      final isValidConfig = validProtocols.any((protocol) => configStr.toLowerCase().startsWith(protocol));

      if (!isValidConfig) {
        if (kDebugMode) {
          print('Invalid V2Ray config format: $configStr');
        }
        config = '';
        serverName = '';
      } else {
        if (kDebugMode) {
          print('Valid V2Ray config detected');
        }
      }

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error loading server data: $e');
      }
    }
  }

  String _decodeBase64(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      return utf8.decode(base64.decode(value));
    } catch (_) {
      return '';
    }
  }


  String _getFlagEmoji(String countryCode) {
    if (countryCode.isEmpty) return '🌍';

    // Convert country code to flag emoji
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '🌍';

    return String.fromCharCode(code.codeUnitAt(0) + 127397) +
        String.fromCharCode(code.codeUnitAt(1) + 127397);
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _advancedDrawerController = AdvancedDrawerController();

  Widget contactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            Get.snackbar(
              "已复制",
              "$label 已复制到剪贴板",
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedDrawer(
      backdrop: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white],
          ),
        ),
      ),
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      openRatio: 0.65,
      // openScale: 1.0,
      disabledGestures: false,
      childDecoration: const BoxDecoration(
        borderRadius:  BorderRadius.all(Radius.circular(16)),),
      drawer: Drawer(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[

              SizedBox(height: 80,),

              ListTile(
                leading: Icon(Icons.vpn_key),
                title: Text('选择协议'),
                onTap: () {
                  Get.to(()=> SelectProtocolScreen(),transition: Transition.fadeIn);
                },
              ),

              ListTile(
                leading: Icon(Icons.chat),
                title: Text('在线客服'),
                onTap: () {
                  Get.to(()=> LiveChatScreen(),transition: Transition.fadeIn);
                },
              ),

              ListTile(
                leading: const Icon(Icons.call),
                title: const Text('联系我们'),
                onTap: () {
                  final controller = Get.find<ContactController>();
                  controller.getContactData();

                  Get.dialog(
                    GetBuilder<ContactController>(
                      builder: (contactController) {
                        if (controller.isLoading) {
                          return const AlertDialog(
                            content: SizedBox(
                              height: 80,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        final contact = controller.appContactData;
                        if (contact == null) {
                          return const AlertDialog(
                            content: Text("暂无联系方式"),
                          );
                        }

                        return AlertDialog(
                          title:  Text("联系我们",style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              contactItem(
                                icon: Icons.telegram,
                                label: "Telegram",
                                value: '${contact["telegram_username"]}',
                              ),
                              const SizedBox(height: 12),
                              contactItem(
                                icon: Icons.email,
                                label: "Email",
                                value: '${contact["contact_email"]}',
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text("关闭"),
                            ),
                          ],
                        );
                      },
                    ),
                    barrierDismissible: true,
                  );
                },
              ),

              ListTile(
                leading: Icon(Icons.help),
                title: Text('帮助中心'),
                onTap: () {
                  Get.to(()=> HelpCenterScreen(),transition: Transition.fadeIn);
                },
              ),

              ListTile(
                leading: Icon(Icons.policy),
                title: Text('隐私政策'),
                onTap: () {
                  Get.to(() => const DynamicContentScreen(title: '隐私政策', prefKey: 'privacy_policy'), transition: Transition.rightToLeft);
                },
              ),

              ListTile(
                leading: Icon(Icons.security),
                title: Text('服务条款'),
                onTap: () {
                  Get.to(() => const DynamicContentScreen(title: '服务条款', prefKey: 'terms_conditions'), transition: Transition.rightToLeft);
                },
              ),

              ListTile(
                leading: Icon(Icons.info),
                title: Text('关于我们'),
                onTap: () {
                  Get.to(() => const DynamicContentScreen(title: '关于我们', prefKey: 'about_us'), transition: Transition.rightToLeft);
                },
              ),

              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('个人中心'),
                onTap: () {
                  Get.to(() => const ProfileScreen(), transition: Transition.leftToRight);
                },
              ),

              ListTile(
                leading: Icon(Icons.star),
                title: Text('评价我们'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final url = prefs.getString('rate_app_url') ?? '';
                  if (url.isNotEmpty) {
                    final uri = Uri.parse(url);
                    final launched = await launchExternalLink(uri);
                    if (!launched) {
                      Fluttertoast.showToast(msg: '无法打开链接', backgroundColor: Colors.red);
                    }
                  } else {
                    Fluttertoast.showToast(msg: '暂无评价链接', backgroundColor: Colors.orange);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('分享应用'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final shareUrl = prefs.getString('share_app_url') ?? '';
                  if (shareUrl.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: shareUrl));
                    Fluttertoast.showToast(msg: '分享链接已复制', backgroundColor: Colors.green);
                  } else {
                    Fluttertoast.showToast(msg: '暂无分享链接', backgroundColor: Colors.orange);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('更多应用'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final moreUrl = prefs.getString('more_app_url') ?? '';
                  if (moreUrl.isNotEmpty) {
                    final uri = Uri.parse(moreUrl);
                    final launched = await launchExternalLink(uri);
                    if (!launched) {
                      Get.snackbar("错误", '无法打开链接', backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  } else {
                    Get.snackbar("提示", '暂无链接', backgroundColor: Colors.orange, colorText: Colors.white);
                  }
                },
              ),

            ],
          ),
        ),

      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          //drawer
          leading: IconButton(onPressed: (){
            _advancedDrawerController.showDrawer();
          }, icon: Icon(Icons.menu)),
          title: Text(
            'TSVPN - V2ray',
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: Colors.black,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: (){
                  Get.to(()=> ProfileScreen(),transition: Transition.leftToRight);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: Colors.black, size: 24),
                ),
              ),
            ),
          ],
          automaticallyImplyLeading: false,
        ),

        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      ValueListenableBuilder<V2RayStatus>(
                        valueListenable: v2rayStatus,
                        builder: (context, value, child) {
                          // compute visual values from the live status value.state
                          final isConnected = value.state == 'CONNECTED';
                          final isConnecting = value.state == 'CONNECTING';

                          final Color statusColor = isConnected
                              ? const Color(0xFF4CAF50)
                              : isConnecting
                              ? const Color(0xFFFFB84D)
                              : const Color(0xFFFF6B6B);

                          final String statusText = isConnected
                              ? '已连接!'
                              : isConnecting
                              ? '连接中...'
                              : '已断开!';

                          final IconData statusIcon = isConnected
                              ? Icons.check_circle
                              : isConnecting
                              ? Icons.autorenew
                              : Icons.power_off;

                          final VPNStatus currentStatus = isConnected
                              ? VPNStatus.connected
                              : isConnecting
                              ? VPNStatus.connecting
                              : VPNStatus.disconnected;

                          return Column(
                            children: [
                              // Status display
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),

                              // Connection button
                              GestureDetector(
                                onTap: () async {
                                  // Prevent multiple taps during processing or connecting
                                  if (isProcessing || isConnecting) return;

                                  setState(() {
                                    isProcessing = true;
                                  });

                                  try {
                                    // Use the live status to decide connect/disconnect
                                    if (value.state == 'CONNECTED') {
                                      // Disconnect
                                      await v2ray.stopV2Ray();

                                      final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
                                      if (appCtrl != null && appCtrl.shouldShowRewarded && AdHelper.rewardedAdUnitId.isNotEmpty) {
                                        _showRewardedAd();
                                      }

                                      Get.find<ActiveServerController>().serverDisConnect(
                                        id: id,
                                        protocolName: "v2ray",
                                      );

                                      Get.snackbar(
                                        "提示",
                                        "VPN 已断开",
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                        margin: const EdgeInsets.all(16),
                                      );
                                    } else {
                                      // Connect
                                      if (config == null || config.toString().trim().isEmpty) {
                                        Get.snackbar(
                                          "提示",
                                          "未选择服务器。请选择一个服务器。",
                                          backgroundColor: Colors.orange,
                                          colorText: Colors.white,
                                          snackPosition: SnackPosition.BOTTOM,
                                          margin: const EdgeInsets.all(16),
                                        );
                                        return;
                                      }

                                      if (kDebugMode) {
                                        final preview = config.toString();
                                        print("Starting VPN with config: ${preview.length > 20 ? preview.substring(0, 20) : preview}...");
                                      }

                                      final configStr = config.toString().trim();
                                      final V2RayURL parser = V2ray.parseFromURL(configStr);

                                      Future<void> performV2Connect() async {
                                        if (await v2ray.requestPermission()){
                                          v2ray.startV2Ray(
                                            remark: parser.remark,
                                            config: parser.getFullConfiguration(),
                                            proxyOnly: false,
                                            bypassSubnets: null,
                                            blockedApps: null,
                                          );
                                          setState(() {});
                                        }
                                      }

                                      try {
                                        await performV2Connect();
                                        Get.find<ActiveServerController>().serverConnect(
                                          id: id,
                                          protocolName: "v2ray",
                                        );
                                      } catch (e) {
                                        if (kDebugMode) print('Connect after rewarded failed: $e');
                                        Get.snackbar("错误", '连接失败: $e', backgroundColor: Colors.red, colorText: Colors.white);
                                      }
                                    }
                                  } catch (e) {
                                    if (kDebugMode) print('Connection error: $e');
                                    Get.snackbar(
                                      "错误",
                                      "操作失败: $e",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                      margin: const EdgeInsets.all(16),
                                    );
                                  } finally {
                                    setState(() {
                                      isProcessing = false;
                                    });
                                  }
                                },
                                child: SizedBox(
                                  width: 320,
                                  height: 320,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Animated ripple waves for connecting and connected states
                                      if (isConnected || isConnecting)
                                        AnimatedBuilder(
                                          animation: _waveController,
                                          builder: (context, child) {
                                            return CustomPaint(
                                              size: const Size(320, 320),
                                              painter: ExpressVPNRipplePainter(
                                                color: statusColor,
                                                animation: _waveController,
                                                status: currentStatus,
                                              ),
                                            );
                                          },
                                        ),
                                      // Outer glow ring for connected state
                                      if (isConnected)
                                        Container(
                                          width: 240,
                                          height: 240,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.transparent,
                                                statusColor.withValues(alpha: 0.1),
                                                statusColor.withValues(alpha: 0.2),
                                              ],
                                              stops: const [0.5, 0.8, 1.0],
                                            ),
                                          ),
                                        ),
                                      // Center button with dynamic color
                                      Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              statusColor,
                                              statusColor.withValues(alpha: 0.85),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusColor.withValues(alpha: 0.5),
                                              blurRadius: 40,
                                              spreadRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 6,
                                              ),
                                            ),
                                            child: Icon(
                                              isConnecting
                                                  ? Icons.sync
                                                  : Icons.power_settings_new,
                                              size: 70,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () async {
                          final appCtrl0 = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
                          if (appCtrl0 != null && appCtrl0.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) {
                            _showInterstitialAd();
                          }
                          // Open location screen and wait for result; do not auto-select when user saves there
                          final result = await Get.to(() => V2LocationScreen(), transition: Transition.leftToRight);
                          if (kDebugMode) {
                            print('V2LocationScreen returned: $result');
                          }
                          // If result == 'saved' we intentionally do NOT auto-select the server here.
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[100],
                                ),
                                child: Center(
                                  child: Text(
                                    _selectedFlag,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedCountry,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Banner ad: show only when controller enables it and ad is ready
                      GetBuilder<AppSettingController>(
                        builder: (appCtrl) {
                          // If controller enabled banner but ad not loaded yet, try loading now
                          if (appCtrl.shouldShowBanner && !_isBannerAdReady && AdHelper.bannerAdUnitId.isNotEmpty) {
                            // Safe to call; _loadBannerAd will set state and prevent repeated loads
                            WidgetsBinding.instance.addPostFrameCallback((_) => _loadBannerAd());
                          }

                          // If banner was previously ready but controller now disables it, dispose
                          if (!appCtrl.shouldShowBanner && _isBannerAdReady) {
                            try {
                              _bannerAd.dispose();
                            } catch (_) {}
                            _isBannerAdReady = false;
                          }

                          if (appCtrl.shouldShowBanner && _isBannerAdReady) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  width: _bannerAd.size.width.toDouble(),
                                  height: _bannerAd.size.height.toDouble(),
                                  child: AdWidget(ad: _bannerAd),
                                ),
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),

                      // Ads removed: native video ad omitted
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

      ),
    );
  }

}

class ExpressVPNRipplePainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;
  final VPNStatus status;

  ExpressVPNRipplePainter({
    required this.color,
    required this.animation,
    required this.status,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw multiple ripple rings with different speeds
    for (int i = 0; i < 4; i++) {
      final progress = (animation.value + (i * 0.25)) % 1.0;
      final radius = maxRadius * 0.3 + (maxRadius * 0.7 * progress);

      // Calculate opacity with smooth fade out
      double opacity;
      if (progress < 0.2) {
        opacity = progress * 2.5; // Fade in
      } else if (progress > 0.8) {
        opacity = (1.0 - progress) * 5; // Fade out
      } else {
        opacity = 0.5;
      }

      opacity *= 0.4; // Overall opacity adjustment

      // Draw outer glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(center, radius, glowPaint);

      // Draw main ring
      final ringPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(center, radius, ringPaint);
    }

    // Draw pulsing background circle when connected
    if (status == VPNStatus.connected) {
      final pulseProgress = (animation.value * 2) % 1.0;
      final pulseOpacity = (1.0 - pulseProgress) * 0.15;

      final pulsePaint = Paint()
        ..color = color.withValues(alpha: pulseOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, maxRadius * 0.65, pulsePaint);
    }

    // Draw inner accent rings
    for (int i = 0; i < 2; i++) {
      final innerProgress = (animation.value * 0.5 + (i * 0.5)) % 1.0;
      final innerRadius = maxRadius * 0.35 + (maxRadius * 0.15 * innerProgress);
      final innerOpacity = (1.0 - innerProgress) * 0.3;

      final innerPaint = Paint()
        ..color = color.withValues(alpha: innerOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, innerRadius, innerPaint);
    }
  }

  @override
  bool shouldRepaint(ExpressVPNRipplePainter oldDelegate) => true;
}

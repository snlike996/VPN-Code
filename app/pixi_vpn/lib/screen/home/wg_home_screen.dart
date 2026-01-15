import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pixi_vpn/controller/wg_client_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixi_vpn/utils/link_launcher.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import '../../ads/ads_service.dart';
import '../../controller/active_server_controller.dart';
import '../../controller/app_setting_controller.dart';
import '../../controller/contact_controller.dart';
import '../../controller/wireguard_vpn_controller.dart';
import '../location/wg_location_screen.dart';
import '../profile/profile_screen.dart';
import '../setting/dynamic_content_screen.dart';
import '../setting/help_center_screen.dart';
import '../setting/live_chat_screen.dart';
import '../setting/select_protocol_screen.dart';

enum VPNStatus { disconnected, connecting, connected }

class WGHomeScreen extends StatefulWidget {
  const WGHomeScreen({super.key});

  @override
  State<WGHomeScreen> createState() => _VPNHomePageState();
}

class _VPNHomePageState extends State<WGHomeScreen>
    with SingleTickerProviderStateMixin {
  VPNStatus _status = VPNStatus.disconnected;
  late AnimationController _waveController;

// State variables
  String serverName = '';
  String address = 'wg-connect';
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

  // Quick connect servers (populated from API)

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

    _initializeApp();
    _initializeWireGuard();
    _setupVpnListener();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  // Generate random alphabetic string (only letters)
  String _generateRandomAlphabeticString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _initializeApp() async {
    try {
      final controller = Get.find<WireGuardVpnController>();

      // Load config from SharedPreferences
      await _loadConfigData();

      // If no config or server name is loaded, fetch server data but DO NOT auto-select or save any server.
      if (config.isEmpty || serverName.isEmpty) {
        if (kDebugMode) {
          print('No server selected. Fetching server list...');
        }

        // Fetch server list from API; do NOT auto-save or auto-select any server.
        await controller.getWireGuardVpnData();

        // Populate quick connect servers (take first 7 servers)
        if (controller.vpnServers.isNotEmpty) {
        }

        // If no servers available, inform the user.
        if (controller.vpnServers.isEmpty) {
          Fluttertoast.showToast(
            msg: "暂无可用VPN服务器",
          );
        }
      } else {
        if (kDebugMode) {
          print('Server already selected: $serverName');
        }

        // Still fetch servers for quick connect list (we don't overwrite the selected server)
        await controller.getWireGuardVpnData();
        if (controller.vpnServers.isNotEmpty) {
        }
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
      serverName = _decodeBase64(prefs.getString('name_w'));
      address = _decodeBase64(prefs.getString('address_w'));
      config = _decodeBase64(_decodeBase64(prefs.getString('link_w')));
      isPremium = _decodeBase64(prefs.getString('isPremium_w'));
      countryCode = _decodeBase64(prefs.getString('country_code_w'));

      // Update selected country and flag
      if (serverName.isNotEmpty) {
        _selectedCountry = serverName;
        _selectedFlag = _getFlagEmoji(countryCode ?? '');
      }

      if (kDebugMode) {
        print('Loaded id: $id');
        print('Loaded server: $serverName');
        print('Config length: ${config?.length ?? 0}');
      }

      // If any required data is missing, try to fetch from API
      if (serverName.isEmpty || address.isEmpty || config.isEmpty) {
        if (kDebugMode) {
          print('Missing server data. Will fetch from API...');
        }
        // Don't show error here, let _initializeApp handle it
        return;
      }

      // Validate config format
      if (!config.trim().startsWith('[Interface]')) {
        if (kDebugMode) {
          print('Invalid config format');
        }
        Fluttertoast.showToast(
          msg: "无效的服务器配置，请选择其他服务器。",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        config = '';
        serverName = '';
        address = '';
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

  // WireGuard instance
  final wireGuard = WireGuardFlutter.instance;

  void _initializeWireGuard() async {
    try {
      await wireGuard.initialize(interfaceName: "my_wg_vpn");
      debugPrint("WireGuard initialized successfully");
    } catch (error, stack) {
      debugPrint("Failed to initialize WireGuard: $error\n$stack");
    }
  }

  void _setupVpnListener() {
    wireGuard.vpnStageSnapshot.listen((event) {
      log("VPN Event: $event");
      final isConnected = event.toString() == "VpnStage.connected";

      setState(() {
        isConnect = isConnected;
        if (isConnected) {
          _status = VPNStatus.connected;
          _waveController.repeat(reverse: true);
        } else {
          _status = VPNStatus.disconnected;
          _waveController.stop();
          _waveController.reset();
        }
      });
    });
  }

  Future<void> _startVpn(String configContent) async {
    // Validate config before starting VPN
    if (configContent.isEmpty || !configContent.trim().startsWith('[Interface]')) {
      Fluttertoast.showToast(
        msg: "无效的WireGuard配置，无法启动VPN。",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }
    try {
      await wireGuard.startVpn(
        serverAddress: address,
        wgQuickConfig: configContent,
        providerBundleIdentifier: 'com.app.v2rayguardvpn.WGExtension',
      );
    } catch (error, stack) {
      debugPrint("Failed to start VPN: $error\n$stack");
    }
  }

  Future<void> _disconnect() async {
    try {
      await wireGuard.stopVpn();
    } catch (e, str) {
      debugPrint('Failed to disconnect: $e\n$str');
    }
  }

  Future<void> _toggleConnection() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      print('╔═══════════════════════════════════════════════════════╗');
      print('║           WG VPN CONNECTION TOGGLE STARTED            ║');
      print('╚═══════════════════════════════════════════════════════╝');
      print('📊 Current State:');
      print('   - Is Connected: $isConnect');
      print('   - Server ID: $id');
      print('   - Server Name: $serverName');
      print('   - Address: $address');
      print('   - Status: $_status');

      if (isConnect) {
        // Disconnect flow
        print('\n🔴 DISCONNECT FLOW INITIATED');

        setState(() {
          _status = VPNStatus.disconnected;
        });

        await _disconnect();

        final appCtrl = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
        if (appCtrl != null && appCtrl.shouldShowRewarded && AdHelper.rewardedAdUnitId.isNotEmpty) {
          _showRewardedAd();
        }

        Get.find<ActiveServerController>().serverDisConnect(
          id: id,
          protocolName: "wireguard",
        );

        // Remove client from server if we have a client name
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? savedClientName = prefs.getString('client_name_w');

        print('📋 Saved Client Name: ${savedClientName != null ? "Found" : "Not Found"}');

        if (savedClientName != null && savedClientName.isNotEmpty && id != null) {
          try {
            // Decode the saved client name
            String clientNameDecoded = utf8.decode(base64.decode(savedClientName));
            print('🔓 Decoded Client Name: $clientNameDecoded');

            if (clientNameDecoded.isNotEmpty) {
              print('🗑️ Calling removeClient API...');
              await Get.find<WgClientController>().removeClient(
                clientName: clientNameDecoded,
                serverId: id,
                protocol: 'wireguard',
              );

              print('✅ Client removed successfully');

              // Clear saved client name after removal
              await prefs.remove('client_name_w');
              print('🧹 Cleared saved client name from storage');
            }
          } catch (e) {
            print('❌ Failed to remove client: $e');
          }
        }

        Fluttertoast.showToast(
          msg: "VPN已断开",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        // Connect flow
        print('\n🟢 CONNECT FLOW INITIATED');

        if (id == null) {
          print('❌ ERROR: Server ID is null');
          Fluttertoast.showToast(
            msg: "未选择服务器，请选择服务器。",
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          setState(() {
            isProcessing = false;
          });
          return;
        }

        setState(() {
          _status = VPNStatus.connecting;
        });

        // Generate a unique client name (only alphabets, no numbers)
        // Using 8 random lowercase letters for uniqueness
        final generatedClientName = _generateRandomAlphabeticString(6);
        print('🎲 Generated Client Name: $generatedClientName (${generatedClientName.length} chars, alphabets only)');

        // Call generateClient (which updates the controller's state)
        print('📡 Calling generateClient API...');
        await Get.find<WgClientController>().generateClient(
          clientName: generatedClientName,
          serverId: id,
          protocol: 'wireguard',
        );

        // Retrieve config_content and client_name from the controller with null checks
        final wgController = Get.find<WgClientController>();

        print('🔍 Checking API Response...');
        print('   - isGenerateSuccess: ${wgController.isGenerateSuccess}');
        print('   - generateClientData: ${wgController.generateClientData}');

        // Check if generation was successful
        if (!wgController.isGenerateSuccess) {
          print('❌ Generate Client Failed!');
          Fluttertoast.showToast(
            msg: "生成客户端失败，请重试。",
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          setState(() {
            isProcessing = false;
            _status = VPNStatus.disconnected;
          });
          return;
        }

        // Use the helper getters with null checks
        final String? configContent = wgController.configContent;
        final String? clientName = wgController.clientName;

        print('📦 Extracted Data:');
        print('   - Config Content: ${configContent != null ? "${configContent.length} chars" : "NULL"}');
        print('   - Client Name: ${clientName ?? "NULL"}');

        if (configContent == null || configContent.isEmpty) {
          print('❌ Config Content is null or empty');
          Fluttertoast.showToast(
            msg: "无法生成客户端配置。",
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          setState(() {
            isProcessing = false;
            _status = VPNStatus.disconnected;
          });
          return;
        }

        // Save client name in shared preferences for later removal on disconnect
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final clientNameToSave = clientName ?? generatedClientName;
        await prefs.setString('client_name_w', base64.encode(utf8.encode(clientNameToSave)));
        print('💾 Saved Client Name: $clientNameToSave');

        // Update the config variable with the generated config for UI display
        config = configContent;
        print('📝 Updated config variable');

        // Start VPN with the generated config
        print('🚀 Starting VPN with generated config...');
        print('Config Preview: ${configContent.substring(0, configContent.length > 100 ? 100 : configContent.length)}...');
        await _startVpn(configContent);

        // Wait a bit to check connection status
        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _status = VPNStatus.connected;
        });

        print('VPN Connected Successfully!');

        Get.find<ActiveServerController>().serverDisConnect(
          id: id,
          protocolName: "wireguard",
        );

        Fluttertoast.showToast(
          msg: "VPN已连接",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

      print('╔═══════════════════════════════════════════════════════╗');
      print('║         WG VPN CONNECTION TOGGLE COMPLETED            ║');
      print('╚═══════════════════════════════════════════════════════╝\n');

    } catch (e, stackTrace) {
      print('❌❌❌ CRITICAL ERROR IN TOGGLE CONNECTION ❌❌❌');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace:\n$stackTrace');

      debugPrint('Toggle connection error: $e');
      setState(() {
        _status = VPNStatus.disconnected;
      });
      Fluttertoast.showToast(
        msg: "连接失败: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }



  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }


  Color get _statusColor {
    switch (_status) {
      case VPNStatus.disconnected:
        return const Color(0xFFFF6B6B);
      case VPNStatus.connecting:
        return const Color(0xFFFFB84D);
      case VPNStatus.connected:
        return const Color(0xFF4CAF50);
    }
  }

  String get _statusText {
    switch (_status) {
      case VPNStatus.disconnected:
        return '已断开!';
      case VPNStatus.connecting:
        return '连接中...';
      case VPNStatus.connected:
        return '已连接!';
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case VPNStatus.disconnected:
        return Icons.power_off;
      case VPNStatus.connecting:
        return Icons.autorenew;
      case VPNStatus.connected:
        return Icons.check_circle;
    }
  }

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
                            fontSize: 18,
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
                      Fluttertoast.showToast(msg: '无法打开链接', backgroundColor: Colors.red);
                    }
                  } else {
                    Fluttertoast.showToast(msg: '暂无链接', backgroundColor: Colors.orange);
                  }
                },
              ),

            ],
          ),
        ),

      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          //drawer
          leading: IconButton(onPressed: (){
            _advancedDrawerController.showDrawer();
          }, icon: Icon(Icons.menu)),
          title: Text(
            'TSVPN - WireGuard',
            style: GoogleFonts.openSans(
              fontSize: 19,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _statusIcon,
                            color: _statusColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusText,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _status != VPNStatus.connecting ? _toggleConnection : null,
                        child: SizedBox(
                          width: 320,
                          height: 320,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Animated ripple waves
                              if (_status == VPNStatus.connected || _status == VPNStatus.connecting)
                                AnimatedBuilder(
                                  animation: _waveController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: const Size(320, 320),
                                      painter: ExpressVPNRipplePainter(
                                        color: _statusColor,
                                        animation: _waveController,
                                        status: _status,
                                      ),
                                    );
                                  },
                                ),
                              // Outer glow ring
                              if (_status == VPNStatus.connected)
                                Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.transparent,
                                        _statusColor.withValues(alpha: 0.1),
                                        _statusColor.withValues(alpha: 0.2),
                                      ],
                                      stops: const [0.5, 0.8, 1.0],
                                    ),
                                  ),
                                ),
                              // Center button
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _statusColor,
                                      _statusColor.withValues(alpha: 0.85),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _statusColor.withValues(alpha: 0.5),
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
                                      _status == VPNStatus.connecting
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

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: (){
                          // Handle location selection
                          final appCtrl0 = Get.isRegistered<AppSettingController>() ? Get.find<AppSettingController>() : null;
                          if (appCtrl0 != null && appCtrl0.shouldShowInterstitial && AdHelper.interstitialAdUnitId.isNotEmpty) {
                            _showInterstitialAd();
                          }
                          Get.to(()=> WgLocationScreen(),transition: Transition.leftToRight);
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
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '已选位置',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedCountry,
                                      style: const TextStyle(
                                        fontSize: 16,
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

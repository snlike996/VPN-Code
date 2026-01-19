import 'dart:developer';
import 'package:get/get.dart';
import 'package:pixi_vpn/data/repository/v2ray_repo.dart';
import 'package:pixi_vpn/model/v2ray_vpn_model.dart';
import 'package:pixi_vpn/utils/ping_service.dart';
import '../data/model/base_model/api_response.dart';

class V2rayVpnController extends GetxController {
  final V2rayVpnRepo v2rayVpnRepo;
  final PingService pingService;

  V2rayVpnController({
    required this.v2rayVpnRepo,
    required this.pingService,
  });

  bool _isLoadingV2rayVpn = false;
  bool get isLoadingV2rayVpn => _isLoadingV2rayVpn;

  List<V2rayVpnModel> _vpnServers = [];
  List<V2rayVpnModel> get vpnServers => _vpnServers;

  Future<void> getV2rayVpnData() async {
    _isLoadingV2rayVpn = true;
    update();

    ApiResponse apiResponse = await v2rayVpnRepo.getV2rayVpnData();

    _isLoadingV2rayVpn = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        final List<dynamic> rawList = apiResponse.response!.data["data"] ?? [];
        _vpnServers = rawList.map((e) => V2rayVpnModel.fromJson(e)).toList();

      } catch (e) {
        _vpnServers = [];
        log('Failed to parse VPN server list: $e');
      }
    } else {
      _vpnServers = [];
      log('Failed to load VPN data. Status: ${apiResponse.response?.statusCode}');
    }

    update(); // Notify UI about data change
  }

  /// Test ping for a single server by index
  /// Uses unified speed test URL: https://www.google.com/generate_204
  /// Principle: Flutter HTTP → VPN Tunnel → Speed Test Server
  /// No retry on failure
  Future<void> testServerPing(int index) async {
    if (index < 0 || index >= _vpnServers.length) return;

    _vpnServers[index].isPinging = true;
    update();

    try {
      // Test speed using Google generate_204 (3s timeout, no retry)
      // When VPN is connected, the request goes through the VPN tunnel
      final ping = await pingService.pingSpeed();
      
      _vpnServers[index].ping = ping;
      _vpnServers[index].isPinging = false;
      update();
    } catch (e) {
      // Failure - no retry
      log('Failed to test server ping at index $index: $e');
      _vpnServers[index].ping = null;
      _vpnServers[index].isPinging = false;
      update();
    }
  }

  /// Test ping for all servers with concurrency limit
  /// Limits concurrent pings to 5 to avoid overwhelming the network
  Future<void> testAllServersPing() async {
    const int concurrencyLimit = 5; // Limit to 3-5 concurrent pings
    
    // Process servers in batches
    for (int i = 0; i < _vpnServers.length; i += concurrencyLimit) {
      final end = (i + concurrencyLimit < _vpnServers.length) 
          ? i + concurrencyLimit 
          : _vpnServers.length;
      
      // Create batch of futures
      final batch = <Future>[];
      for (int j = i; j < end; j++) {
        batch.add(testServerPing(j));
      }
      
      // Wait for current batch to complete before starting next batch
      await Future.wait(batch).catchError((e) {
        log('Error in batch ping test: $e');
      });
    }
    
    log('All server pings completed');
  }
}

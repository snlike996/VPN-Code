import 'dart:developer';
import 'package:get/get.dart';
import 'package:pixi_vpn/data/repository/v2ray_repo.dart';
import 'package:pixi_vpn/model/v2ray_vpn_model.dart';
import '../data/model/base_model/api_response.dart';

class V2rayVpnController extends GetxController {
  final V2rayVpnRepo v2rayVpnRepo;

  V2rayVpnController({required this.v2rayVpnRepo});

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
}

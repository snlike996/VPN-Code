import 'dart:developer';
import 'package:get/get.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/wireguard_vpn_repo.dart';
import '../model/wg_vpn_server_model.dart';

class WireGuardVpnController extends GetxController {
  final WireGuardVpnRepo wireGuardVpnRepo;

  WireGuardVpnController({required this.wireGuardVpnRepo});

  bool _isLoadingWireGuardVpn = false;
  bool get isLoadingWireGuardVpn => _isLoadingWireGuardVpn;

  List<WGVpnServerModel> _vpnServers = [];
  List<WGVpnServerModel> get vpnServers => _vpnServers;

  Future<void> getWireGuardVpnData() async {
    _isLoadingWireGuardVpn = true;
    update();

    ApiResponse apiResponse = await wireGuardVpnRepo.getWireGuardVpnData();

    _isLoadingWireGuardVpn = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        final List<dynamic> rawList = apiResponse.response!.data["data"] ?? [];
        _vpnServers = rawList.map((e) => WGVpnServerModel.fromJson(e)).toList();
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

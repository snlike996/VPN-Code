import 'dart:developer';
import 'package:get/get.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/open_vpn_repo.dart';
import '../model/open_vpn_server_model.dart';

class OpenVpnController extends GetxController {
  final OpenVpnRepo openVpnRepo;

  OpenVpnController({required this.openVpnRepo});

  bool _isLoadingOpenVpn = false;
  bool get isLoadingOpenVpn => _isLoadingOpenVpn;

  List<OpenVpnServerModel> _vpnServers = [];
  List<OpenVpnServerModel> get vpnServers => _vpnServers;

  Future<void> getOpenVpnData() async {
    _isLoadingOpenVpn = true;
    update();

    ApiResponse apiResponse = await openVpnRepo.getOpenVpnData();

    _isLoadingOpenVpn = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        final List<dynamic> rawList = apiResponse.response!.data["data"] ?? [];
        _vpnServers = rawList.map((e) => OpenVpnServerModel.fromJson(e)).toList();

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

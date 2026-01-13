import 'dart:developer';
import 'package:get/get.dart';
import 'package:pixi_vpn/data/repository/help_center_repo.dart';
import '../data/model/base_model/api_response.dart';

class HelpCenterController extends GetxController {
  final HelpCenterRepo helpCenterRepo;

  HelpCenterController({required this.helpCenterRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  dynamic helpCenterData;

  Future<void> getHelpCenterData() async {
    _isLoading = true;
    update();

    ApiResponse apiResponse = await helpCenterRepo.getHelpCenterData();

    _isLoading = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
       helpCenterData = apiResponse.response!.data["results"];

      } catch (e) {
        log('Failed to parse VPN server list: $e');
      }
    } else {
      log('Failed to load VPN data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }
}

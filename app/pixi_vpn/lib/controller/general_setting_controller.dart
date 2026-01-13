import 'dart:developer';
import 'package:get/get.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/genral_setting_repo.dart';

class GeneralSettingController extends GetxController {
  final GeneralSettingRepo generalSettingRepo;

  GeneralSettingController({required this.generalSettingRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  dynamic appGeneralData;

  Future<void> getGeneralData() async {
    _isLoading = true;
    update();

    ApiResponse apiResponse = await generalSettingRepo.getGeneralData();

    _isLoading = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        appGeneralData = apiResponse.response!.data;

      } catch (e) {
        log('Failed to parse: $e');
      }
    } else {
      log('Failed to load data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }
}

import 'dart:developer';
import 'package:get/get.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/app_update_repo.dart';

class AppUpdateController extends GetxController {
  final AppUpdateRepo appUpdateRepo;

  AppUpdateController({required this.appUpdateRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  dynamic appUpdateData;

  Future<void> getUpdateData() async {
    _isLoading = true;
    update();

    ApiResponse apiResponse = await appUpdateRepo.getUpdateData();

    _isLoading = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        appUpdateData = apiResponse.response!.data;

      } catch (e) {
        log('Failed to parse: $e');
      }
    } else {
      log('Failed to load data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }
}

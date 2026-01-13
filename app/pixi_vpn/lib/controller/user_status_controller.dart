import 'package:get/get.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/user_status_repo.dart';

class UserStatusController extends GetxController {
  final UserStatusRepo userStatusRepo;

  UserStatusController({required this.userStatusRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  dynamic userStatusData;

  Future<dynamic> getUserStatus() async {
    _isLoading = true;
    update();
    ApiResponse apiResponse = await userStatusRepo.getUserStatus();

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _isLoading = false;
      update();
      if (apiResponse.response!.data != null) {
        userStatusData = apiResponse.response!.data;
      }

    } else {
      _isLoading = false;
      update();
    }
  }


}
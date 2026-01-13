import 'package:get/get.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/profile_repo.dart';

class ProfileController extends GetxController {
  final ProfileRepo profileRepo;

  ProfileController({required this.profileRepo});

  bool isLoading = false;

  bool isLoadingCancel = false;

  dynamic profileData;
  dynamic subscriptionCancelData;

  Future<dynamic> getProfileData() async {
    isLoading = true;
    update();
    ApiResponse apiResponse = await profileRepo.getProfileData();

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      isLoading = false;
      update();
      if (apiResponse.response!.data != null) {
        profileData = apiResponse.response!.data;
      }
    } else {
      isLoading = false;
      update();
    }
  }

  cancelSubscriptionData() async {
    isLoadingCancel = true;
    update();
    ApiResponse apiResponse = await profileRepo.cancelSubscription();

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      isLoadingCancel = false;
      update();
      if (apiResponse.response!.data != null) {
        subscriptionCancelData = apiResponse.response!.data;
      }
    } else {
      isLoadingCancel = false;
      update();
    }
  }

}
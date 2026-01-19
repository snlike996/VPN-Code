import 'package:get/get.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/profile_repo.dart';

class ProfileController extends GetxController {
  final ProfileRepo profileRepo;

  ProfileController({required this.profileRepo});

  bool isLoading = false;

  bool isLoadingCancel = false;
  bool isRedeemSubmitting = false;
  bool hasPendingRedeem = false;

  dynamic profileData;
  dynamic subscriptionCancelData;
  dynamic redeemData;

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

  Future<dynamic> submitRedeemCode(String code) async {
    isRedeemSubmitting = true;
    update();
    ApiResponse apiResponse = await profileRepo.submitRedeemCode(code: code);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      isRedeemSubmitting = false;
      update();
      redeemData = apiResponse.response!.data;
      if (redeemData is Map && redeemData['message'] != null) {
        hasPendingRedeem = true;
      }
      update();
      return apiResponse.response!.statusCode;
    } else {
      isRedeemSubmitting = false;
      update();
    }
  }

  Future<void> getRedeemStatus() async {
    ApiResponse apiResponse = await profileRepo.getRedeemStatus();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      final data = apiResponse.response!.data;
      if (data is Map) {
        hasPendingRedeem = data['status'] == 'pending';
        update();
      }
    }
  }

}

import 'package:get/get.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/subscription_repo.dart';

class SubscriptionController extends GetxController {
  final SubscriptionRepo subscriptionRepo;

  SubscriptionController({required this.subscriptionRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  dynamic subscribeData;

  Future<dynamic> purchaseSubscription({
    dynamic packageName,
    dynamic validity,
    dynamic price,
  }) async {
    _isLoading = true;
    update();
    ApiResponse apiResponse = await subscriptionRepo.purchaseSubscription(
      packageName: packageName,
      price: price,
      validity: validity
    );

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _isLoading = false;
      update();
      if (apiResponse.response!.data != null) {
        subscribeData = apiResponse.response!.data;
      }
      return apiResponse.response!.statusCode;
    } else {
      _isLoading = false;
      update();
    }
  }


}
import 'dart:developer';
import 'package:get/get.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/contact_repo.dart';

class ContactController extends GetxController {
  final ContactRepo contactRepo;

  ContactController({required this.contactRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  dynamic appContactData;

  Future<void> getContactData() async {
    _isLoading = true;
    update();

    ApiResponse apiResponse = await contactRepo.getContactData();

    _isLoading = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        appContactData = apiResponse.response!.data;

      } catch (e) {
        log('Failed to parse: $e');
      }
    } else {
      log('Failed to load data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }
}

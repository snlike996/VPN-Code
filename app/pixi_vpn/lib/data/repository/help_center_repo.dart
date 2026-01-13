import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class HelpCenterRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  HelpCenterRepo({required this.dioClient, required this.secureStorage});

  Future<ApiResponse> getHelpCenterData() async {
    try {
      Response response = await dioClient.get(
        AppStrings.helpCenterUrl,
        options: Options(headers: {
          "Content-Type": "application/json",
        }),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }


}
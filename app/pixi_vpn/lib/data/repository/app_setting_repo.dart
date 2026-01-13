import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class SettingRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  SettingRepo({required this.dioClient, required this.secureStorage});

  Future<ApiResponse> getAppSettingData() async {
    try {
      Response response = await dioClient.get(
        AppStrings.appSettingUrl,
        options: Options(headers: {
          "Content-Type": "application/json",
        }),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> getAdmobData() async {
    try {
      Response response = await dioClient.get(
        AppStrings.admobUrl,
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
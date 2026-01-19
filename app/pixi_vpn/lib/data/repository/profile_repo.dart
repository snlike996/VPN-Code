import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class ProfileRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  ProfileRepo({required this.dioClient, required this.secureStorage});

  Future<ApiResponse> getProfileData() async {
    try {
      String? token = await secureStorage.read(key: AppStrings.tokenKey);
      Response response = await dioClient.get(
        AppStrings.profileUrl,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  cancelSubscription() async {
    try {
      Response response = await dioClient.post(
        AppStrings.subscriptionCancelUrl,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Authorization":
          "Bearer ${ secureStorage.read(key: AppStrings.tokenKey)}",
        }),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> submitRedeemCode({required String code}) async {
    try {
      String? token = await secureStorage.read(key: AppStrings.tokenKey);
      Response response = await dioClient.post(
        AppStrings.redeemCodeUrl,
        data: {"code": code},
        options: Options(headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> getRedeemStatus() async {
    try {
      String? token = await secureStorage.read(key: AppStrings.tokenKey);
      Response response = await dioClient.get(
        AppStrings.redeemStatusUrl,
        options: Options(headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class ProfileRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  ProfileRepo({required this.dioClient, required this.secureStorage});

  Future<String?> _readToken() async {
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      return dioClient.sharedPreferences.getString(AppStrings.tokenKey);
    }
    return secureStorage.read(key: AppStrings.tokenKey);
  }

  Future<ApiResponse> getProfileData() async {
    try {
      String? token = await _readToken();
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
      String? token = await _readToken();
      Response response = await dioClient.post(
        AppStrings.subscriptionCancelUrl,
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

  Future<ApiResponse> submitRedeemCode({required String code}) async {
    try {
      String? token = await _readToken();
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
      String? token = await _readToken();
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

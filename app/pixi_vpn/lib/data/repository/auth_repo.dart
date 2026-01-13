import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class AuthRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  AuthRepo({
    required this.dioClient,
    required this.secureStorage,
  });

  // ===================== API ======================

  Future<ApiResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      Response response = await dioClient.post(
        AppStrings.registerUrl,
        queryParameters: {
          "name": name,
          "email": email,
          "password": password,
        },
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    try {
      Response response = await dioClient.post(
        AppStrings.loginUrl,
        queryParameters: {
          "email": email,
          "password": password,
          "device_id": deviceId,
        },
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> forgetPassword({dynamic email}) async {
    try {
      Response response = await dioClient.post(
        AppStrings.forgetPasswordUrl,
        queryParameters: {
          "email" : email,
        },
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> resetPassword({dynamic email,dynamic token, dynamic password, dynamic confirmPassword}) async
  {
    try {
      Response response = await dioClient.post(
        AppStrings.resetPasswordUrl,
        queryParameters: {
          "token" : token,
          "email" : email,
          "password" : password,
          "password_confirmation" : confirmPassword,
        },
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  // ===================== TOKEN ======================

  /// Save token securely and update Dio headers
  Future<void> saveUserToken(String token) async {
    dioClient.updateHeader(token, "");
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      await dioClient.sharedPreferences.setString(AppStrings.tokenKey, token);
    } else {
      await secureStorage.write(key: AppStrings.tokenKey, value: token);
    }
  }

  /// Get token securely
  Future<String> getUserToken() async {
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      return dioClient.sharedPreferences.getString(AppStrings.tokenKey) ?? "";
    }
    return await secureStorage.read(key: AppStrings.tokenKey) ?? "";
  }

  /// Remove token
  Future<void> removeUserToken() async {
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      await dioClient.sharedPreferences.remove(AppStrings.tokenKey);
    } else {
      await secureStorage.delete(key: AppStrings.tokenKey);
    }
  }

  /// Same as saveUserToken but sets Dio headers too
  Future<void> saveAuthToken(String token) async {
    dioClient.token = token;
    dioClient.dio?.options.headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      await dioClient.sharedPreferences.setString(AppStrings.tokenKey, token);
    } else {
      await secureStorage.write(key: AppStrings.tokenKey, value: token);
    }
  }

  /// Get auth token for header
  Future<String> getAuthToken() async {
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      return dioClient.sharedPreferences.getString(AppStrings.tokenKey) ?? "";
    }
    return await secureStorage.read(key: AppStrings.tokenKey) ?? "";
  }
}

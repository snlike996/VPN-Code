import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class UserStatusRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  UserStatusRepo({required this.dioClient, required this.secureStorage});

  Future<ApiResponse> getUserStatus() async {
    try {
      Response response = await dioClient.get(
        AppStrings.userStatusUrl,
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
}
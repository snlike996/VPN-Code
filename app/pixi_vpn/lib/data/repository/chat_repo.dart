import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class ChatRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  ChatRepo({required this.dioClient, required this.secureStorage});

  Future<ApiResponse> getChatData() async {
    try {
      String? token = await secureStorage.read(key: AppStrings.tokenKey);
      Response response = await dioClient.get(
        AppStrings.chatUrl,
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


  Future<ApiResponse> sendChat({dynamic message}) async {
    try {
      String? token = await secureStorage.read(key: AppStrings.tokenKey);
      Response response = await dioClient.post(
        AppStrings.chatUrl,
        data: {
          "message": message,
        },
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
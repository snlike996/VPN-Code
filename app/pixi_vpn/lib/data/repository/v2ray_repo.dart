import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class V2rayVpnRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  V2rayVpnRepo({required this.dioClient, required this.secureStorage});

  Future<ApiResponse> getCountries() async {
    try {
      String? token = await secureStorage.read(key: AppStrings.tokenKey);
      final headers = <String, String>{
        "Accept": "application/json",
      };
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
      Response response = await dioClient.get(
        AppStrings.v2rayCountriesUrl,
        options: Options(
          headers: headers,
        ),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> getSubscriptionContent(String countryCode) async {
    try {
      String? token = await secureStorage.read(key: AppStrings.tokenKey);
      final headers = <String, String>{
        "Accept": "text/plain",
      };
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
      Response response = await dioClient.get(
        AppStrings.v2raySubscriptionContentUrl,
        queryParameters: {
          'country': countryCode,
        },
        options: Options(
          responseType: ResponseType.plain,
          headers: headers,
        ),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

}

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

  Future<ApiResponse> getV2rayVpnData() async {
    try {
      Response response = await dioClient.get(
        AppStrings.v2rayUrl,
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
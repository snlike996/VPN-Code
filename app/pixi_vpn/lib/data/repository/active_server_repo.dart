import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class ActiveServerRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  ActiveServerRepo({required this.dioClient, required this.secureStorage});

  Future<ApiResponse> serverConnect({
    dynamic id, dynamic protocolName
}) async {
    try {
      Response response = await dioClient.post(
        AppStrings.serverConnect,
        data: {
          "server_id": id,
          "protocol": protocolName,
        },
        options: Options(headers: {
          "Content-Type": "application/json",
        }),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }


  Future<ApiResponse> serverDisConnect({
    dynamic id, dynamic protocolName
  }) async {
    try {
      Response response = await dioClient.post(
        AppStrings.serverDisConnect,
        data: {
          "server_id": id,
          "protocol": protocolName,
        },
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
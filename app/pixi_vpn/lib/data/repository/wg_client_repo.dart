import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_strings.dart';
import '../datasource/remote/dio/dio_client.dart';
import '../datasource/remote/exception/api_error_handler.dart';
import '../model/base_model/api_response.dart';

class WgClientRepo {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  WgClientRepo({required this.dioClient, required this.secureStorage});

  Future<ApiResponse> generateClient({
    dynamic clientName, dynamic serverId, dynamic protocol
  }) async {
    try {
      print('🌐 [REPO] Generate Client API Call Starting...');

      String? token = await secureStorage.read(key: AppStrings.tokenKey);
      print('🔑 Token: ${token != null ? "✓ Present (${token.substring(0, 20)}...)" : "✗ Missing"}');
      print('📍 Endpoint: ${AppStrings.wireGuardClientGenerate}');
      print('📤 Request Data: {');
      print('   client_name: $clientName');
      print('   server_id: $serverId');
      print('   protocol: $protocol');
      print('}');

      Response response = await dioClient.post(
        AppStrings.wireGuardClientGenerate,
        data :{
          "client_name": clientName,
          "server_id": serverId,
          "protocol": protocol
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          // Don't throw exceptions for any status code - let us handle it
          validateStatus: (status) => true,
        ),
      );

      print('✅ [REPO] API Call Completed (Status: ${response.statusCode})');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode != null && response.statusCode! >= 500) {
        print('⚠️ Warning: Server returned error status ${response.statusCode}');
        print('⚠️ This indicates a server-side issue');
        print('⚠️ Checking if response still contains valid data...');
      }

      return ApiResponse.withSuccess(response);
    } catch (e) {
      print('❌ [REPO] API Call Failed');
      print('Error Type: ${e.runtimeType}');
      print('Error: $e');

      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }


  Future<ApiResponse> removeClient({
    dynamic clientName, dynamic serverId, dynamic protocol
  }) async {
    try {
      print('🌐 [REPO] Remove Client API Call Starting...');

      String? token = await secureStorage.read(key: AppStrings.tokenKey);
      print('🔑 Token: ${token != null ? "✓ Present (${token.substring(0, 20)}...)" : "✗ Missing"}');
      print('📍 Endpoint: ${AppStrings.wireGuardClientRemove}');
      print('📤 Request Data: {');
      print('   client_name: $clientName');
      print('   server_id: $serverId');
      print('   protocol: $protocol');
      print('}');

      Response response = await dioClient.post(
        AppStrings.wireGuardClientRemove,
        data :{
          "client_name": clientName,
          "server_id": serverId,
          "protocol": protocol
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          // Don't throw exceptions for any status code - let us handle it
          validateStatus: (status) => true,
        ),
      );

      print('✅ [REPO] API Call Completed (Status: ${response.statusCode})');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode != null && response.statusCode! >= 500) {
        print('⚠️ Warning: Server returned error status ${response.statusCode}');
      }

      return ApiResponse.withSuccess(response);
    } catch (e) {
      print('❌ [REPO] API Call Failed');
      print('Error Type: ${e.runtimeType}');
      print('Error: $e');

      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

}
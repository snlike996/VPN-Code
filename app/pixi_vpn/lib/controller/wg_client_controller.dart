import 'dart:developer';
import 'package:get/get.dart';
import 'package:pixi_vpn/data/repository/wg_client_repo.dart';
import '../data/model/base_model/api_response.dart';

class WgClientController extends GetxController {
  final WgClientRepo wgClientRepo;

  WgClientController({required this.wgClientRepo});

  bool _isLoadingGenerate = false;
  bool get isLoadingGenerate => _isLoadingGenerate;

  bool _isLoadingRemove = false;
  bool get isLoadingRemove => _isLoadingRemove;

  dynamic generateClientData;
  dynamic removeClientData;

  // Helper getters to safely extract config content and client name
  String? get configContent {
    if (generateClientData != null && generateClientData is Map) {
      return generateClientData['config_content']?.toString();
    }
    return null;
  }

  String? get clientName {
    if (generateClientData != null && generateClientData is Map) {
      return generateClientData['client_name']?.toString();
    }
    return null;
  }

  bool get isGenerateSuccess {
    if (generateClientData != null && generateClientData is Map) {
      return generateClientData['success'] == true;
    }
    return false;
  }

  Future<void> generateClient(
      {
        dynamic clientName, dynamic serverId, dynamic protocol
      }
      ) async {
    _isLoadingGenerate = true;
    update();

    print('═══════════════════════════════════════════════════════');
    print('🔵 GENERATE CLIENT REQUEST');
    print('Client Name: $clientName');
    print('Server ID: $serverId');
    print('Protocol: $protocol');
    print('═══════════════════════════════════════════════════════');

    ApiResponse apiResponse = await wgClientRepo.generateClient(
        clientName: clientName,
        serverId: serverId,
        protocol: protocol
    );

    _isLoadingGenerate = false;

    print('═══════════════════════════════════════════════════════');
    print('📥 GENERATE CLIENT RESPONSE');
    print('Response is null: ${apiResponse.response == null}');
    if (apiResponse.response != null) {
      print('Status Code: ${apiResponse.response!.statusCode}');
      print('Status Message: ${apiResponse.response!.statusMessage}');
      print('Data is null: ${apiResponse.response!.data == null}');
      print('Data Type: ${apiResponse.response!.data.runtimeType}');
      print('Response Data: ${apiResponse.response!.data}');
      print('Response Headers: ${apiResponse.response!.headers}');
    }
    if (apiResponse.error != null) {
      print('❌ API Error: ${apiResponse.error}');
      print('Error Type: ${apiResponse.error.runtimeType}');
    }
    print('═══════════════════════════════════════════════════════');

    // Check if we have response data regardless of status code
    // Sometimes server returns 500 but still has valid data
    if (apiResponse.response != null && apiResponse.response!.data != null) {
      try {
        final data = apiResponse.response!.data;
        final statusCode = apiResponse.response!.statusCode;

        // Check if data has the expected structure
        if (data is Map && data['config_content'] != null) {
          generateClientData = data;
          print('✅ Generate Client Success! (Status: $statusCode)');
          print('⚠️ Warning: Server returned status $statusCode but data is valid');
          print('Config Content Length: ${configContent?.length ?? 0}');
          print('Client Name: ${this.clientName}');
          print('Data Success Flag: ${data['success']}');
        } else if (statusCode == 200 || statusCode == 201) {
          // Success status but unexpected data format
          generateClientData = data;
          print('⚠️ Success status but unexpected data format');
          print('Data: $data');
        } else {
          // Error status and no valid data
          print('❌ Failed to load data');
          print('Status Code: $statusCode');
          print('Response: $data');
          print('Server returned error status without valid config_content');
        }
      } catch (e, stackTrace) {
        print('❌ Failed to parse: $e');
        print('Stack trace: $stackTrace');
        log('Failed to parse: $e');
      }
    } else {
      print('❌ Failed to load data - No response or data');
      print('Status Code: ${apiResponse.response?.statusCode}');
      print('Response: ${apiResponse.response?.data}');
      print('Error: ${apiResponse.error}');
      log('Failed to load data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }

  Future<void> removeClient(
      {
        dynamic clientName, dynamic serverId, dynamic protocol
      }
      ) async {
    _isLoadingRemove = true;
    update();

    print('═══════════════════════════════════════════════════════');
    print('🔴 REMOVE CLIENT REQUEST');
    print('Client Name: $clientName');
    print('Server ID: $serverId');
    print('Protocol: $protocol');
    print('═══════════════════════════════════════════════════════');

    ApiResponse apiResponse = await wgClientRepo.removeClient(
        clientName: clientName,
        serverId: serverId,
        protocol: protocol
    );

    _isLoadingRemove = false;

    print('═══════════════════════════════════════════════════════');
    print('📥 REMOVE CLIENT RESPONSE');
    print('Response is null: ${apiResponse.response == null}');
    if (apiResponse.response != null) {
      print('Status Code: ${apiResponse.response!.statusCode}');
      print('Status Message: ${apiResponse.response!.statusMessage}');
      print('Data is null: ${apiResponse.response!.data == null}');
      print('Response Data: ${apiResponse.response!.data}');
      print('Response Headers: ${apiResponse.response!.headers}');
    }
    if (apiResponse.error != null) {
      print('❌ API Error: ${apiResponse.error}');
    }
    print('═══════════════════════════════════════════════════════');

    if (apiResponse.response != null &&
        (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201) &&
        apiResponse.response!.data != null) {
      try {
        removeClientData = apiResponse.response!.data;
        print('✅ Remove Client Success!');
        print('Response Data: $removeClientData');

      } catch (e) {
        print('❌ Failed to parse: $e');
        log('Failed to parse: $e');
      }
    } else {
      print('❌ Failed to remove client');
      print('Status Code: ${apiResponse.response?.statusCode}');
      print('Response: ${apiResponse.response?.data}');
      print('Error: ${apiResponse.error}');
      log('Failed to load data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }
}

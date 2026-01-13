import 'dart:developer';
import 'package:get/get.dart';
import 'package:pixi_vpn/data/repository/active_server_repo.dart';
import '../data/model/base_model/api_response.dart';

class ActiveServerController extends GetxController {
  final ActiveServerRepo activeServerRepo;

  ActiveServerController({required this.activeServerRepo});

  bool _isLoadingConnect = false;
  bool get isLoadingConnect => _isLoadingConnect;

  bool _isLoadingDisConnect = false;
  bool get isLoadingDisConnect => _isLoadingDisConnect;

  dynamic serverConnectedData;
  dynamic serverDisconnectedData;

  Future<void> serverConnect(
      {
        dynamic id, dynamic protocolName
      }
      ) async {
    _isLoadingConnect = true;
    update();

    ApiResponse apiResponse = await activeServerRepo.serverConnect(
      id: id,
      protocolName: protocolName
    );

    _isLoadingConnect = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        serverConnectedData = apiResponse.response!.data;

      } catch (e) {
        log('Failed to parse: $e');
      }
    } else {
      log('Failed to load data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }

  Future<void> serverDisConnect(
      {
        dynamic id, dynamic protocolName
      }
      ) async {
    _isLoadingDisConnect = true;
    update();

    ApiResponse apiResponse = await activeServerRepo.serverDisConnect(
        id: id,
        protocolName: protocolName
    );

    _isLoadingDisConnect = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        serverDisconnectedData = apiResponse.response!.data;

      } catch (e) {
        log('Failed to parse: $e');
      }
    } else {
      log('Failed to load data. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }
}

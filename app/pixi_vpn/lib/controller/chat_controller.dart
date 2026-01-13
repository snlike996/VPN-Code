import 'dart:developer';
import 'package:get/get.dart';
import 'package:pixi_vpn/data/repository/chat_repo.dart';
import '../data/model/base_model/api_response.dart';

class ChatController extends GetxController {
  final ChatRepo chatRepo;

  ChatController({required this.chatRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingSend = false;
  bool get isLoadingSend => _isLoadingSend;

  dynamic chatData;
  dynamic sendChatData;

  Future<void> getChatData({bool silentRefresh = false}) async {
    // Only show loading indicator if not a silent refresh
    if (!silentRefresh) {
      _isLoading = true;
      update();
    }

    ApiResponse apiResponse = await chatRepo.getChatData();

    if (!silentRefresh) {
      _isLoading = false;
    }

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        chatData = apiResponse.response!.data;
        if (!silentRefresh) {
          log('Chat data loaded successfully');
          log('Chat data type: ${chatData.runtimeType}');
          log('Chat data length: ${chatData is List ? chatData.length : 'Not a list'}');
          log('Chat data content: $chatData');
        }
      } catch (e) {
        log('Failed to parse chat data: $e');
      }
    } else {
      log('Failed to load chat data. Status: ${apiResponse.response?.statusCode}');
      chatData = null;
    }

    update();
  }

  Future<void> sendChat({dynamic message}) async {
    _isLoadingSend = true;
    update();

    ApiResponse apiResponse = await chatRepo.sendChat(
      message: message
    );

    _isLoadingSend = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      try {
        // After successful send, refresh the chat data to get the latest messages
        await getChatData();
        log('Message sent successfully, chat data refreshed');
      } catch (e) {
        log('Failed to refresh chat data after send: $e');
      }
    } else {
      log('Failed to send message. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }


}

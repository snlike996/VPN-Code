// Live Chat Screen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixi_vpn/controller/chat_controller.dart';
import 'package:intl/intl.dart';
import 'package:pixi_vpn/controller/auth_controller.dart';
import 'package:pixi_vpn/ui/shared/auth/signin_screen.dart';
import 'package:pixi_vpn/utils/app_colors.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _autoRefreshTimer;
  bool _isUserAtBottom = true;

  /// Check auth token and fetch chat data only when logged in.
  void _checkAuthAndFetchChat() async {
    final token = await Get.find<AuthController>().getAuthToken();
    if (token.isNotEmpty) {
      // fetch chat only when authenticated
      await Get.find<ChatController>().getChatData();
      // scroll after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) _scrollToBottom();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Add scroll listener to track if user is at bottom
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndFetchChat();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      // Consider user at bottom if within 100 pixels of bottom
      _isUserAtBottom = (maxScroll - currentScroll) < 100;
    }
  }

  /// Start auto-refresh timer (every 15 seconds)
  void _startAutoRefresh() async {
    // Check if user is logged in before starting auto-refresh
    final token = await Get.find<AuthController>().getAuthToken();
    if (token.isEmpty) return;

    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      // Silently refresh chat in background
      await _silentRefreshChat();
    });
  }

  /// Silent background refresh without showing loading indicator
  Future<void> _silentRefreshChat() async {
    final token = await Get.find<AuthController>().getAuthToken();
    if (token.isEmpty) {
      _autoRefreshTimer?.cancel();
      return;
    }

    try {
      // Get chat controller
      final chatController = Get.find<ChatController>();

      // Store current message count to detect new messages
      final currentCount = chatController.chatData is List
          ? (chatController.chatData as List).length
          : 0;

      // Silently fetch new messages (don't show loading indicator)
      await chatController.getChatData(silentRefresh: true);

      // Check if new messages arrived
      final newCount = chatController.chatData is List
          ? (chatController.chatData as List).length
          : 0;

      // Auto-scroll to bottom only if user was already at bottom and new messages arrived
      if (newCount > currentCount && _isUserAtBottom && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      // Silently fail - don't disrupt user experience
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Clear input immediately for better UX
    _messageController.clear();

    // Send the message
    await Get.find<ChatController>().sendChat(message: message);

    // Scroll to bottom after the list is refreshed
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _scrollController.hasClients) {
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      builder: (chatController) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: () => _checkAuthAndFetchChat(),
              ),
            ],
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.appPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '客服团队',
                      style: GoogleFonts.raleway(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '在线',
                      style: GoogleFonts.outfit(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Body: check auth first, then show chat UI when logged in
          body: SafeArea(
            child: FutureBuilder<String?>(
              future: Get.find<AuthController>().getAuthToken(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.appPrimaryColor,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final authToken = snapshot.data;

                if (authToken == null || authToken.isEmpty) {
                  // Not logged in - prompt to login
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 64, color: AppColors.appPrimaryColor),
                          const SizedBox(height: 18),
                          Text(
                            '请登录以使用在线聊天',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '您需要登录才能与我们的支持团队聊​​天。',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.appPrimaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            ),
                            onPressed: () => Get.to(() => const SignInScreen(), transition: Transition.leftToRight),
                            child: Text('登录', style: GoogleFonts.poppins(color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Logged in - show chat UI
                return Column(
                  children: [
                    // Chat messages
                    Expanded(
                      child: chatController.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.appPrimaryColor,
                                strokeWidth: 2.5,
                              ),
                            )
                          : (chatController.chatData != null && chatController.chatData is List && (chatController.chatData as List).isNotEmpty)
                              ? ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                  itemCount: (chatController.chatData as List).length,
                                  itemBuilder: (context, index) {
                                    final message = (chatController.chatData as List)[index];
                                    // Skip null messages
                                    if (message == null) return const SizedBox.shrink();
                                    return _buildChatBubble(message);
                                  },
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: AppColors.appPrimaryColor.withAlpha(26), // ~0.1 opacity
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chat_bubble_outline,
                                          size: 40,
                                          color: AppColors.appPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '暂无消息',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '开始与我们的支持团队对话',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),

                    // Message input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8), // ~0.03 opacity
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  maxLines: null,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: '输入您的消息...',
                                    border: InputBorder.none,
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            chatController.isLoadingSend
                                ? Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: AppColors.appPrimaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : Material(
                                    color: AppColors.appPrimaryColor,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _sendMessage,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatBubble(dynamic message) {
    // Null safety check - return empty widget if message is null
    if (message == null || message is! Map) {
      return const SizedBox.shrink();
    }

    // Parse message data from API with null safety
    final bool isUserMessage = (message['sender_type']?.toString() ?? '') == 'user';
    final String messageText = (message['message'] ?? '').toString();
    final String createdAt = (message['created_at'] ?? '').toString();

    // Don't display empty messages
    if (messageText.isEmpty) {
      return const SizedBox.shrink();
    }

    // Format time
    String formattedTime = '';
    try {
      if (createdAt.isNotEmpty) {
        final DateTime dateTime = DateTime.parse(createdAt);
        formattedTime = DateFormat('hh:mm a').format(dateTime.toLocal());
      }
    } catch (e) {
      formattedTime = '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            // Admin/Support avatar
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUserMessage
                        ? AppColors.appPrimaryColor
                        : const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUserMessage ? 16 : 4),
                      bottomRight: Radius.circular(isUserMessage ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8), // ~0.03 opacity
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    messageText,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: isUserMessage ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                if (formattedTime.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      formattedTime,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (isUserMessage) ...[
            const SizedBox(width: 8),
            // User avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.appPrimaryColor.withAlpha(200),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/auth_controller.dart';
import '../core/connection/connection_controller.dart';
import '../platform/windows/connection_adapter.dart';
import '../ui/windows/windows_home_screen.dart';
import '../ui/windows/windows_app.dart';
import 'first_run_controller.dart';
import 'first_run_flow_page.dart';

class AppFlowRoot extends StatefulWidget {
  final ConnectionController controller;
  final WindowsConnectionAdapter adapter;
  final WindowsLaunchOptions launchOptions;

  const AppFlowRoot({
    super.key,
    required this.controller,
    required this.adapter,
    required this.launchOptions,
  });

  @override
  State<AppFlowRoot> createState() => _AppFlowRootState();
}

class _AppFlowRootState extends State<AppFlowRoot> {
  FirstRunController? _firstRunController;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final prefs = await SharedPreferences.getInstance();
    final authController = Get.find<AuthController>();
    final controller = FirstRunController(
      prefs: prefs,
      authController: authController,
    );
    await controller.init();
    if (!mounted) {
      return;
    }
    setState(() {
      _firstRunController = controller;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _firstRunController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AnimatedBuilder(
      animation: _firstRunController!,
      builder: (context, _) {
        final controller = _firstRunController!;
        if (!controller.isCompleted) {
          return FirstRunFlowPage(
            controller: controller,
            connectionController: widget.controller,
          );
        }
        return WindowsHomeScreen(
          controller: widget.controller,
          adapter: widget.adapter,
          launchOptions: widget.launchOptions,
        );
      },
    );
  }
}

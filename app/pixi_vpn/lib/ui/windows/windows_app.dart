import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_flow/app_flow_root.dart';
import '../../core/connection/connection_controller.dart';
import '../../core/connection/network_monitor.dart';
import '../../core/singbox/singbox_config_service.dart';
import '../../di_container.dart' as di;
import '../../platform/windows/connection_adapter.dart';
import '../../platform/windows/vpn_process.dart';

class WindowsLaunchOptions {
  final bool silent;
  final bool autoConnect;
  final bool noTray;
  final bool noCallbacks;

  const WindowsLaunchOptions({
    required this.silent,
    required this.autoConnect,
    required this.noTray,
    required this.noCallbacks,
  });
}

class WindowsApp extends StatefulWidget {
  final WindowsLaunchOptions launchOptions;

  const WindowsApp({super.key, required this.launchOptions});

  @override
  State<WindowsApp> createState() => _WindowsAppState();
}

class _WindowsAppState extends State<WindowsApp> {
  late final WindowsSingBoxService _vpnManager;
  late final WindowsConnectionAdapter _adapter;
  late final ConnectionController _controller;

  @override
  void initState() {
    super.initState();
    _vpnManager = WindowsSingBoxService(autoRestart: true);
    _adapter = WindowsConnectionAdapter(
      vpnManager: _vpnManager,
      singboxService: di.sl<SingboxConfigService>(),
    );
    _controller = ConnectionController(
      adapter: _adapter,
      networkMonitor: NetworkMonitor(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TSVPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: AppFlowRoot(
        controller: _controller,
        adapter: _adapter,
        launchOptions: widget.launchOptions,
      ),
    );
  }
}

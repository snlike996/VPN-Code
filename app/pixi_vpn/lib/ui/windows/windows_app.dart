import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/connection/connection_controller.dart';
import '../../core/connection/network_monitor.dart';
import '../../platform/windows/connection_adapter.dart';
import '../../platform/windows/vpn_process.dart';
import 'windows_home_screen.dart';

class WindowsLaunchOptions {
  final bool silent;
  final bool autoConnect;

  const WindowsLaunchOptions({
    required this.silent,
    required this.autoConnect,
  });
}

class WindowsApp extends StatefulWidget {
  final WindowsLaunchOptions launchOptions;

  const WindowsApp({super.key, required this.launchOptions});

  @override
  State<WindowsApp> createState() => _WindowsAppState();
}

class _WindowsAppState extends State<WindowsApp> {
  late final WindowsVpnManager _vpnManager;
  late final WindowsConnectionAdapter _adapter;
  late final ConnectionController _controller;

  @override
  void initState() {
    super.initState();
    _vpnManager = WindowsVpnManager(autoRestart: false);
    _adapter = WindowsConnectionAdapter(vpnManager: _vpnManager);
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
      home: WindowsHomeScreen(
        controller: _controller,
        adapter: _adapter,
        launchOptions: widget.launchOptions,
      ),
    );
  }
}

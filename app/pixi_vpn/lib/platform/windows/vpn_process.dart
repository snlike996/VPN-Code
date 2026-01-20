import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/proxy_node.dart';
import 'singbox_worker.dart';
import 'system_proxy.dart';

enum WindowsVpnState { stopped, starting, running, stopping, failed }

class WindowsSingBoxService {
  WindowsSingBoxService({this.autoRestart = false});

  final bool autoRestart;

  final ValueNotifier<WindowsVpnState> state =
      ValueNotifier<WindowsVpnState>(WindowsVpnState.stopped);
  final StreamController<String> _logs = StreamController<String>.broadcast();
  final StreamController<String> _notices =
      StreamController<String>.broadcast();
  final StreamController<void> _unexpectedExitController =
      StreamController<void>.broadcast();
  bool dnsProtectionEnabled = true;

  ProxyNode? _currentNode;
  int? _lastProxyPort;
  final SingBoxWorkerClient _worker = SingBoxWorkerClient.instance;
  bool _workerBound = false;

  Stream<String> get logs => _logs.stream;
  Stream<String> get notices => _notices.stream;
  Stream<void> get unexpectedExitStream => _unexpectedExitController.stream;
  ProxyNode? get currentNode => _currentNode;
  WindowsVpnState get status => state.value;
  bool get isRunning => state.value == WindowsVpnState.running;
  bool get isCrashed => state.value == WindowsVpnState.failed;
  ValueNotifier<SingBoxWorkerState> get workerState => _worker.state;

  Future<bool> isAdmin() async {
    await _worker.ensureInitialized(autoRestart: autoRestart);
    _bindWorker();
    return _worker.isAdmin();
  }

  Future<void> connect(
    ProxyNode node, {
    int? localProxyPort,
    ProxySettings? proxySettings,
  }) async {
    if (state.value == WindowsVpnState.starting ||
        state.value == WindowsVpnState.running) {
      return;
    }
    _currentNode = node;
    _lastProxyPort = localProxyPort;
    state.value = WindowsVpnState.starting;

    try {
      await _worker.ensureInitialized(autoRestart: autoRestart);
      _bindWorker();
      final settings = proxySettings ??
          ProxySettings(
            mode: ProxyMode.off.name,
            port: localProxyPort ?? 7890,
            restoreOnDisconnect: true,
          );
      _lastProxyPort = settings.port;
      final result = await _worker.startWithNode(
        node: node,
        proxySettings: settings,
        dnsProtectionEnabled: dnsProtectionEnabled,
      );
      if (result['ok'] != true) {
        throw StateError(result['error']?.toString() ?? 'start_failed');
      }
      state.value = WindowsVpnState.running;
    } catch (e) {
      state.value = WindowsVpnState.failed;
      _logs.add('VPN start failed: $e');
      rethrow;
    }
  }

  Future<void> connectWithConfig(
    String configContent, {
    ProxyNode? node,
    ProxySettings? proxySettings,
  }) async {
    if (state.value == WindowsVpnState.starting ||
        state.value == WindowsVpnState.running) {
      return;
    }

    _currentNode = node;
    state.value = WindowsVpnState.starting;

    try {
      await _worker.ensureInitialized(autoRestart: autoRestart);
      _bindWorker();
      final settings = proxySettings ??
          ProxySettings(
            mode: ProxyMode.off.name,
            port: _lastProxyPort ?? 7890,
            restoreOnDisconnect: true,
          );
      _lastProxyPort = settings.port;
      final result = await _worker.startWithConfig(
        configContent: configContent,
        proxySettings: settings,
        dnsProtectionEnabled: dnsProtectionEnabled,
        nodeRaw: node?.raw,
        nodeName: node?.displayName,
      );
      if (result['ok'] != true) {
        throw StateError(result['error']?.toString() ?? 'start_failed');
      }
      state.value = WindowsVpnState.running;
    } catch (e) {
      state.value = WindowsVpnState.failed;
      _logs.add('VPN start failed: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    state.value = WindowsVpnState.stopping;
    try {
      await _worker.ensureInitialized(autoRestart: autoRestart);
      _bindWorker();
      await _worker.stop();
    } catch (e) {
      _logs.add('VPN stop failed: $e');
    }
    state.value = WindowsVpnState.stopped;
  }

  Future<void> restart() async {
    final node = _currentNode;
    if (node == null) {
      return;
    }
    await disconnect();
    await connect(node, localProxyPort: _lastProxyPort);
  }

  Future<void> dispose() async {
    await disconnect();
    await _logs.close();
    await _notices.close();
    await _unexpectedExitController.close();
  }

  void _bindWorker() {
    if (_workerBound) {
      return;
    }
    _workerBound = true;
    _worker.logs.listen(_logs.add);
    _worker.notices.listen(_notices.add);
    _worker.unexpectedExitStream.listen((_) {
      _unexpectedExitController.add(null);
      state.value = WindowsVpnState.failed;
    });
  }

  // Worker receives raw config content, no file IO here.
}

@Deprecated('Use WindowsSingBoxService instead.')
class WindowsVpnManager extends WindowsSingBoxService {
  WindowsVpnManager({super.autoRestart});
}

// Worker handles process readiness; no local process state here.

import 'dart:async';
import 'dart:io';

import '../../core/connection/connection_controller.dart';
import '../../core/models/proxy_node.dart';
import '../../core/singbox/singbox_config_service.dart';
import 'pac_server.dart';
import 'system_proxy.dart';
import 'vpn_process.dart';

class WindowsConnectionAdapter implements ConnectionAdapter {
  WindowsConnectionAdapter({
    required this.vpnManager,
    this.singboxService,
  }) {
    _exitSubscription = vpnManager.unexpectedExitStream.listen((_) async {
      await _restoreProxy();
      await pacServer.stop();
      _unexpectedDisconnectController.add(null);
    });
    _noticeSubscription = vpnManager.notices.listen(_configNoticeController.add);
  }

  final WindowsSingBoxService vpnManager;
  final SingboxConfigService? singboxService;
  final WindowsSystemProxy systemProxy = WindowsSystemProxy();
  final PacServer pacServer = PacServer();

  ProxyMode proxyMode = ProxyMode.pac;
  bool restoreProxyOnDisconnect = true;
  int? localProxyPort;

  SystemProxySnapshot? _snapshot;
  StreamSubscription<void>? _exitSubscription;
  StreamSubscription<String>? _noticeSubscription;
  final StreamController<void> _unexpectedDisconnectController =
      StreamController<void>.broadcast();
  final StreamController<String> _configNoticeController =
      StreamController<String>.broadcast();

  List<SingboxConfigItem> availableConfigs = <SingboxConfigItem>[];
  SingboxConfigItem? activeConfig;
  String? lastConfigError;

  @override
  Stream<void> get onUnexpectedDisconnect =>
      _unexpectedDisconnectController.stream;

  Stream<String> get configNotices => _configNoticeController.stream;

  @override
  Future<void> connect(ProxyNode node) async {
    _snapshot ??= await systemProxy.readCurrentProxy();

    try {
      if (singboxService == null) {
        localProxyPort ??= await _pickFreePort();
        await vpnManager.connect(node, localProxyPort: localProxyPort!);
      } else {
        await _connectWithSingboxConfigs(node);
      }
      try {
        await _applyProxy();
      } catch (e) {
        await vpnManager.disconnect();
        await _restoreProxy();
        rethrow;
      }
    } catch (e) {
      await _restoreProxy();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await vpnManager.disconnect();
    await _restoreProxy();
    await pacServer.stop();
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _exitSubscription?.cancel();
    await _noticeSubscription?.cancel();
    await _unexpectedDisconnectController.close();
    await _configNoticeController.close();
  }

  Future<void> _applyProxy() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    if (proxyMode == ProxyMode.off) {
      return;
    }

    final port = localProxyPort ?? 7890;
    if (proxyMode == ProxyMode.global) {
      await systemProxy.setProxyGlobal(
        host: '127.0.0.1',
        port: port,
        snapshot: snapshot,
      );
      return;
    }

    final pacUrl = await pacServer.start(proxyPort: port);
    await systemProxy.setProxyPac(pacUrl: pacUrl, snapshot: snapshot);
  }

  Future<void> _restoreProxy() async {
    if (!restoreProxyOnDisconnect) {
      return;
    }
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }
    await systemProxy.setProxyOff(snapshot: snapshot);
  }

  Future<int> _pickFreePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  Future<void> _connectWithSingboxConfigs(ProxyNode node) async {
    final service = singboxService;
    if (service == null) {
      throw StateError('Sing-box config service not available');
    }

    final configs = await service.fetchConfigs();
    availableConfigs = configs;
    activeConfig = null;
    lastConfigError = null;

    if (configs.isEmpty) {
      throw StateError('No sing-box configs available');
    }

    for (final config in configs) {
      try {
        final result = await service.prepareConfig(config);
        localProxyPort = result.proxyPort ?? localProxyPort ?? 7890;
        await vpnManager.connectWithConfig(result.path, node: node);
        activeConfig = config;
        if (config != configs.first) {
          _configNoticeController.add(
            '已切换到备用配置：${config.name}',
          );
        }
        return;
      } catch (e) {
        lastConfigError = e.toString();
        continue;
      }
    }

    throw StateError(lastConfigError ?? 'All sing-box configs failed');
  }
}

import 'dart:async';
import 'dart:io';

import '../../core/connection/connection_controller.dart';
import '../../core/models/proxy_node.dart';
import '../../core/singbox/singbox_config_service.dart';
import 'pac_server.dart';
import 'system_proxy.dart';
import 'vpn_process.dart';
import 'singbox_worker.dart';

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
  final PacServer pacServer = PacServer();

  ProxyMode proxyMode = ProxyMode.pac;
  bool restoreProxyOnDisconnect = true;
  int? localProxyPort;

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
    try {
      if (singboxService == null) {
        localProxyPort ??= await _pickFreePort();
        final proxySettings = await _buildProxySettings(localProxyPort!);
        await vpnManager.connect(
          node,
          localProxyPort: localProxyPort!,
          proxySettings: proxySettings,
        );
      } else {
        await _connectWithSingboxConfigs(node);
      }
    } catch (e) {
      await _stopPacIfNeeded();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await vpnManager.disconnect();
    await _stopPacIfNeeded();
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _exitSubscription?.cancel();
    await _noticeSubscription?.cancel();
    await _unexpectedDisconnectController.close();
    await _configNoticeController.close();
  }

  Future<ProxySettings> _buildProxySettings(int port) async {
    if (proxyMode == ProxyMode.off) {
      return ProxySettings(
        mode: ProxyMode.off.name,
        port: port,
        restoreOnDisconnect: restoreProxyOnDisconnect,
      );
    }
    if (proxyMode == ProxyMode.global) {
      return ProxySettings(
        mode: ProxyMode.global.name,
        port: port,
        restoreOnDisconnect: restoreProxyOnDisconnect,
      );
    }
    final pacUrl = await pacServer.start(proxyPort: port);
    return ProxySettings(
      mode: ProxyMode.pac.name,
      port: port,
      pacUrl: pacUrl.toString(),
      restoreOnDisconnect: restoreProxyOnDisconnect,
    );
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
        final content = await service.resolveContent(config);
        localProxyPort =
            service.parseProxyPort(content) ?? localProxyPort ?? 7890;
        final proxySettings = await _buildProxySettings(localProxyPort!);
        await vpnManager.connectWithConfig(
          content,
          node: node,
          proxySettings: proxySettings,
        );
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

  Future<void> _stopPacIfNeeded() async {
    await pacServer.stop();
  }
}

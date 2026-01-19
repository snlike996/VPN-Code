import 'dart:async';
import 'dart:io';

import '../../core/connection/connection_controller.dart';
import '../../core/models/proxy_node.dart';
import 'pac_server.dart';
import 'system_proxy.dart';
import 'vpn_process.dart';

class WindowsConnectionAdapter implements ConnectionAdapter {
  WindowsConnectionAdapter({
    required this.vpnManager,
  }) {
    _exitSubscription = vpnManager.unexpectedExitStream.listen((_) async {
      await _restoreProxy();
      await pacServer.stop();
      _unexpectedDisconnectController.add(null);
    });
  }

  final WindowsVpnManager vpnManager;
  final WindowsSystemProxy systemProxy = WindowsSystemProxy();
  final PacServer pacServer = PacServer();

  ProxyMode proxyMode = ProxyMode.pac;
  bool restoreProxyOnDisconnect = true;
  int? localProxyPort;

  SystemProxySnapshot? _snapshot;
  StreamSubscription<void>? _exitSubscription;
  final StreamController<void> _unexpectedDisconnectController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get onUnexpectedDisconnect =>
      _unexpectedDisconnectController.stream;

  @override
  Future<void> connect(ProxyNode node) async {
    _snapshot ??= await systemProxy.readCurrentProxy();
    localProxyPort ??= await _pickFreePort();

    try {
      await vpnManager.connect(node, localProxyPort: localProxyPort!);
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
    await _unexpectedDisconnectController.close();
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
}

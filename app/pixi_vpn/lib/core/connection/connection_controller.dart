import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/proxy_node.dart';
import 'network_monitor.dart';

enum ConnectionStatus { idle, starting, connected, reconnecting, stopping }

abstract class ConnectionAdapter {
  Stream<void> get onUnexpectedDisconnect;
  Future<void> connect(ProxyNode node);
  Future<void> disconnect();
  Future<void> dispose();
}

class ConnectionController {
  ConnectionController({
    required this.adapter,
    required this.networkMonitor,
  }) {
    adapter.onUnexpectedDisconnect.listen((_) {
      if (_userInitiatedDisconnect) {
        return;
      }
      _scheduleReconnect();
    });

    networkMonitor.statusStream.listen((available) {
      _networkAvailable = available;
      networkAvailable.value = available;
      if (!available) {
        if (status.value == ConnectionStatus.connected ||
            status.value == ConnectionStatus.starting) {
          status.value = ConnectionStatus.reconnecting;
          _pendingReconnect = true;
          _notifications.add('网络中断，等待恢复…');
          adapter.disconnect();
        }
        return;
      }
      if (_pendingReconnect) {
        _pendingReconnect = false;
        _scheduleReconnect(immediate: true);
      }
    });
  }

  final ConnectionAdapter adapter;
  final NetworkMonitor networkMonitor;

  final ValueNotifier<ConnectionStatus> status =
      ValueNotifier<ConnectionStatus>(ConnectionStatus.idle);
  final ValueNotifier<bool> networkAvailable = ValueNotifier<bool>(true);
  final StreamController<String> _notifications =
      StreamController<String>.broadcast();

  Stream<String> get notifications => _notifications.stream;

  ProxyNode? _currentNode;
  bool _userInitiatedDisconnect = false;
  bool _pendingReconnect = false;
  bool _networkAvailable = true;
  int _attempt = 0;
  Timer? _reconnectTimer;

  Future<void> connect(ProxyNode node, {bool silent = false}) async {
    _currentNode = node;
    _userInitiatedDisconnect = false;
    _pendingReconnect = false;
    _attempt = 0;

    status.value = ConnectionStatus.starting;
    await networkMonitor.start();

    try {
      await adapter.connect(node);
      status.value = ConnectionStatus.connected;
    } catch (e) {
      if (_isAdminRequired(e)) {
        status.value = ConnectionStatus.idle;
        _notifications.add('需要管理员权限');
        rethrow;
      }
      _scheduleReconnect();
      rethrow;
    }
  }

  Future<void> disconnect({bool userInitiated = true}) async {
    _userInitiatedDisconnect = userInitiated;
    _pendingReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    status.value = ConnectionStatus.stopping;
    await adapter.disconnect();
    await networkMonitor.stop();
    status.value = ConnectionStatus.idle;
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await networkMonitor.dispose();
    await adapter.dispose();
    status.dispose();
    networkAvailable.dispose();
    await _notifications.close();
  }

  void _scheduleReconnect({bool immediate = false}) {
    if (_userInitiatedDisconnect || _currentNode == null) {
      return;
    }
    if (!_networkAvailable) {
      _pendingReconnect = true;
      status.value = ConnectionStatus.reconnecting;
      _notifications.add('网络中断，等待恢复…');
      return;
    }

    status.value = ConnectionStatus.reconnecting;
    _attempt += 1;
    final delaySeconds = immediate ? 0 : min(30, 1 << (_attempt - 1));
    if (_attempt == 1) {
      _notifications.add('网络波动，正在重连…');
    } else if (_attempt % 2 == 0) {
      _notifications.add('正在重连（第$_attempt次）');
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_userInitiatedDisconnect || _currentNode == null) {
        return;
      }
      try {
        status.value = ConnectionStatus.starting;
        await adapter.connect(_currentNode!);
        status.value = ConnectionStatus.connected;
        _attempt = 0;
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  void updateNode(ProxyNode node) {
    _currentNode = node;
  }

  bool _isAdminRequired(Object error) {
    final lower = error.toString().toLowerCase();
    return lower.contains('admin_required') ||
        lower.contains('administrator privileges required');
  }
}

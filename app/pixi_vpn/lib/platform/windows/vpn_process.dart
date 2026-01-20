import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/models/proxy_node.dart';
import 'core_binary.dart';
import 'privilege_helper.dart';
import 'firewall.dart';
import 'dns_protect.dart';
import 'tun_adapter.dart';
import 'vpn_config_builder.dart';

enum WindowsVpnState { stopped, starting, running, stopping, failed }

class WindowsVpnManager {
  WindowsVpnManager({this.autoRestart = false});

  final bool autoRestart;
  static const int _maxRestartAttempts = 3;
  static const Duration _restartDelay = Duration(seconds: 2);

  final ValueNotifier<WindowsVpnState> state =
      ValueNotifier<WindowsVpnState>(WindowsVpnState.stopped);
  final StreamController<String> _logs = StreamController<String>.broadcast();
  final StreamController<void> _unexpectedExitController =
      StreamController<void>.broadcast();
  final WindowsTunAdapter _tunAdapter = WindowsTunAdapter();
  final WindowsFirewall _firewall = WindowsFirewall();
  final WindowsDnsProtect _dnsProtect = WindowsDnsProtect();
  bool dnsProtectionEnabled = true;

  Process? _process;
  ProxyNode? _currentNode;
  String? _currentConfigPath;
  bool _shouldRestart = false;
  int _restartAttempts = 0;
  bool _userInitiatedStop = false;

  Stream<String> get logs => _logs.stream;
  Stream<void> get unexpectedExitStream => _unexpectedExitController.stream;
  ProxyNode? get currentNode => _currentNode;

  Future<void> connect(ProxyNode node, {int? localProxyPort}) async {
    if (!WindowsPrivilege.isAdmin()) {
      throw StateError('Administrator privileges required for VPN/TUN');
    }

    if (state.value == WindowsVpnState.starting ||
        state.value == WindowsVpnState.running) {
      return;
    }

    _shouldRestart = autoRestart;
    _userInitiatedStop = false;
    _currentNode = node;
    _currentConfigPath = null;
    state.value = WindowsVpnState.starting;

    try {
      await _tunAdapter.ensureReady();
      await _firewall.applyRules();
      final coreFile = await WindowsCoreBinary.ensureCoreBinary();
      final config = WindowsVpnConfigBuilder.build(
        node,
        localProxyPort: localProxyPort,
      );
      final configPath = await _writeConfig(config);

      _process = await Process.start(
        coreFile.path,
        ['run', '-c', configPath],
        workingDirectory: coreFile.parent.path,
        runInShell: false,
      );

      _process?.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_logs.add);
      _process?.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_logs.add);

      _process?.exitCode.then(_handleExit);
      state.value = WindowsVpnState.running;
      if (dnsProtectionEnabled) {
        try {
          await _dnsProtect.enable();
        } catch (e) {
          _logs.add('DNS protection failed: $e');
        }
      }
    } catch (e) {
      state.value = WindowsVpnState.failed;
      _logs.add('VPN start failed: $e');
      rethrow;
    }
  }

  Future<void> connectWithConfig(String configPath, {ProxyNode? node}) async {
    if (!WindowsPrivilege.isAdmin()) {
      throw StateError('Administrator privileges required for VPN/TUN');
    }

    if (state.value == WindowsVpnState.starting ||
        state.value == WindowsVpnState.running) {
      return;
    }

    _shouldRestart = autoRestart;
    _userInitiatedStop = false;
    _currentNode = node;
    _currentConfigPath = configPath;
    state.value = WindowsVpnState.starting;

    try {
      await _tunAdapter.ensureReady();
      await _firewall.applyRules();
      final coreFile = await WindowsCoreBinary.ensureCoreBinary();

      _process = await Process.start(
        coreFile.path,
        ['run', '-c', configPath],
        workingDirectory: coreFile.parent.path,
        runInShell: false,
      );

      _process?.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_logs.add);
      _process?.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_logs.add);

      _process?.exitCode.then(_handleExit);
      state.value = WindowsVpnState.running;
      if (dnsProtectionEnabled) {
        try {
          await _dnsProtect.enable();
        } catch (e) {
          _logs.add('DNS protection failed: $e');
        }
      }
    } catch (e) {
      state.value = WindowsVpnState.failed;
      _logs.add('VPN start failed: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _shouldRestart = false;
    _userInitiatedStop = true;
    _restartAttempts = 0;

    if (_process == null) {
      state.value = WindowsVpnState.stopped;
      return;
    }

    state.value = WindowsVpnState.stopping;
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
    if (dnsProtectionEnabled) {
      try {
        await _dnsProtect.restore();
      } catch (e) {
        _logs.add('DNS restore failed: $e');
      }
    }
    await _firewall.clearRules();
    state.value = WindowsVpnState.stopped;
  }

  Future<void> dispose() async {
    _shouldRestart = false;
    _restartAttempts = 0;
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
    await _logs.close();
    await _unexpectedExitController.close();
  }

  Future<String> _writeConfig(String content) async {
    final supportDir = await getApplicationSupportDirectory();
    final configDir = Directory('${supportDir.path}\\config');
    await configDir.create(recursive: true);
    final configFile = File('${configDir.path}\\sing-box.json');
    await configFile.writeAsString(content, flush: true);
    return configFile.path;
  }

  void _handleExit(int exitCode) {
    _process = null;

    if (!_userInitiatedStop) {
      _unexpectedExitController.add(null);
    }

    if (_shouldRestart && _currentNode != null) {
      if (_restartAttempts >= _maxRestartAttempts) {
        _logs.add('VPN restart limit reached');
        state.value = WindowsVpnState.failed;
        return;
      }
      _restartAttempts += 1;
      _logs.add('VPN exited ($exitCode), restarting...');
      Future<void>.delayed(_restartDelay, () async {
        if (!_shouldRestart || _currentNode == null) {
          return;
        }
        try {
          if (_currentConfigPath != null) {
            await connectWithConfig(_currentConfigPath!, node: _currentNode);
          } else {
            await connect(_currentNode!);
          }
        } catch (_) {
          // connect handles state/logging
        }
      });
      return;
    }

    if (dnsProtectionEnabled) {
      _dnsProtect.restore().catchError((e) {
        _logs.add('DNS restore failed: $e');
      });
    }
    state.value = WindowsVpnState.stopped;
  }
}

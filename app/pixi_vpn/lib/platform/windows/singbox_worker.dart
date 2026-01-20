import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/models/proxy_node.dart';
import 'core_binary.dart';
import 'dns_protect.dart';
import 'firewall.dart';
import 'admin_check.dart';
import 'system_proxy.dart';
import 'tun_adapter.dart';
import 'vpn_config_builder.dart';

enum SingBoxWorkerState { idle, testing, running, stopping, crashed }

class SingBoxWorkerClient {
  SingBoxWorkerClient._();

  static final SingBoxWorkerClient instance = SingBoxWorkerClient._();

  final ValueNotifier<SingBoxWorkerState> state =
      ValueNotifier<SingBoxWorkerState>(SingBoxWorkerState.idle);
  final StreamController<String> _logs = StreamController<String>.broadcast();
  final StreamController<String> _notices =
      StreamController<String>.broadcast();
  final StreamController<void> _unexpectedExit =
      StreamController<void>.broadcast();

  SendPort? _sendPort;
  ReceivePort? _receivePort;
  int _requestId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  bool _autoRestart = false;
  Completer<void>? _readyCompleter;

  Stream<String> get logs => _logs.stream;
  Stream<String> get notices => _notices.stream;
  Stream<void> get unexpectedExitStream => _unexpectedExit.stream;

  Future<void> ensureInitialized({required bool autoRestart}) async {
    if (_sendPort != null) {
      _autoRestart = autoRestart;
      return;
    }
    if (_readyCompleter != null) {
      await _readyCompleter!.future;
      return;
    }
    _autoRestart = autoRestart;
    _readyCompleter = Completer<void>();
    _receivePort = ReceivePort();
    _receivePort!.listen(_handleMessage);
    final token = ServicesBinding.rootIsolateToken;
    await Isolate.spawn(
      _singBoxWorkerMain,
      {
        'sendPort': _receivePort!.sendPort,
        'token': token,
        'autoRestart': autoRestart,
      },
      debugName: 'singbox_worker',
    );
    await _readyCompleter!.future;
  }

  Future<bool> isAdmin() async {
    final response = await _request({'cmd': 'admin_check'});
    return response['ok'] == true && response['isAdmin'] == true;
  }

  Future<Map<String, dynamic>> startWithNode({
    required ProxyNode node,
    required ProxySettings proxySettings,
    required bool dnsProtectionEnabled,
  }) async {
    return _request({
      'cmd': 'start_node',
      'nodeRaw': node.raw,
      'nodeName': node.displayName,
      'proxySettings': proxySettings.toJson(),
      'dnsProtectionEnabled': dnsProtectionEnabled,
      'autoRestart': _autoRestart,
    });
  }

  Future<Map<String, dynamic>> startWithConfig({
    required String configContent,
    required ProxySettings proxySettings,
    required bool dnsProtectionEnabled,
    String? nodeRaw,
    String? nodeName,
  }) async {
    return _request({
      'cmd': 'start_config',
      'configContent': configContent,
      'nodeRaw': nodeRaw,
      'nodeName': nodeName,
      'proxySettings': proxySettings.toJson(),
      'dnsProtectionEnabled': dnsProtectionEnabled,
      'autoRestart': _autoRestart,
    });
  }

  Future<Map<String, dynamic>> stop() async {
    return _request({'cmd': 'stop'});
  }

  Future<SingboxTestResult> testNode({
    required ProxyNode node,
    required Duration timeout,
  }) async {
    final response = await _request(
      {
        'cmd': 'test',
        'nodeRaw': node.raw,
        'nodeName': node.displayName,
        'timeoutSeconds': timeout.inSeconds,
      },
      timeout: timeout + const Duration(seconds: 45),
    );
    return SingboxTestResult.fromJson(response);
  }

  Future<void> cancelPendingTests() async {
    await _request({'cmd': 'cancel_tests'}, timeout: const Duration(seconds: 5));
  }

  Future<Map<String, dynamic>> _request(
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final sendPort = _sendPort;
    if (sendPort == null) {
      throw StateError('SingBox worker not initialized');
    }
    final id = ++_requestId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    sendPort.send({
      'type': 'request',
      'id': id,
      ...payload,
    });
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(id);
        return {
          'ok': false,
          'error': 'worker_timeout',
          'state': state.value.name,
        };
      },
    );
  }

  void _handleMessage(dynamic message) {
    if (message is! Map) {
      return;
    }
    final type = message['type'];
    if (type == 'ready') {
      _sendPort = message['sendPort'] as SendPort?;
      _readyCompleter?.complete();
      return;
    }
    if (type == 'response') {
      final id = message['id'] as int?;
      if (id != null) {
        _pending.remove(id)?.complete(Map<String, dynamic>.from(message));
      }
      return;
    }
    if (type == 'event') {
      final event = message['event']?.toString();
      if (event == 'log') {
        _logs.add(message['message']?.toString() ?? '');
      } else if (event == 'notice') {
        _notices.add(message['message']?.toString() ?? '');
      } else if (event == 'unexpected_exit') {
        _unexpectedExit.add(null);
      } else if (event == 'state') {
        final name = message['state']?.toString();
        final next = SingBoxWorkerState.values
            .firstWhere((e) => e.name == name, orElse: () => state.value);
        state.value = next;
      }
    }
  }
}

class ProxySettings {
  final String mode;
  final int port;
  final String? pacUrl;
  final bool restoreOnDisconnect;

  const ProxySettings({
    required this.mode,
    required this.port,
    required this.restoreOnDisconnect,
    this.pacUrl,
  });

  factory ProxySettings.fromJson(Map<String, dynamic> json) {
    return ProxySettings(
      mode: (json['mode'] ?? ProxyMode.off.name).toString(),
      port: (json['port'] as int?) ?? 7890,
      pacUrl: json['pacUrl']?.toString(),
      restoreOnDisconnect: json['restoreOnDisconnect'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'port': port,
      'pacUrl': pacUrl,
      'restoreOnDisconnect': restoreOnDisconnect,
    };
  }
}

class SingboxTestResult {
  final bool success;
  final int? latencyMs;
  final String? error;
  final int? exitCode;

  SingboxTestResult({
    required this.success,
    required this.latencyMs,
    required this.error,
    required this.exitCode,
  });

  factory SingboxTestResult.fromJson(Map<String, dynamic> json) {
    return SingboxTestResult(
      success: json['ok'] == true && json['success'] == true,
      latencyMs: json['latencyMs'] as int?,
      error: json['error']?.toString(),
      exitCode: json['exitCode'] as int?,
    );
  }
}

void _singBoxWorkerMain(Map<String, dynamic> init) {
  final sendPort = init['sendPort'] as SendPort?;
  final token = init['token'] as RootIsolateToken?;
  if (token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }
  final autoRestart = init['autoRestart'] == true;
  final commandPort = ReceivePort();
  sendPort?.send({'type': 'ready', 'sendPort': commandPort.sendPort});
  final worker = _SingBoxWorker(sendPort, autoRestart: autoRestart);
  commandPort.listen((message) async {
    try {
      await worker.handle(message);
    } catch (e, st) {
      worker.log('worker_exception: $e');
      worker.log(st.toString());
    }
  });
}

class _SingBoxWorker {
  _SingBoxWorker(this._sendPort, {required bool autoRestart})
      : _autoRestart = autoRestart;

  final SendPort? _sendPort;
  final WindowsTunAdapter _tunAdapter = WindowsTunAdapter();
  final WindowsFirewall _firewall = WindowsFirewall();
  final WindowsDnsProtect _dnsProtect = WindowsDnsProtect();
  final WindowsSystemProxy _systemProxy = WindowsSystemProxy();
  final bool _autoRestart;

  SingBoxWorkerState _state = SingBoxWorkerState.idle;
  Process? _process;
  bool _userInitiatedStop = false;
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 3;
  static const Duration _restartBaseDelay = Duration(seconds: 2);
  SystemProxySnapshot? _proxySnapshot;
  ProxySettings? _proxySettings;
  bool _dnsProtectionEnabled = true;
  String? _logFilePath;
  IOSink? _workerLogSink;
  Completer<bool>? _readyCompleter;
  String? _currentConfigPath;
  final Queue<_TestTask> _testQueue = Queue<_TestTask>();
  int _activeTests = 0;
  int _testGeneration = 0;
  static const int _maxConcurrentTests = 3;

  Future<void> handle(dynamic message) async {
    if (message is! Map) {
      return;
    }
    final type = message['type'];
    if (type != 'request') {
      return;
    }
    final id = message['id'] as int?;
    if (id == null) {
      return;
    }
    final cmd = message['cmd']?.toString();
    try {
      if (cmd == 'admin_check') {
        _sendResponse(id, {'ok': true, 'isAdmin': WindowsAdminCheck.isAdmin()});
        return;
      }
      if (cmd == 'start_node') {
        await _handleStartNode(id, message);
        return;
      }
      if (cmd == 'start_config') {
        await _handleStartConfig(id, message);
        return;
      }
      if (cmd == 'cancel_tests') {
        _cancelPendingTests();
        _sendResponse(id, {'ok': true});
        return;
      }
      if (cmd == 'stop') {
        await _handleStop(id);
        return;
      }
      if (cmd == 'test') {
        await _handleTest(id, message);
        return;
      }
      _sendResponse(id, {'ok': false, 'error': 'unknown_command'});
    } catch (e, st) {
      log('command_error[$cmd]: $e');
      log(st.toString());
      _sendResponse(id, {'ok': false, 'error': e.toString()});
    }
  }

  Future<void> _handleStartNode(int id, Map message) async {
    if (_state == SingBoxWorkerState.testing) {
      _cancelPendingTests();
      if (_activeTests > 0) {
        _sendIgnored(id);
        return;
      }
    }
    if (!_canStart()) {
      _sendIgnored(id);
      return;
    }
    _setState(SingBoxWorkerState.running);
    _userInitiatedStop = false;
    _restartAttempts = 0;
    _dnsProtectionEnabled = message['dnsProtectionEnabled'] == true;
    _proxySettings = ProxySettings.fromJson(
      Map<String, dynamic>.from(message['proxySettings'] as Map? ?? {}),
    );

    await _initWorkerLog();
    log('start_node requested');
    try {
      await _tunAdapter.ensureReady();
      await _firewall.applyRules();
      final configPath = await _writeNodeConfig(
        message['nodeRaw']?.toString() ?? '',
        localProxyPort: _proxySettings?.port,
      );
      _currentConfigPath = configPath;
      final core = await WindowsCoreBinary.ensureCoreBinary();
      await _startProcess(core.path, configPath);
      await _waitForReady();
      await _applyProxy();
      if (_dnsProtectionEnabled) {
        try {
          await _dnsProtect.enable();
        } catch (e) {
          log('dns_protect_failed: $e');
        }
      }
      _sendResponse(id, {'ok': true, 'state': _state.name});
    } catch (e, st) {
      log('start_node_failed: $e');
      log(st.toString());
      _setState(SingBoxWorkerState.crashed);
      _sendResponse(id, {'ok': false, 'error': e.toString(), 'state': _state.name});
    }
  }

  Future<void> _handleStartConfig(int id, Map message) async {
    if (_state == SingBoxWorkerState.testing) {
      _cancelPendingTests();
      if (_activeTests > 0) {
        _sendIgnored(id);
        return;
      }
    }
    if (!_canStart()) {
      _sendIgnored(id);
      return;
    }
    _setState(SingBoxWorkerState.running);
    _userInitiatedStop = false;
    _restartAttempts = 0;
    _dnsProtectionEnabled = message['dnsProtectionEnabled'] == true;
    _proxySettings = ProxySettings.fromJson(
      Map<String, dynamic>.from(message['proxySettings'] as Map? ?? {}),
    );

    await _initWorkerLog();
    log('start_config requested');
    try {
      await _tunAdapter.ensureReady();
      await _firewall.applyRules();
      final content = message['configContent']?.toString() ?? '';
      final configPath = await _writeConfigContent(content);
      _currentConfigPath = configPath;
      final core = await WindowsCoreBinary.ensureCoreBinary();
      await _startProcess(core.path, configPath);
      await _waitForReady();
      await _applyProxy();
      if (_dnsProtectionEnabled) {
        try {
          await _dnsProtect.enable();
        } catch (e) {
          log('dns_protect_failed: $e');
        }
      }
      _sendResponse(id, {'ok': true, 'state': _state.name});
    } catch (e, st) {
      log('start_config_failed: $e');
      log(st.toString());
      _setState(SingBoxWorkerState.crashed);
      _sendResponse(id, {'ok': false, 'error': e.toString(), 'state': _state.name});
    }
  }

  Future<void> _handleStop(int id) async {
    if (_state != SingBoxWorkerState.running &&
        _state != SingBoxWorkerState.crashed) {
      _sendIgnored(id);
      return;
    }
    _setState(SingBoxWorkerState.stopping);
    _userInitiatedStop = true;
    _currentConfigPath = null;
    _cancelPendingTests();
    log('stop requested');
    try {
      final proc = _process;
      if (proc != null) {
        proc.kill(ProcessSignal.sigterm);
      }
      _process = null;
      await _restoreProxy();
      if (_dnsProtectionEnabled) {
        try {
          await _dnsProtect.restore();
        } catch (e) {
          log('dns_restore_failed: $e');
        }
      }
      await _firewall.clearRules();
    } catch (e, st) {
      log('stop_failed: $e');
      log(st.toString());
    }
    _setState(SingBoxWorkerState.idle);
    _sendResponse(id, {'ok': true, 'state': _state.name});
  }

  Future<void> _handleTest(int id, Map message) async {
    if (!_canTest()) {
      _sendIgnored(id);
      return;
    }
    final nodeRaw = message['nodeRaw']?.toString() ?? '';
    final timeoutSeconds = message['timeoutSeconds'] as int? ?? 8;
    _testQueue.add(
      _TestTask(
        id: id,
        nodeRaw: nodeRaw,
        timeout: Duration(seconds: timeoutSeconds),
        generation: _testGeneration,
      ),
    );
    if (_state == SingBoxWorkerState.idle) {
      _setState(SingBoxWorkerState.testing);
    }
    _pumpTestQueue();
  }

  bool _canStart() {
    return _state == SingBoxWorkerState.idle ||
        _state == SingBoxWorkerState.crashed;
  }

  bool _canTest() {
    return _state == SingBoxWorkerState.idle;
  }

  void _sendResponse(int id, Map<String, dynamic> payload) {
    _sendPort?.send({'type': 'response', 'id': id, ...payload});
  }

  void _sendIgnored(int id) {
    _sendResponse(id, {
      'ok': false,
      'ignored': true,
      'state': _state.name,
      'error': 'busy',
    });
  }

  void _setState(SingBoxWorkerState next) {
    _state = next;
    _sendPort?.send({'type': 'event', 'event': 'state', 'state': next.name});
  }

  void log(String message) {
    try {
      _workerLogSink?.writeln(message);
    } catch (_) {}
    try {
      _sendPort?.send({'type': 'event', 'event': 'log', 'message': message});
    } catch (_) {}
  }

  Future<void> _initWorkerLog() async {
    if (_workerLogSink != null) {
      return;
    }
    final dir = await _resolveLogDir();
    final file = File('${dir.path}\\singbox_worker.log');
    _workerLogSink = file.openWrite(mode: FileMode.append);
    _workerLogSink?.writeln('--- ${DateTime.now().toIso8601String()} start ---');
  }

  void _cancelPendingTests() {
    _testGeneration += 1;
    while (_testQueue.isNotEmpty) {
      final task = _testQueue.removeFirst();
      _sendResponse(task.id, {
        'ok': false,
        'error': 'canceled',
        'state': _state.name,
      });
    }
    if (_activeTests == 0 && _state == SingBoxWorkerState.testing) {
      _setState(SingBoxWorkerState.idle);
    }
  }

  void _pumpTestQueue() {
    if (_activeTests > 0) {
      return;
    }
    if (_testQueue.isEmpty) {
      if (_state == SingBoxWorkerState.testing) {
        _setState(SingBoxWorkerState.idle);
      }
      return;
    }
    final count = _testQueue.length < _maxConcurrentTests
        ? _testQueue.length
        : _maxConcurrentTests;
    for (var i = 0; i < count; i++) {
      final task = _testQueue.removeFirst();
      _activeTests += 1;
      Future<void>.microtask(() async {
        await _runTestTask(task);
      });
    }
  }

  Future<void> _runTestTask(_TestTask task) async {
    try {
      await _initWorkerLog();
      log('test requested');
      if (task.generation != _testGeneration) {
        _sendResponse(task.id, {'ok': false, 'error': 'canceled'});
        return;
      }
      final configPath = await _writeTestConfig(task.nodeRaw);
      final core = await WindowsCoreBinary.ensureCoreBinary();
      final result = await _runSingboxTest(core.path, configPath, task.timeout);
      if (task.generation != _testGeneration) {
        _sendResponse(task.id, {'ok': false, 'error': 'canceled'});
        return;
      }
      _sendResponse(task.id, {
        'ok': true,
        'success': result.success,
        'latencyMs': result.latencyMs,
        'error': result.error,
        'exitCode': result.exitCode,
      });
    } catch (e, st) {
      log('test_failed: $e');
      log(st.toString());
      _sendResponse(task.id, {'ok': false, 'error': e.toString()});
    } finally {
      _activeTests = _activeTests > 0 ? _activeTests - 1 : 0;
      if (_activeTests == 0) {
        _pumpTestQueue();
      }
    }
  }

  Future<Directory> _resolveLogDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory('${supportDir.path}\\logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    _logFilePath ??= '${logDir.path}\\sing-box.log';
    return logDir;
  }

  Future<String> _writeNodeConfig(String raw, {int? localProxyPort}) async {
    final logPath = await _ensureSingboxLogPath();
    final config = WindowsVpnConfigBuilder.build(
      ProxyNode(id: 'node', type: 'custom', name: '', raw: raw),
      localProxyPort: localProxyPort,
      logOutputPath: logPath,
    );
    return _writeConfigFile(config, 'sing-box.json');
  }

  Future<String> _writeTestConfig(String raw) async {
    final logPath = await _ensureSingboxLogPath();
    final config = WindowsVpnConfigBuilder.buildTestConfig(
      ProxyNode(id: 'node', type: 'test', name: '', raw: raw),
      logOutputPath: logPath,
    );
    return _writeConfigFile(config, 'sing-box-test.json');
  }

  Future<String> _writeConfigContent(String content) async {
    final logPath = await _ensureSingboxLogPath();
    final normalized = _injectLogConfig(content, logPath);
    return _writeConfigFile(normalized, 'sing-box.json');
  }

  Future<String> _writeConfigFile(String content, String name) async {
    final supportDir = await getApplicationSupportDirectory();
    final configDir = Directory('${supportDir.path}\\config');
    await configDir.create(recursive: true);
    final file = File('${configDir.path}\\$name');
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  Future<String> _ensureSingboxLogPath() async {
    await _resolveLogDir();
    return _logFilePath ?? 'sing-box.log';
  }

  String _injectLogConfig(String content, String logPath) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('config_error');
      }
      final logConfig = Map<String, dynamic>.from(decoded['log'] as Map? ?? {});
      logConfig['level'] = 'debug';
      logConfig['output'] = logPath;
      decoded['log'] = logConfig;
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      throw StateError('config_error');
    }
  }

  Future<void> _startProcess(String exePath, String configPath) async {
    final configDir = File(configPath).parent.path;
    _readyCompleter = Completer<bool>();
    _process = await Process.start(
      exePath,
      ['run', '-c', configPath],
      workingDirectory: configDir,
      runInShell: false,
    );
    _process?.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _handleLogLine('[stdout] $line'));
    _process?.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _handleLogLine('[stderr] $line'));
    _process?.exitCode.then(_handleExit);
  }

  Future<void> _waitForReady() async {
    final proc = _process;
    if (proc == null) {
      throw StateError('sing-box not started');
    }
    final readyFuture = _readyCompleter?.future ?? Future<bool>.value(false);
    final completed = await Future.any<bool>([
      readyFuture,
      proc.exitCode.then((_) => false),
    ]).timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
    if (!completed) {
      proc.kill();
      throw StateError('sing-box not ready');
    }
  }

  void _handleLogLine(String line) {
    log(line);
    final lower = line.toLowerCase();
    if (lower.contains('started') ||
        lower.contains('tun') && lower.contains('listen') ||
        lower.contains('inbound') && lower.contains('listening')) {
      if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
        _readyCompleter?.complete(true);
      }
    }
  }

  Future<void> _applyProxy() async {
    final settings = _proxySettings;
    if (settings == null || settings.mode == ProxyMode.off.name) {
      return;
    }
    _proxySnapshot ??= await _systemProxy.readCurrentProxy();
    final snapshot = _proxySnapshot;
    if (snapshot == null) {
      return;
    }
    if (settings.mode == ProxyMode.global.name) {
      await _systemProxy.setProxyGlobal(
        host: '127.0.0.1',
        port: settings.port,
        snapshot: snapshot,
      );
      return;
    }
    if (settings.mode == ProxyMode.pac.name) {
      final pacUrl = settings.pacUrl;
      if (pacUrl == null || pacUrl.isEmpty) {
        throw StateError('PAC url missing');
      }
      await _systemProxy.setProxyPac(
        pacUrl: Uri.parse(pacUrl),
        snapshot: snapshot,
      );
    }
  }

  Future<void> _restoreProxy() async {
    final settings = _proxySettings;
    if (settings == null || !settings.restoreOnDisconnect) {
      return;
    }
    final snapshot = _proxySnapshot;
    if (snapshot == null) {
      return;
    }
    await _systemProxy.setProxyOff(snapshot: snapshot);
  }

  void _handleExit(int exitCode) {
    try {
      _process = null;
      if (_userInitiatedStop) {
        _setState(SingBoxWorkerState.idle);
        return;
      }
      if (_autoRestart) {
        if (_restartAttempts >= _maxRestartAttempts) {
          log('restart_limit_reached');
          _setState(SingBoxWorkerState.crashed);
          _sendPort?.send({'type': 'event', 'event': 'unexpected_exit'});
          return;
        }
        _restartAttempts += 1;
        log('process_exit=$exitCode restarting');
        final delaySeconds =
            _restartBaseDelay.inSeconds * (1 << (_restartAttempts - 1));
        Future<void>.delayed(Duration(seconds: delaySeconds), () async {
          try {
            if (_state != SingBoxWorkerState.running) {
              return;
            }
            final configPath = _currentConfigPath;
            if (configPath == null || _proxySettings == null) {
              return;
            }
            final core = await WindowsCoreBinary.ensureCoreBinary();
            await _startProcess(core.path, configPath);
            await _waitForReady();
            await _applyProxy();
          } catch (e) {
            log('auto_restart_failed: $e');
          }
        });
        return;
      }
      _setState(SingBoxWorkerState.crashed);
      _sendPort?.send({'type': 'event', 'event': 'unexpected_exit'});
    } catch (e) {
      log('exit_handler_failed: $e');
    }
  }

  Future<_SingboxResult> _runSingboxTest(
    String exePath,
    String configPath,
    Duration timeout,
  ) async {
    final args = [
      'test',
      '-c',
      configPath,
      '--timeout',
      '${timeout.inSeconds}s',
    ];
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    int? exitCode;
    try {
      final proc = await Process.start(
        exePath,
        args,
        workingDirectory: File(configPath).parent.path,
        runInShell: false,
      );
      proc.stdout.transform(utf8.decoder).listen(stdoutBuffer.write);
      proc.stderr.transform(utf8.decoder).listen(stderrBuffer.write);
      exitCode = await proc.exitCode.timeout(
        timeout,
        onTimeout: () {
          proc.kill();
          return -1;
        },
      );
    } catch (e) {
      return _SingboxResult(
        success: false,
        latencyMs: null,
        error: 'process_error: $e',
        exitCode: exitCode,
      );
    }
    final output = '${stdoutBuffer.toString()}\n${stderrBuffer.toString()}';
    final latency = _parseLatency(output);
    final success = exitCode == 0;
    String? error;
    if (success) {
      error = latency == null ? 'latency_missing' : null;
    } else if (exitCode == -1) {
      error = 'timeout';
    } else {
      error = _inferSingboxError(output);
    }
    return _SingboxResult(
      success: success,
      latencyMs: latency,
      error: error,
      exitCode: exitCode,
    );
  }

  int? _parseLatency(String output) {
    final match =
        RegExp(r'latency\\s*[:=]\\s*(\\d+)\\s*ms', caseSensitive: false)
            .firstMatch(output);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    final fallback =
        RegExp(r'(\\d+)\\s*ms', caseSensitive: false).firstMatch(output);
    if (fallback != null) {
      return int.tryParse(fallback.group(1) ?? '');
    }
    return null;
  }

  String _inferSingboxError(String output) {
    final lower = output.toLowerCase();
    if (lower.contains('timeout')) {
      return 'timeout';
    }
    if (lower.contains('handshake') || lower.contains('tls')) {
      return 'handshake_failed';
    }
    if (lower.contains('config') || lower.contains('parse')) {
      return 'config_error';
    }
    return 'unavailable';
  }
}

class _SingboxResult {
  final bool success;
  final int? latencyMs;
  final String? error;
  final int? exitCode;

  _SingboxResult({
    required this.success,
    required this.latencyMs,
    required this.error,
    required this.exitCode,
  });
}

class _TestTask {
  final int id;
  final String nodeRaw;
  final Duration timeout;
  final int generation;

  _TestTask({
    required this.id,
    required this.nodeRaw,
    required this.timeout,
    required this.generation,
  });
}

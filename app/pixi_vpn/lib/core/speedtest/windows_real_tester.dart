import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/proxy_node.dart';
import '../../platform/windows/core_binary.dart';
import '../../platform/windows/vpn_config_builder.dart';

class SpeedTestResult {
  final bool available;
  final int? tcpMs;
  final int? tlsMs;
  final int scoreMs;
  final int? jitterMs;
  final DateTime testedAt;
  final String? error;
  final int? exitCode;

  SpeedTestResult({
    required this.available,
    required this.tcpMs,
    required this.tlsMs,
    required this.scoreMs,
    required this.jitterMs,
    required this.testedAt,
    required this.error,
    required this.exitCode,
  });
}

class WindowsRealTester {
  static const Duration _timeout = Duration(seconds: 5);
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const int _maxConcurrency = 5;

  static Future<List<ProxyNode>> testAndSort(
    List<ProxyNode> nodes, {
    Duration timeout = _timeout,
  }) async {
    if (nodes.isEmpty) {
      return nodes;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final working = nodes.toList();
    final toTest = <ProxyNode>[];

    for (final node in working) {
      final cached = _readCache(prefs, node.raw, now);
      if (cached != null) {
        _applyResult(node, cached);
      } else {
        toTest.add(node);
      }
    }

    if (toTest.isNotEmpty) {
      await _runWithConcurrency(toTest, _maxConcurrency, (node) async {
        final result = await testNode(node, timeout: timeout);
        _applyResult(node, result);
        await _writeCache(prefs, node.raw, result);
      });
    }

    working.sort(_compareNodes);
    return working;
  }

  static Future<void> clearCacheFor(List<ProxyNode> nodes) async {
    if (nodes.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    for (final node in nodes) {
      await prefs.remove(_cacheKey(node.raw));
    }
  }

  static Future<SpeedTestResult> testNode(
    ProxyNode node, {
    Duration timeout = _timeout,
  }) async {
    final now = DateTime.now();
    final protocol = _detectProtocol(node.raw);
    final hostPort = _extractHostPort(node.raw);
    if (hostPort == null) {
      return SpeedTestResult(
        available: false,
        tcpMs: null,
        tlsMs: null,
        scoreMs: 999999,
        jitterMs: null,
        testedAt: now,
        error: 'config_error',
        exitCode: null,
      );
    }

    final singboxResult = await _testWithSingbox(
      node: node,
      timeout: timeout,
      host: hostPort.host,
      port: hostPort.port,
      protocol: protocol,
    );
    if (singboxResult != null) {
      await _appendLog(
        node: node,
        host: hostPort.host,
        port: hostPort.port,
        protocol: protocol,
        result: singboxResult,
        exitCode: singboxResult.exitCode,
      );
      return singboxResult;
    }

    final isTls = _isTlsNode(node.raw, hostPort.port);
    final sni = _extractSni(node.raw) ?? hostPort.host;

    final tcpSamples = await _runSamples(
      () => _measureTcp(hostPort.host, hostPort.port, timeout),
    );
    final tlsSamples = isTls
        ? await _runSamples(
            () => _measureTls(hostPort.host, hostPort.port, sni, timeout),
          )
        : <int>[];

    final tcpMs = _median(tcpSamples);
    final tlsMs = _median(tlsSamples);

    final available = isTls ? tlsMs != null : tcpMs != null;
    final scoreMs = tlsMs ?? tcpMs ?? 999999;
    final jitterMs = _jitter([...tcpSamples, ...tlsSamples]);
    final error = available ? null : _inferSocketError(isTls, tcpMs, tlsMs);

    final result = SpeedTestResult(
      available: available,
      tcpMs: tcpMs,
      tlsMs: tlsMs,
      scoreMs: scoreMs,
      jitterMs: jitterMs,
      testedAt: now,
      error: error,
      exitCode: null,
    );
    await _appendLog(
      node: node,
      host: hostPort.host,
      port: hostPort.port,
      protocol: protocol,
      result: result,
      exitCode: null,
    );
    return result;
  }

  static Future<List<int>> _runSamples(Future<int?> Function() runner) async {
    final results = <int>[];
    for (var i = 0; i < 2; i++) {
      final value = await runner();
      if (value != null) {
        results.add(value);
      }
    }
    return results;
  }

  static int? _median(List<int> values) {
    if (values.isEmpty) {
      return null;
    }
    values.sort();
    if (values.length == 1) {
      return values.first;
    }
    final middle = values.length ~/ 2;
    if (values.length.isOdd) {
      return values[middle];
    }
    return ((values[middle - 1] + values[middle]) / 2).round();
  }

  static int? _jitter(List<int> values) {
    if (values.length < 2) {
      return null;
    }
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    return maxValue - minValue;
  }

  static Future<int?> _measureTcp(
    String host,
    int port,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  static Future<int?> _measureTls(
    String host,
    int port,
    String sni,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    SecureSocket? secureSocket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      secureSocket = await SecureSocket.secure(
        socket,
        supportedProtocols: const ['http/1.1'],
        onBadCertificate: (_) => true,
        host: sni,
      ).timeout(timeout);
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    } finally {
      secureSocket?.destroy();
      socket?.destroy();
    }
  }

  static Future<SpeedTestResult?> _testWithSingbox({
    required ProxyNode node,
    required Duration timeout,
    required String host,
    required int port,
    required String protocol,
  }) async {
    if (!Platform.isWindows) {
      return null;
    }
    final now = DateTime.now();
    File? binary;
    try {
      binary = await WindowsCoreBinary.ensureCoreBinary();
    } catch (_) {
      return null;
    }

    final configDir = await _ensureTestConfigDir();
    final configPath = File(
      '${configDir.path}\\node_${_fnv1a(node.raw)}.json',
    );
    try {
      final content = WindowsVpnConfigBuilder.buildTestConfig(node);
      await configPath.writeAsString(content, flush: true);
    } catch (_) {
      return SpeedTestResult(
        available: false,
        tcpMs: null,
        tlsMs: null,
        scoreMs: 999999,
        jitterMs: null,
        testedAt: now,
        error: 'config_error',
        exitCode: null,
      );
    }

    final stopwatch = Stopwatch()..start();
    final result = await Isolate.run(
      () async => _runSingboxTest(
        binary!.path,
        configPath.path,
        timeout,
      ),
    );
    stopwatch.stop();

    final latencyMs = result.latencyMs;
    final available = result.success && latencyMs != null;
    final error = available ? null : result.error;

    return SpeedTestResult(
      available: available,
      tcpMs: null,
      tlsMs: latencyMs,
      scoreMs: latencyMs ?? 999999,
      jitterMs: null,
      testedAt: now,
      error: error,
      exitCode: result.exitCode,
    );
  }

  static Future<_SingboxResult> _runSingboxTest(
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
      final proc = await Process.start(exePath, args);
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
      output: output,
    );
  }

  static int? _parseLatency(String output) {
    final match = RegExp(r'latency\\s*[:=]\\s*(\\d+)\\s*ms', caseSensitive: false)
        .firstMatch(output);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    final fallback = RegExp(r'(\\d+)\\s*ms', caseSensitive: false).firstMatch(output);
    if (fallback != null) {
      return int.tryParse(fallback.group(1) ?? '');
    }
    return null;
  }

  static String _inferSingboxError(String output) {
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

  static String? _inferSocketError(bool isTls, int? tcpMs, int? tlsMs) {
    if (isTls && tlsMs == null) {
      return tcpMs == null ? 'timeout' : 'handshake_failed';
    }
    if (!isTls && tcpMs == null) {
      return 'timeout';
    }
    return null;
  }

  static Future<Directory> _ensureTestConfigDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}\\speedtest');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> _appendLog({
    required ProxyNode node,
    required String host,
    required int port,
    required String protocol,
    required SpeedTestResult result,
    required int? exitCode,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory('${supportDir.path}\\logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    final logFile = File('${logDir.path}\\speedtest.log');
    final rtt = result.tlsMs ?? result.tcpMs ?? result.scoreMs;
    final line = [
      DateTime.now().toIso8601String(),
      node.displayName.replaceAll('\n', ' '),
      '$protocol $host:$port',
      result.available ? 'ok' : 'fail',
      'rtt=${rtt}ms',
      'err=${result.error ?? '-'}',
      'exit=${exitCode ?? '-'}',
    ].join(' | ');
    await logFile.writeAsString('$line\n', mode: FileMode.append, flush: true);
  }

  static String _detectProtocol(String raw) {
    final lower = raw.toLowerCase();
    if (lower.startsWith('vless://')) {
      return 'vless';
    }
    if (lower.startsWith('trojan://')) {
      return 'trojan';
    }
    if (lower.startsWith('vmess://')) {
      return 'vmess';
    }
    return 'unknown';
  }

  static _HostPort? _extractHostPort(String raw) {
    final lower = raw.toLowerCase();
    if (lower.startsWith('vmess://')) {
      final payload = raw.substring('vmess://'.length);
      final decoded = _tryBase64Decode(payload);
      if (decoded == null) {
        return null;
      }
      try {
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final host = (json['add'] ?? '').toString();
        final portValue = json['port'];
        int? port;
        if (portValue is int) {
          port = portValue;
        } else if (portValue != null) {
          port = int.tryParse(portValue.toString());
        }
        if (host.isEmpty || port == null) {
          return null;
        }
        return _HostPort(host: host, port: port);
      } catch (_) {
        return null;
      }
    }

    if (lower.startsWith('vless://') || lower.startsWith('trojan://')) {
      return _parseUserInfoHostPort(raw);
    }

    return null;
  }

  static _HostPort? _parseUserInfoHostPort(String raw) {
    final schemeEnd = raw.indexOf('://');
    if (schemeEnd == -1) {
      return null;
    }
    var rest = raw.substring(schemeEnd + 3);
    if (rest.startsWith('//')) {
      rest = rest.substring(2);
    }

    final fragmentSplit = rest.split('#');
    final withoutFragment = fragmentSplit.isNotEmpty ? fragmentSplit.first : rest;
    final querySplit = withoutFragment.split('?');
    final withoutQuery = querySplit.isNotEmpty ? querySplit.first : withoutFragment;

    final atIndex = withoutQuery.lastIndexOf('@');
    final hostPortPart = atIndex == -1 ? withoutQuery : withoutQuery.substring(atIndex + 1);
    if (hostPortPart.isEmpty) {
      return null;
    }

    final colonIndex = hostPortPart.lastIndexOf(':');
    if (colonIndex == -1) {
      return null;
    }

    final host = hostPortPart.substring(0, colonIndex);
    final portStr = hostPortPart.substring(colonIndex + 1);
    if (host.isEmpty) {
      return null;
    }
    final port = int.tryParse(portStr);
    if (port == null) {
      return null;
    }
    return _HostPort(host: host, port: port);
  }

  static String? _extractSni(String raw) {
    final lower = raw.toLowerCase();
    if (lower.startsWith('vmess://')) {
      final payload = raw.substring('vmess://'.length);
      final decoded = _tryBase64Decode(payload);
      if (decoded == null) {
        return null;
      }
      try {
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final host = _pickHostFromMap(json);
        if (host != null && host.isNotEmpty) {
          return host;
        }
        final add = (json['add'] ?? '').toString().trim();
        return add.isNotEmpty ? add : null;
      } catch (_) {
        return null;
      }
    }

    final params = _parseQueryParams(raw);
    return _pickHostFromMap(params);
  }

  static bool _isTlsNode(String raw, int port) {
    if (port == 443) {
      return true;
    }
    final lower = raw.toLowerCase();
    if (lower.startsWith('vmess://')) {
      final payload = raw.substring('vmess://'.length);
      final decoded = _tryBase64Decode(payload);
      if (decoded == null) {
        return false;
      }
      try {
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final tlsValue = (json['tls'] ?? '').toString().trim();
        return tlsValue.isNotEmpty && tlsValue != 'none';
      } catch (_) {
        return false;
      }
    }

    final params = _parseQueryParams(raw);
    final security = params['security'] ?? params['tls'];
    if (security == null) {
      return false;
    }
    final value = security.toLowerCase();
    return value.isNotEmpty && value != 'none' && value != 'false' && value != '0';
  }

  static Map<String, String> _parseQueryParams(String raw) {
    final queryStart = raw.indexOf('?');
    if (queryStart == -1) {
      return {};
    }
    final fragmentStart = raw.indexOf('#', queryStart + 1);
    final query = fragmentStart == -1
        ? raw.substring(queryStart + 1)
        : raw.substring(queryStart + 1, fragmentStart);
    if (query.isEmpty) {
      return {};
    }

    final params = <String, String>{};
    for (final part in query.split('&')) {
      if (part.isEmpty) {
        continue;
      }
      final eq = part.indexOf('=');
      final key = eq == -1 ? part : part.substring(0, eq);
      final value = eq == -1 ? '' : part.substring(eq + 1);
      final decodedKey = Uri.decodeComponent(key).toLowerCase();
      final decodedValue = Uri.decodeComponent(value);
      if (decodedKey.isNotEmpty && decodedValue.isNotEmpty) {
        params[decodedKey] = decodedValue;
      }
    }
    return params;
  }

  static String? _pickHostFromMap(Map<String, dynamic> source) {
    const keys = [
      'sni',
      'host',
      'ws-host',
      'ws_host',
      'wshost',
      'peer',
    ];
    final lowered = <String, dynamic>{};
    source.forEach((key, value) {
      lowered[key.toString().toLowerCase()] = value;
    });

    for (final key in keys) {
      if (!lowered.containsKey(key)) {
        continue;
      }
      final value = lowered[key];
      if (value == null) {
        continue;
      }
      final host = value.toString().trim();
      if (host.isNotEmpty) {
        return host.split(',').first.trim();
      }
    }
    return null;
  }

  static String? _tryBase64Decode(String content) {
    try {
      final normalized = content.replaceAll(RegExp(r'\s'), '');
      final padded = base64.normalize(normalized);
      final bytes = base64.decode(padded);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      try {
        final normalized = content.replaceAll(RegExp(r'\s'), '');
        final padded = base64.normalize(normalized);
        final bytes = base64Url.decode(padded);
        return utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        return null;
      }
    }
  }

  static _CacheEntry? _readCache(
    SharedPreferences prefs,
    String raw,
    DateTime now,
  ) {
    final key = _cacheKey(raw);
    final value = prefs.getString(key);
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      final testedAtMs = json['testedAt'] as int?;
      if (testedAtMs == null) {
        prefs.remove(key);
        return null;
      }
      final testedAt = DateTime.fromMillisecondsSinceEpoch(testedAtMs);
      if (now.difference(testedAt) > _cacheTtl) {
        prefs.remove(key);
        return null;
      }
      return _CacheEntry(
        tcpMs: json['tcpMs'] as int?,
        tlsMs: json['tlsMs'] as int?,
        available: (json['available'] as bool?) ?? false,
        testedAt: testedAt,
        error: json['error'] as String?,
        exitCode: null,
      );
    } catch (_) {
      prefs.remove(key);
      return null;
    }
  }

  static Future<void> _writeCache(
    SharedPreferences prefs,
    String raw,
    SpeedTestResult result,
  ) async {
    final key = _cacheKey(raw);
    final payload = jsonEncode({
      'tcpMs': result.tcpMs,
      'tlsMs': result.tlsMs,
      'available': result.available,
      'testedAt': result.testedAt.millisecondsSinceEpoch,
      'error': result.error,
    });
    await prefs.setString(key, payload);
  }

  static void _applyResult(ProxyNode node, SpeedTestResult result) {
    node.tcpMs = result.tcpMs;
    node.tlsMs = result.tlsMs;
    node.available = result.available;
    node.latencyMs = result.scoreMs;
    node.testedAt = result.testedAt;
    node.testError = result.error;
  }

  static int _compareNodes(ProxyNode a, ProxyNode b) {
    if (a.available != b.available) {
      return a.available ? -1 : 1;
    }
    final aScore = a.latencyMs ?? 999999;
    final bScore = b.latencyMs ?? 999999;
    return aScore.compareTo(bScore);
  }

  static String _cacheKey(String raw) {
    return 'win_node_test_${_fnv1a(raw)}';
  }

  static String _fnv1a(String input) {
    const int fnvPrime = 16777619;
    const int fnvOffset = 0x811c9dc5;
    int hash = fnvOffset;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

class _CacheEntry extends SpeedTestResult {
  _CacheEntry({
    required super.tcpMs,
    required super.tlsMs,
    required super.available,
    required super.testedAt,
    required super.error,
    required super.exitCode,
  }) : super(
          scoreMs: (tlsMs ?? tcpMs ?? 999999),
          jitterMs: null,
        );
}

class _HostPort {
  final String host;
  final int port;

  _HostPort({required this.host, required this.port});
}

class _SingboxResult {
  final bool success;
  final int? latencyMs;
  final String? error;
  final int? exitCode;
  final String? output;

  _SingboxResult({
    required this.success,
    required this.latencyMs,
    required this.error,
    required this.exitCode,
    this.output,
  });
}

Future<void> _runWithConcurrency(
  List<ProxyNode> nodes,
  int limit,
  Future<void> Function(ProxyNode) worker,
) async {
  if (nodes.isEmpty) {
    return;
  }
  final count = nodes.length < limit ? nodes.length : limit;
  var index = 0;

  Future<void> runNext() async {
    while (true) {
      final current = index++;
      if (current >= nodes.length) {
        return;
      }
      await worker(nodes[current]);
    }
  }

  final futures = <Future<void>>[];
  for (var i = 0; i < count; i++) {
    futures.add(runNext());
  }

  await Future.wait(futures);
}

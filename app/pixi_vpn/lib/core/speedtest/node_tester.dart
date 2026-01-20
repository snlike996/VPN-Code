import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/proxy_node.dart';

enum NodeTestMode { httpProbe, tlsHandshake }

class NodeTester {
  static const Duration _timeout = Duration(seconds: 3);
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const int _maxConcurrency = 5;

  static Future<List<ProxyNode>> testAndSort(
    List<ProxyNode> nodes, {
    NodeTestMode mode = NodeTestMode.httpProbe,
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
        node.latencyMs = cached.latencyMs;
        node.available = cached.available;
        node.testedAt = cached.testedAt;
      } else {
        toTest.add(node);
      }
    }

    if (toTest.isNotEmpty) {
      await _runWithConcurrency(toTest, _maxConcurrency, (node) async {
        final result = await _testNode(node, mode: mode, timeout: timeout);
        node.latencyMs = result.latencyMs;
        node.available = result.available;
        node.testedAt = result.testedAt;
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
        latencyMs: json['latencyMs'] as int?,
        available: (json['available'] as bool?) ?? false,
        testedAt: testedAt,
      );
    } catch (_) {
      prefs.remove(key);
      return null;
    }
  }

  static Future<void> _writeCache(
    SharedPreferences prefs,
    String raw,
    _CacheEntry entry,
  ) async {
    final key = _cacheKey(raw);
    final payload = jsonEncode({
      'latencyMs': entry.latencyMs,
      'available': entry.available,
      'testedAt': entry.testedAt.millisecondsSinceEpoch,
    });
    await prefs.setString(key, payload);
  }

  static Future<_CacheEntry> _testNode(
    ProxyNode node, {
    required NodeTestMode mode,
    required Duration timeout,
  }) async {
    final now = DateTime.now();
    final hostPort = _extractHostPort(node.raw);
    final connectHost = hostPort?.host;
    final probeHost = _extractProbeHost(node.raw) ?? connectHost;
    final probePort = hostPort?.port ?? 443;
    log('NodeTester: raw="${node.raw}" host="${connectHost ?? ''}" sni="${probeHost ?? ''}" port="$probePort"');
    if (connectHost == null) {
      return _CacheEntry(
        latencyMs: null,
        available: false,
        testedAt: now,
      );
    }

    final requiresTls = _requiresTls(node.raw);
    final stopwatch = Stopwatch()..start();
    final result = mode == NodeTestMode.tlsHandshake
        ? (requiresTls
            ? await _probeTls(connectHost, probePort, timeout: timeout, sni: probeHost)
            : await _probeTcp(connectHost, probePort, timeout: timeout))
        : await _probeHttp(probeHost, probePort, timeout: timeout);
    stopwatch.stop();

    int? latency = result.success ? stopwatch.elapsedMilliseconds : null;
    if (latency != null && latency < 20) {
      latency = 20;
    }
    log('NodeTester: name="${node.displayName}" host="$connectHost" sni="$probeHost" tls=$requiresTls status=${result.statusCode} latencyMs=$latency');

    return _CacheEntry(
      latencyMs: latency,
      available: result.success,
      testedAt: now,
    );
  }

  static Future<void> _runWithConcurrency(
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

  static String? _extractProbeHost(String raw) {
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

    final queryParams = _parseQueryParams(raw);
    final host = _pickHostFromMap(queryParams);
    return host;
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

  static Future<_ProbeResult> _probeHttp(
    String? host,
    int port, {
    required Duration timeout,
  }) async {
    if (host == null || host.isEmpty) {
      return _ProbeResult.failure();
    }
    final paths = ['/generate_204', '/cdn-cgi/trace'];
    _ProbeResult? lastResult;

    for (final path in paths) {
      final uri = Uri(
        scheme: 'https',
        host: host,
        port: port == 443 ? null : port,
        path: path,
      );
      final result = await _performRequest(uri, timeout: timeout);
      lastResult = result;
      if (result.success) {
        return result;
      }
    }

    return lastResult ?? _ProbeResult.failure();
  }

  static Future<_ProbeResult> _performRequest(
    Uri uri, {
    required Duration timeout,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.userAgentHeader, 'pixi_vpn_tester');
      final response = await request.close().timeout(timeout);
      final status = response.statusCode;
      await response.drain().timeout(timeout);
      return _ProbeResult(success: true, statusCode: status);
    } catch (_) {
      return _ProbeResult.failure();
    } finally {
      client.close(force: true);
    }
  }

  static Future<_ProbeResult> _probeTcp(
    String host,
    int port, {
    required Duration timeout,
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      return _ProbeResult(success: true, statusCode: 200);
    } catch (_) {
      return _ProbeResult.failure();
    } finally {
      socket?.destroy();
    }
  }

  static Future<_ProbeResult> _probeTls(
    String host,
    int port, {
    required Duration timeout,
    String? sni,
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      final secureSocket = await SecureSocket.secure(
        socket,
        host: sni ?? host,
        onBadCertificate: (_) => true,
      ).timeout(timeout);
      secureSocket.destroy();
      return _ProbeResult(success: true, statusCode: 200);
    } catch (_) {
      return _ProbeResult.failure();
    } finally {
      socket?.destroy();
    }
  }

  static bool _requiresTls(String raw) {
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

  static int _compareNodes(ProxyNode a, ProxyNode b) {
    if (a.available != b.available) {
      return a.available ? -1 : 1;
    }

    final aLatency = a.latencyMs;
    final bLatency = b.latencyMs;
    if (aLatency == null && bLatency == null) {
      return 0;
    }
    if (aLatency == null) {
      return 1;
    }
    if (bLatency == null) {
      return -1;
    }
    return aLatency.compareTo(bLatency);
  }

  static String _cacheKey(String raw) {
    return 'node_test_${_fnv1a(raw)}';
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

class _CacheEntry {
  final int? latencyMs;
  final bool available;
  final DateTime testedAt;

  _CacheEntry({
    required this.latencyMs,
    required this.available,
    required this.testedAt,
  });
}

class _HostPort {
  final String host;
  final int port;

  _HostPort({required this.host, required this.port});
}

class _ProbeResult {
  final bool success;
  final int? statusCode;

  _ProbeResult({required this.success, required this.statusCode});

  factory _ProbeResult.failure() {
    return _ProbeResult(success: false, statusCode: null);
  }
}

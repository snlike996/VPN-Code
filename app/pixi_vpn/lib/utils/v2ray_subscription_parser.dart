import 'dart:convert';
import 'dart:developer';
import 'package:pixi_vpn/model/proxy_node.dart';

class V2raySubscriptionParser {
  static List<ProxyNode> parse(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final plainNodes = _parseLines(trimmed);
    log('SubscriptionParser: plain nodes=${plainNodes.length}');
    if (plainNodes.isNotEmpty) {
      return plainNodes;
    }

    final decoded = _tryBase64Decode(trimmed);
    if (decoded == null) {
      log('SubscriptionParser: base64 decode failed');
      return plainNodes;
    }

    final decodedNodes = _parseLines(decoded);
    log('SubscriptionParser: decoded nodes=${decodedNodes.length}');
    return decodedNodes;
  }

  static List<ProxyNode> _parseLines(String content) {
    final lines = content
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.replaceFirst(RegExp(r'^\uFEFF'), '').trimLeft())
        .where((line) => line.isNotEmpty)
        .toList();

    final nodes = <ProxyNode>[];
    for (final line in lines) {
      final node = _parseLine(line);
      if (node != null) {
        nodes.add(node);
      }
    }
    return nodes;
  }

  static ProxyNode? _parseLine(String line) {
    final normalized = line.replaceFirst(RegExp(r'^\uFEFF'), '').trimLeft();
    final lower = normalized.toLowerCase();
    if (!lower.startsWith('vless://') &&
        !lower.startsWith('vmess://') &&
        !lower.startsWith('trojan://')) {
      return null;
    }

    if (lower.startsWith('vmess://')) {
      return _parseVmess(normalized);
    }

    return _parseUriLike(normalized);
  }

  static ProxyNode? _parseUriLike(String line) {
    try {
      final uri = Uri.parse(line);
      final name = uri.fragment.isNotEmpty
          ? Uri.decodeComponent(uri.fragment)
          : '';
      final host = uri.host.isNotEmpty ? uri.host : null;
      final port = uri.hasPort ? uri.port : null;

      return ProxyNode(
        id: line.hashCode.toString(),
        type: uri.scheme,
        name: name,
        raw: line,
        host: host,
        port: port,
      );
    } catch (_) {
      return null;
    }
  }

  static ProxyNode? _parseVmess(String line) {
    final payload = line.substring('vmess://'.length);
    final decoded = _tryBase64Decode(payload);
    if (decoded == null) {
      return ProxyNode(
        id: line.hashCode.toString(),
        type: 'vmess',
        name: '',
        raw: line,
      );
    }

    try {
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final name = (json['ps'] ?? '').toString();
      final host = (json['add'] ?? '').toString();
      final portString = (json['port'] ?? '').toString();
      final port = int.tryParse(portString);

      return ProxyNode(
        id: line.hashCode.toString(),
        type: 'vmess',
        name: name,
        raw: line,
        host: host.isNotEmpty ? host : null,
        port: port,
      );
    } catch (_) {
      return ProxyNode(
        id: line.hashCode.toString(),
        type: 'vmess',
        name: '',
        raw: line,
      );
    }
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
}

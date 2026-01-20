import 'dart:convert';

import '../../core/models/proxy_node.dart';

class WindowsVpnConfigBuilder {
  static String build(
    ProxyNode node, {
    int? localProxyPort,
    String? logOutputPath,
  }) {
    final parsed = _parse(node.raw);
    if (parsed == null) {
      throw StateError('Unsupported node format: ${node.raw}');
    }

    final outbound = _buildOutbound(parsed);

    final inbounds = [
      {
        'type': 'tun',
        'tag': 'tun-in',
        'interface_name': 'tsvpn0',
        'inet4_address': '172.19.0.1/30',
        'auto_route': true,
        'strict_route': true,
        'sniff': true,
      },
    ];

    if (localProxyPort != null) {
      inbounds.add({
        'type': 'mixed',
        'tag': 'mixed-in',
        'listen': '127.0.0.1',
        'listen_port': localProxyPort,
      });
    }

    final config = <String, dynamic>{
      'log': _buildLog(logOutputPath),
      'dns': {
        'servers': [
          {
            'address': '1.1.1.1',
            'detour': 'proxy',
          },
          {
            'address': '8.8.8.8',
            'detour': 'proxy',
          },
        ],
      },
      'inbounds': inbounds,
      'outbounds': [
        outbound,
        {
          'type': 'direct',
          'tag': 'direct',
        },
        {
          'type': 'block',
          'tag': 'block',
        },
      ],
      'route': {
        'auto_detect_interface': true,
        'rules': [
          {
            'protocol': 'dns',
            'outbound': 'direct',
          },
        ],
        'final': 'proxy',
      },
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  static String buildTestConfig(ProxyNode node, {String? logOutputPath}) {
    final parsed = _parse(node.raw);
    if (parsed == null) {
      throw StateError('Unsupported node format: ${node.raw}');
    }

    final outbound = _buildOutbound(parsed);
    final config = <String, dynamic>{
      'log': _buildLog(logOutputPath),
      'outbounds': [
        outbound,
        {
          'type': 'direct',
          'tag': 'direct',
        },
        {
          'type': 'block',
          'tag': 'block',
        },
      ],
      'route': {
        'final': 'proxy',
      },
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  static Map<String, dynamic> _buildLog(String? logOutputPath) {
    final log = <String, dynamic>{
      'level': 'debug',
    };
    if (logOutputPath != null && logOutputPath.isNotEmpty) {
      log['output'] = logOutputPath;
    }
    return log;
  }

  static Map<String, dynamic> _buildOutbound(_ParsedNode parsed) {
    final outbound = <String, dynamic>{
      'type': parsed.protocol,
      'tag': 'proxy',
      'server': parsed.host,
      'server_port': parsed.port,
    };

    if (parsed.protocol == 'vless') {
      outbound['uuid'] = parsed.uuid;
    } else if (parsed.protocol == 'trojan') {
      outbound['password'] = parsed.password;
    } else if (parsed.protocol == 'vmess') {
      outbound['uuid'] = parsed.uuid;
      if (parsed.alterId != null) {
        outbound['alter_id'] = parsed.alterId;
      }
    }

    if (parsed.transport == 'ws') {
      outbound['transport'] = {
        'type': 'ws',
        'path': parsed.wsPath ?? '/',
        'headers': {
          'Host': parsed.wsHost ?? parsed.sni ?? parsed.host,
        },
      };
    }

    if (parsed.tlsEnabled) {
      outbound['tls'] = {
        'enabled': true,
        'server_name': parsed.sni ?? parsed.host,
        'insecure': true,
      };
    }

    return outbound;
  }

  static _ParsedNode? _parse(String raw) {
    final lower = raw.toLowerCase();
    if (lower.startsWith('vmess://')) {
      return _parseVmess(raw);
    }
    if (lower.startsWith('vless://')) {
      return _parseVlessOrTrojan(raw, 'vless');
    }
    if (lower.startsWith('trojan://')) {
      return _parseVlessOrTrojan(raw, 'trojan');
    }
    return null;
  }

  static _ParsedNode? _parseVlessOrTrojan(String raw, String protocol) {
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
    final query = querySplit.length > 1 ? querySplit.sublist(1).join('?') : '';

    final atIndex = withoutQuery.lastIndexOf('@');
    if (atIndex == -1) {
      return null;
    }
    final userInfo = withoutQuery.substring(0, atIndex);
    final hostPortPart = withoutQuery.substring(atIndex + 1);
    final colonIndex = hostPortPart.lastIndexOf(':');
    if (colonIndex == -1) {
      return null;
    }
    final host = hostPortPart.substring(0, colonIndex);
    final port = int.tryParse(hostPortPart.substring(colonIndex + 1));
    if (host.isEmpty || port == null) {
      return null;
    }

    final params = _parseQueryParams(query);
    final transport = params['type'] ?? params['net'];
    final wsPath = params['path'];
    final wsHost = params['host'] ?? params['ws-host'] ?? params['ws_host'];
    final sni = params['sni'] ?? params['peer'] ?? wsHost;
    final security = params['security'] ?? params['tls'];
    final tlsEnabled = security != null && security.isNotEmpty && security != 'none';

    return _ParsedNode(
      protocol: protocol,
      host: host,
      port: port,
      uuid: protocol == 'vless' ? userInfo : null,
      password: protocol == 'trojan' ? userInfo : null,
      tlsEnabled: tlsEnabled,
      sni: sni,
      transport: transport,
      wsPath: wsPath,
      wsHost: wsHost,
      alterId: null,
    );
  }

  static _ParsedNode? _parseVmess(String raw) {
    final payload = raw.substring('vmess://'.length);
    final decoded = _tryBase64Decode(payload);
    if (decoded == null) {
      return null;
    }
    try {
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final host = (json['add'] ?? '').toString().trim();
      final portValue = json['port'];
      int? port;
      if (portValue is int) {
        port = portValue;
      } else if (portValue != null) {
        port = int.tryParse(portValue.toString());
      }
      final uuid = (json['id'] ?? '').toString().trim();
      final alterIdValue = json['aid'];
      int? alterId;
      if (alterIdValue is int) {
        alterId = alterIdValue;
      } else if (alterIdValue != null) {
        alterId = int.tryParse(alterIdValue.toString());
      }
      if (host.isEmpty || port == null || uuid.isEmpty) {
        return null;
      }

      final transport = (json['net'] ?? '').toString();
      final wsPath = (json['path'] ?? '').toString();
      final wsHost = (json['host'] ?? '').toString();
      final sni = (json['sni'] ?? '').toString().isNotEmpty
          ? (json['sni'] ?? '').toString()
          : wsHost;
      final tlsValue = (json['tls'] ?? '').toString();
      final tlsEnabled = tlsValue.isNotEmpty && tlsValue != 'none';

      return _ParsedNode(
        protocol: 'vmess',
        host: host,
        port: port,
        uuid: uuid,
        password: null,
        tlsEnabled: tlsEnabled,
        sni: sni,
        transport: transport,
        wsPath: wsPath.isNotEmpty ? wsPath : null,
        wsHost: wsHost.isNotEmpty ? wsHost : null,
        alterId: alterId,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _parseQueryParams(String query) {
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
      if (decodedKey.isNotEmpty) {
        params[decodedKey] = decodedValue;
      }
    }
    return params;
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

class _ParsedNode {
  final String protocol;
  final String host;
  final int port;
  final String? uuid;
  final String? password;
  final bool tlsEnabled;
  final String? sni;
  final String? transport;
  final String? wsPath;
  final String? wsHost;
  final int? alterId;

  _ParsedNode({
    required this.protocol,
    required this.host,
    required this.port,
    required this.uuid,
    required this.password,
    required this.tlsEnabled,
    required this.sni,
    required this.transport,
    required this.wsPath,
    required this.wsHost,
    required this.alterId,
  });
}

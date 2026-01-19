import 'dart:io';

import 'package:flutter/services.dart';

enum ProxyMode { off, global, pac }

class SystemProxySnapshot {
  final int proxyEnable;
  final String? proxyServer;
  final String? proxyOverride;
  final String? autoConfigUrl;

  const SystemProxySnapshot({
    required this.proxyEnable,
    required this.proxyServer,
    required this.proxyOverride,
    required this.autoConfigUrl,
  });
}

class WindowsSystemProxy {
  static const MethodChannel _channel = MethodChannel('tsvpn/windows');
  static const String _key =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';

  Future<SystemProxySnapshot> readCurrentProxy() async {
    final enableValue = await _queryDword('ProxyEnable');
    final proxyEnable = enableValue ?? 0;
    return SystemProxySnapshot(
      proxyEnable: proxyEnable,
      proxyServer: await _queryString('ProxyServer'),
      proxyOverride: await _queryString('ProxyOverride'),
      autoConfigUrl: await _queryString('AutoConfigURL'),
    );
  }

  Future<void> setProxyOff({required SystemProxySnapshot snapshot}) async {
    await _setDword('ProxyEnable', snapshot.proxyEnable);
    await _setStringOrDelete('ProxyServer', snapshot.proxyServer);
    await _setStringOrDelete('ProxyOverride', snapshot.proxyOverride);
    await _setStringOrDelete('AutoConfigURL', snapshot.autoConfigUrl);
    await _refresh();
  }

  Future<void> setProxyGlobal({
    required String host,
    required int port,
    required SystemProxySnapshot snapshot,
  }) async {
    await _setDword('ProxyEnable', 1);
    await _setString('ProxyServer', '$host:$port');
    await _setString('ProxyOverride', _defaultProxyOverride());
    await _setStringOrDelete('AutoConfigURL', null);
    await _refresh();
  }

  Future<void> setProxyPac({
    required Uri pacUrl,
    required SystemProxySnapshot snapshot,
  }) async {
    await _setDword('ProxyEnable', 0);
    await _setStringOrDelete('ProxyServer', null);
    await _setString('AutoConfigURL', pacUrl.toString());
    await _setString('ProxyOverride', _defaultProxyOverride());
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      await _channel.invokeMethod('refreshInternetSettings');
    } catch (_) {
      // Fallback: ignore if channel unavailable.
    }
  }

  Future<String?> _queryString(String name) async {
    final result = await Process.run('reg', ['query', _key, '/v', name]);
    if (result.exitCode != 0) {
      return null;
    }
    final output = result.stdout.toString();
    final pattern = '${RegExp.escape(name)}\\s+REG_\\w+\\s+(.+)\\$';
    final regex = RegExp(pattern, multiLine: true);
    final match = regex.firstMatch(output);
    if (match == null) {
      return null;
    }
    return match.group(1)?.trim();
  }

  Future<int?> _queryDword(String name) async {
    final value = await _queryString(name);
    if (value == null) {
      return null;
    }
    final cleaned = value.trim();
    if (cleaned.startsWith('0x')) {
      return int.tryParse(cleaned.substring(2), radix: 16);
    }
    return int.tryParse(cleaned);
  }

  Future<void> _setString(String name, String value) async {
    await Process.run('reg', [
      'add',
      _key,
      '/v',
      name,
      '/t',
      'REG_SZ',
      '/d',
      value,
      '/f',
    ]);
  }

  Future<void> _setStringOrDelete(String name, String? value) async {
    if (value == null || value.isEmpty) {
      await Process.run('reg', ['delete', _key, '/v', name, '/f']);
      return;
    }
    await _setString(name, value);
  }

  Future<void> _setDword(String name, int value) async {
    await Process.run('reg', [
      'add',
      _key,
      '/v',
      name,
      '/t',
      'REG_DWORD',
      '/d',
      value.toString(),
      '/f',
    ]);
  }

  String _defaultProxyOverride() {
    return '<local>;localhost;127.*;10.*;192.168.*;172.16.*;172.17.*;172.18.*;172.19.*;172.2*;172.30.*;172.31.*';
  }
}

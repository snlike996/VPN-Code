import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'admin_check.dart';

class WindowsDnsProtect {
  static const List<String> defaultServers = ['1.1.1.1', '8.8.8.8'];

  Future<bool> enable({List<String>? servers}) async {
    if (!WindowsAdminCheck.isAdmin()) {
      throw StateError('Administrator privileges required for DNS protection');
    }

    final interfaceIndex = await _getDefaultInterfaceIndex();
    if (interfaceIndex == null) {
      return false;
    }

    final currentServers = await _getDnsServers(interfaceIndex);
    await _writeBackup(
      DnsBackup(interfaceIndex: interfaceIndex, servers: currentServers),
    );

    final dnsServers = servers ?? defaultServers;
    await _setDnsServers(interfaceIndex, dnsServers);
    return true;
  }

  Future<void> restore() async {
    if (!WindowsAdminCheck.isAdmin()) {
      throw StateError('Administrator privileges required for DNS protection');
    }

    final backup = await _readBackup();
    if (backup == null) {
      final interfaceIndex = await _getDefaultInterfaceIndex();
      if (interfaceIndex != null) {
        await _resetDnsServers(interfaceIndex);
      }
      return;
    }

    if (backup.servers.isEmpty) {
      await _resetDnsServers(backup.interfaceIndex);
      return;
    }

    await _setDnsServers(backup.interfaceIndex, backup.servers);
  }

  Future<int?> _getDefaultInterfaceIndex() async {
    final script = r'''
$route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1
if ($null -eq $route) { exit 1 }
$route.InterfaceIndex
''';
    final result = await _runPowerShell(script);
    if (result.exitCode != 0) {
      return null;
    }
    final output = result.stdout.toString().trim();
    return int.tryParse(output);
  }

  Future<List<String>> _getDnsServers(int interfaceIndex) async {
    final script = r'''
$servers = (Get-DnsClientServerAddress -InterfaceIndex {IDX} -AddressFamily IPv4).ServerAddresses
$servers | ConvertTo-Json -Compress
'''.replaceAll('{IDX}', interfaceIndex.toString());
    final result = await _runPowerShell(script);
    if (result.exitCode != 0) {
      return [];
    }
    final output = result.stdout.toString().trim();
    if (output.isEmpty || output == 'null') {
      return [];
    }
    try {
      final decoded = jsonDecode(output);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [decoded.toString()];
    } catch (_) {
      return [];
    }
  }

  Future<void> _setDnsServers(int interfaceIndex, List<String> servers) async {
    final joined = servers.map((s) => '"$s"').join(',');
    final script =
        'Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses ($joined)';
    final result = await _runPowerShell(script);
    if (result.exitCode != 0) {
      throw StateError('Failed to set DNS: ${result.stderr}');
    }
  }

  Future<void> _resetDnsServers(int interfaceIndex) async {
    final script =
        'Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ResetServerAddresses';
    final result = await _runPowerShell(script);
    if (result.exitCode != 0) {
      throw StateError('Failed to reset DNS: ${result.stderr}');
    }
  }

  Future<ProcessResult> _runPowerShell(String script) async {
    return Process.run(
      'powershell',
      ['-NoProfile', '-Command', script],
      runInShell: false,
    );
  }

  Future<File> _backupFile() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}\\dns_backup.json');
    return file;
  }

  Future<void> _writeBackup(DnsBackup backup) async {
    final file = await _backupFile();
    await file.writeAsString(jsonEncode(backup.toJson()), flush: true);
  }

  Future<DnsBackup?> _readBackup() async {
    final file = await _backupFile();
    if (!await file.exists()) {
      return null;
    }
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return DnsBackup.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

class DnsBackup {
  final int interfaceIndex;
  final List<String> servers;

  DnsBackup({required this.interfaceIndex, required this.servers});

  Map<String, dynamic> toJson() {
    return {
      'interfaceIndex': interfaceIndex,
      'servers': servers,
    };
  }

  factory DnsBackup.fromJson(Map<String, dynamic> json) {
    return DnsBackup(
      interfaceIndex: json['interfaceIndex'] as int,
      servers: (json['servers'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

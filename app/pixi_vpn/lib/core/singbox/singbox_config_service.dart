import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/model/base_model/api_response.dart';
import '../../data/repository/singbox_repo.dart';

class SingboxConfigItem {
  final int id;
  final String name;
  final String type;
  final String content;
  final int priority;

  const SingboxConfigItem({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    required this.priority,
  });
}

class SingboxConfigResult {
  final SingboxConfigItem config;
  final String path;
  final int? proxyPort;

  const SingboxConfigResult({
    required this.config,
    required this.path,
    required this.proxyPort,
  });
}

class SingboxConfigService {
  SingboxConfigService({required this.repo});

  final SingboxRepo repo;
  final Dio _dio = Dio();

  Future<List<SingboxConfigItem>> fetchConfigs() async {
    final ApiResponse response = await repo.getConfigs();
    if (response.response == null) {
      throw StateError(response.error?.toString() ?? 'Failed to load configs');
    }
    final data = response.response?.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('Invalid sing-box configs response');
    }
    final rawList = data['configs'];
    if (rawList is! List) {
      return <SingboxConfigItem>[];
    }
    return rawList.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return SingboxConfigItem(
        id: map['id'] as int,
        name: (map['name'] ?? '').toString(),
        type: (map['type'] ?? '').toString(),
        content: (map['content'] ?? '').toString(),
        priority: (map['priority'] ?? 0) as int,
      );
    }).toList();
  }

  Future<SingboxConfigResult> prepareConfig(SingboxConfigItem config) async {
    final content = await resolveContent(config);
    final proxyPort = parseProxyPort(content);
    final path = await _writeConfig(content);
    return SingboxConfigResult(
      config: config,
      path: path,
      proxyPort: proxyPort,
    );
  }

  Future<String> resolveContent(SingboxConfigItem config) async {
    if (config.type == 'subscription_url') {
      final response = await _dio.get<String>(
        config.content,
        options: Options(responseType: ResponseType.plain),
      );
      return response.data?.trim() ?? '';
    }
    return config.content.trim();
  }

  int? parseProxyPort(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final inbounds = decoded['inbounds'];
      if (inbounds is! List || inbounds.isEmpty) {
        return null;
      }
      final inbound = inbounds.first;
      if (inbound is! Map<String, dynamic>) {
        return null;
      }
      final listenPort = inbound['listen_port'];
      if (listenPort is int) {
        return listenPort;
      }
      if (listenPort is String) {
        return int.tryParse(listenPort);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _writeConfig(String content) async {
    final configDir = await _resolveConfigDir();
    await configDir.create(recursive: true);
    final configFile = File('${configDir.path}\\config.json');
    await configFile.writeAsString(content, flush: true);
    return configFile.path;
  }

  Future<Directory> _resolveConfigDir() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory('$appData\\TSVPN\\singbox');
      }
    }
    final supportDir = await getApplicationSupportDirectory();
    return Directory('${supportDir.path}\\TSVPN\\singbox');
  }
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class WindowsCoreBinary {
  static const String _assetPath = 'assets/windows/core/sing-box.exe';

  static Future<File> ensureCoreBinary() async {
    final supportDir = await getApplicationSupportDirectory();
    final coreDir = Directory('${supportDir.path}\\core');
    final coreFile = File('${coreDir.path}\\sing-box.exe');

    if (await coreFile.exists()) {
      return coreFile;
    }

    await coreDir.create(recursive: true);

    try {
      final data = await rootBundle.load(_assetPath);
      await coreFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return coreFile;
    } catch (_) {
      final fallback = File('windows/assets/core/sing-box.exe');
      if (await fallback.exists()) {
        return fallback.copy(coreFile.path);
      }
      throw StateError('sing-box.exe not found. Place it at assets/windows/core/sing-box.exe');
    }
  }
}

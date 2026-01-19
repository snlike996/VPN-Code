import 'dart:io';

import 'package:flutter/services.dart';

class WindowsStartupArgs {
  static const MethodChannel _channel = MethodChannel('tsvpn/windows');

  static Future<List<String>> load() async {
    try {
      final args = await _channel.invokeMethod<List<dynamic>>('getStartupArgs');
      if (args == null) {
        return Platform.executableArguments;
      }
      return args.map((e) => e.toString()).toList();
    } catch (_) {
      return Platform.executableArguments;
    }
  }
}

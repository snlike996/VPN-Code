import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';

class CrashGuard {
  static RawReceivePort? _errorPort;
  static RawReceivePort? _exitPort;

  static Future<void> run(Future<void> Function() body) async {
    _setupHandlers();
    await runZonedGuarded(() async {
      await body();
    }, (error, stack) {
      _log('zone_error', error.toString(), stack);
    });
  }

  static void _setupHandlers() {
    FlutterError.onError = (details) {
      _log('flutter_error', details.exceptionAsString(), details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _log('platform_error', error.toString(), stack);
      return true;
    };
    _errorPort ??= RawReceivePort((dynamic pair) {
      _log('isolate_error', pair.toString(), null);
    });
    Isolate.current.addErrorListener(_errorPort!.sendPort);
    _exitPort ??= RawReceivePort((_) {
      _log('isolate_exit', 'isolate exited', null);
    });
    Isolate.current.addOnExitListener(_exitPort!.sendPort);
  }

  static void _log(String tag, String message, StackTrace? stack) {
    try {
      final buffer = StringBuffer();
      buffer.write('[${DateTime.now().toIso8601String()}] ');
      buffer.write(tag);
      buffer.write(': ');
      buffer.writeln(message);
      if (stack != null) {
        buffer.writeln(stack.toString());
      }
      final file = File('${Directory.systemTemp.path}\\tsvpn_crash.log');
      file.writeAsStringSync(buffer.toString(), mode: FileMode.append);
    } catch (_) {
      // Never throw from crash guard.
    }
  }
}

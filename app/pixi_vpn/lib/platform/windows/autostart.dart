import 'dart:io';

class WindowsAutoStart {
  static const String _runKey =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const String _valueName = 'TSVPN';

  static Future<void> enableAutoStart({bool autoConnect = false}) async {
    final exePath = Platform.resolvedExecutable;
    final args = autoConnect ? ' --silent --autoconnect' : ' --silent';
    final value = '"$exePath"$args';
    final result = await Process.run('reg', [
      'add',
      _runKey,
      '/v',
      _valueName,
      '/t',
      'REG_SZ',
      '/d',
      value,
      '/f',
    ]);
    if (result.exitCode != 0) {
      throw StateError('Failed to enable auto start: ${result.stderr}');
    }
  }

  static Future<void> disableAutoStart() async {
    final result = await Process.run('reg', [
      'delete',
      _runKey,
      '/v',
      _valueName,
      '/f',
    ]);
    if (result.exitCode != 0) {
      final stderr = (result.stderr ?? '').toString();
      if (!stderr.contains('unable to find') && !stderr.contains('not found')) {
        throw StateError('Failed to disable auto start: ${result.stderr}');
      }
    }
  }

  static Future<bool> isAutoStartEnabled() async {
    final result = await Process.run('reg', [
      'query',
      _runKey,
      '/v',
      _valueName,
    ]);
    if (result.exitCode != 0) {
      return false;
    }
    final stdout = result.stdout.toString();
    return stdout.contains(_valueName);
  }
}

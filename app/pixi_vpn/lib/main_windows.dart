import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/utils/crash_guard.dart';
import 'di_container.dart' as di;
import 'ui/windows/windows_app.dart';
import 'platform/windows/startup_args.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  final args = await WindowsStartupArgs.load();
  final silent = args.contains('--silent');
  final autoConnect = args.contains('--autoconnect');
  final noTray = args.contains('--no-tray');
  final noCallbacks = args.contains('--no-callbacks');
  const windowOptions = WindowOptions(
    size: Size(1100, 720),
    center: true,
    title: 'TSVPN',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (!silent) {
      await windowManager.show();
      await windowManager.focus();
    } else {
      await windowManager.hide();
    }
  });

  await di.init();
  runApp(WindowsApp(
    launchOptions: WindowsLaunchOptions(
      silent: silent,
      autoConnect: autoConnect,
      noTray: noTray,
      noCallbacks: noCallbacks,
    ),
  ));
}

Future<void> main() async {
  await CrashGuard.run(() async {
    await bootstrap();
  });
}

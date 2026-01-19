import 'privilege_helper.dart';

class WindowsTunAdapter {
  Future<void> ensureReady() async {
    if (!WindowsPrivilege.isAdmin()) {
      throw StateError('Administrator privileges required for TUN');
    }
  }
}

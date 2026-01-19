import 'privilege_helper.dart';

class WindowsFirewall {
  Future<void> applyRules() async {
    if (!WindowsPrivilege.isAdmin()) {
      throw StateError('Administrator privileges required for firewall rules');
    }
  }

  Future<void> clearRules() async {
    if (!WindowsPrivilege.isAdmin()) {
      throw StateError('Administrator privileges required for firewall rules');
    }
  }
}

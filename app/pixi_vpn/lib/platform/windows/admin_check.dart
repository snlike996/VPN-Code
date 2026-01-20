import 'privilege_helper.dart';

class WindowsAdminCheck {
  static bool isAdmin() {
    return WindowsPrivilege.isAdmin();
  }
}

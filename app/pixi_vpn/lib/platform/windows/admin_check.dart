import 'package:win32/win32.dart' as win32;

class WindowsAdminCheck {
  static bool isAdmin() {
    return win32.IsUserAnAdmin() != 0;
  }
}

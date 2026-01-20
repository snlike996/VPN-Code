import 'dart:ffi';
import 'dart:io';

class WindowsPrivilege {
  static bool isAdmin() {
    if (!Platform.isWindows) {
      return false;
    }
    try {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final isUserAnAdmin =
          shell32.lookupFunction<Int32 Function(), int Function()>('IsUserAnAdmin');
      return isUserAnAdmin() != 0;
    } catch (_) {
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/profile_controller.dart';
import '../../shared/auth/signin_screen.dart';

class WindowsLoginDialog extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const WindowsLoginDialog({
    super.key,
    this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 600),
        child: SignInScreen(
          showBack: false,
          showExit: true,
          onExit: () => Navigator.of(context).pop(),
          onLoginSuccess: () {
            // Close dialog
            Navigator.of(context).pop();
            
            // Refresh profile data
            try {
              Get.find<ProfileController>().getProfileData();
            } catch (_) {
              // ProfileController might not be registered
            }
            
            // Call success callback
            onLoginSuccess?.call();
          },
        ),
      ),
    );
  }
}

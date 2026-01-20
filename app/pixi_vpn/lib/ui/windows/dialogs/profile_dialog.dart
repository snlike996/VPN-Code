import 'package:flutter/material.dart';

import '../../shared/profile/profile_screen.dart';

class WindowsProfileDialog extends StatelessWidget {
  const WindowsProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        height: 650,
        child: const ProfileScreen(),
      ),
    );
  }
}

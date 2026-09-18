import 'package:flutter/material.dart';

import '../desktop/breakpoints.dart';
import '../desktop/desktop_shell.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';
import 'admin_home_screen.dart';
import 'employee_shell_screen.dart';

Widget homeForUser(AppUser user) {
  return ResponsiveAppHome(isManager: user.isManager);
}

class ResponsiveAppHome extends StatelessWidget {
  const ResponsiveAppHome({super.key, required this.isManager});

  final bool isManager;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (DesktopBreakpoints.isMobile(width)) {
      return isManager
          ? const AdminHomeScreen()
          : const EmployeeShellScreen();
    }
    return DesktopShell(isManager: isManager);
  }
}

Future<void> logoutToLogin(BuildContext context) async {
  await ApiService.instance.logout();
  if (!context.mounted) {
    return;
  }
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}

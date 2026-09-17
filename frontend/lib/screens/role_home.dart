import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import 'admin_home_screen.dart';
import 'employee_shell_screen.dart';

Widget homeForUser(AppUser user) {
  if (user.isManager) {
    return const AdminHomeScreen();
  }
  return const EmployeeShellScreen();
}

Future<void> logoutToLogin(BuildContext context) async {
  await ApiService.instance.logout();
  if (!context.mounted) {
    return;
  }
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}

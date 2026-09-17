import 'package:flutter/material.dart';

import 'employees_screen.dart';
import 'users_screen.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Team'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Employees'),
              Tab(text: 'Users'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EmployeesScreen(embedded: true),
            UsersScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}

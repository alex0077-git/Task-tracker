import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../widgets/create_user_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    final users = await ApiService.instance.getUsers();
    if (!mounted) {
      return;
    }
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _openCreateUser() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );
    if (created == true) {
      await _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateUser,
        tooltip: 'Create user',
        child: const Icon(Icons.person_add_outlined),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: _users.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No users found')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: _users.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF3949AB),
                              child: Text(
                                user.username.isEmpty
                                    ? '?'
                                    : user.username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(user.username),
                            subtitle: Text(user.roleLabel),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

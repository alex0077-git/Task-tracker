import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/task.dart';
import '../../screens/user_tasks_screen.dart';
import '../../services/api_service.dart';
import '../desktop_theme.dart';

class DesktopEmployeesScreen extends StatefulWidget {
  const DesktopEmployeesScreen({
    super.key,
    this.refreshToken = 0,
    this.onDataChanged,
  });

  final int refreshToken;
  final VoidCallback? onDataChanged;

  @override
  State<DesktopEmployeesScreen> createState() => _DesktopEmployeesScreenState();
}

class _DesktopEmployeesScreenState extends State<DesktopEmployeesScreen> {
  final _searchController = TextEditingController();
  List<AppUser> _users = [];
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void didUpdateWidget(covariant DesktopEmployeesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadEmployees();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> get _visibleUsers {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) {
      return _users;
    }
    return _users.where((user) {
      return user.username.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.roleLabel.toLowerCase().contains(query);
    }).toList();
  }

  int _assignedCount(AppUser user) {
    return _tasks.where((task) => task.assignee == user.id).length;
  }

  Future<void> _loadEmployees({bool notifyChanged = false}) async {
    setState(() {
      _isLoading = true;
    });
    final results = await Future.wait([
      ApiService.instance.getUsers(),
      ApiService.instance.getTasks(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _users = results[0] as List<AppUser>;
      _tasks = results[1] as List<Task>;
      _isLoading = false;
    });
    if (notifyChanged) {
      widget.onDataChanged?.call();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _searchQuery = value.trim();
      });
    });
  }

  Future<void> _openCreateEmployee() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateEmployeeDialog(),
    );
    if (created == true) {
      await _loadEmployees(notifyChanged: true);
    }
  }

  Future<void> _openUser(AppUser user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserTasksScreen(
          assigneeId: user.id,
          username: user.username,
        ),
      ),
    );
    await _loadEmployees(notifyChanged: true);
  }

  @override
  Widget build(BuildContext context) {
    final users = _visibleUsers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Employees',
                  style: TextStyle(
                    color: DesktopColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreateEmployee,
                style: FilledButton.styleFrom(
                  backgroundColor: DesktopColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add Employee'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: DesktopColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DesktopColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DesktopColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: DesktopColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DesktopColors.border),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? const Center(
                          child: Text(
                            'No employees found',
                            style: TextStyle(
                              color: DesktopColors.textSecondary,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth:
                                    MediaQuery.sizeOf(context).width - 320,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  DesktopColors.background,
                                ),
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: 64,
                                columns: const [
                                  DataColumn(label: Text('#')),
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Role')),
                                  DataColumn(label: Text('Assigned')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: [
                                  for (var i = 0; i < users.length; i++)
                                    DataRow(
                                      cells: [
                                        DataCell(Text('${i + 1}')),
                                        DataCell(
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor:
                                                    DesktopColors.primarySoft,
                                                child: Text(
                                                  users[i].username.isEmpty
                                                      ? '?'
                                                      : users[i]
                                                          .username[0]
                                                          .toUpperCase(),
                                                  style: const TextStyle(
                                                    color:
                                                        DesktopColors.primary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                users[i].username,
                                                style: const TextStyle(
                                                  color: DesktopColors
                                                      .textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            users[i].email.isEmpty
                                                ? '—'
                                                : users[i].email,
                                            style: const TextStyle(
                                              color:
                                                  DesktopColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(users[i].roleLabel)),
                                        DataCell(
                                          Text('${_assignedCount(users[i])}'),
                                        ),
                                        DataCell(
                                          _StatusPill(
                                            active: users[i].isActive,
                                          ),
                                        ),
                                        DataCell(
                                          PopupMenuButton<String>(
                                            tooltip: 'Actions',
                                            onSelected: (value) {
                                              if (value == 'view') {
                                                _openUser(users[i]);
                                              }
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(
                                                value: 'view',
                                                child: Text('View'),
                                              ),
                                            ],
                                            icon: const Icon(
                                              Icons.more_horiz,
                                              color:
                                                  DesktopColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? DesktopColors.success : DesktopColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CreateEmployeeDialog extends StatefulWidget {
  const _CreateEmployeeDialog();

  @override
  State<_CreateEmployeeDialog> createState() => _CreateEmployeeDialogState();
}

class _CreateEmployeeDialogState extends State<_CreateEmployeeDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isStaff = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Username and password are required';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final error = await ApiService.instance.createUser(
      username: username,
      password: password,
      isStaff: _isStaff,
    );
    if (!mounted) {
      return;
    }
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isSaving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Employee'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              enabled: !_isSaving,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              enabled: !_isSaving,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Admin / Manager'),
              value: _isStaff,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _isStaff = value;
                      });
                    },
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: DesktopColors.primary,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

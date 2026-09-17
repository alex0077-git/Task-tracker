import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../models/task_counts.dart';
import '../services/api_service.dart';
import '../widgets/task_status_style.dart';
import 'user_tasks_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<AppUser> _users = [];
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  List<Task> _tasksFor(AppUser user) {
    return _tasks.where((task) => task.assignee == user.id).toList();
  }

  Future<void> _loadEmployees() async {
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
    await _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadEmployees,
            child: _users.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No employees found')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final counts = TaskCounts.fromTasks(_tasksFor(user));
                      return _EmployeeCard(
                        username: user.username,
                        counts: counts,
                        onTap: () => _openUser(user),
                      );
                    },
                  ),
          );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: content,
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.username,
    required this.counts,
    required this.onTap,
  });

  final String username;
  final TaskCounts counts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF3949AB),
                child: Text(
                  username.isEmpty ? '?' : username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${counts.total} assigned',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _CountChip(
                          color: TaskStatusStyle.toDo,
                          label: '${counts.toDo} to do',
                        ),
                        _CountChip(
                          color: TaskStatusStyle.pending,
                          label: '${counts.pending} pending',
                        ),
                        _CountChip(
                          color: TaskStatusStyle.completed,
                          label: '${counts.completed} done',
                        ),
                        _CountChip(
                          color: TaskStatusStyle.overdue,
                          label: '${counts.overdue} overdue',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

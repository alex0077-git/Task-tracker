import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_counts.dart';
import '../services/api_service.dart';
import '../widgets/assigned_task_card.dart';
import 'task_detail_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    final tasks = await ApiService.instance.getTasks();
    if (!mounted) {
      return;
    }
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _openTask(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final counts = TaskCounts.fromTasks(_tasks);
    final username = ApiService.instance.currentUser?.username ?? 'Employee';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My tasks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Hello, $username',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${counts.total} assigned  •  ${counts.pending} pending  •  ${counts.completed} done',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_tasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: Text('No tasks assigned')),
                    )
                  else
                    for (final task in _tasks) ...[
                      AssignedTaskCard(
                        task: task,
                        onTap: () => _openTask(task),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
    );
  }
}

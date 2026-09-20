import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_counts.dart';
import '../services/api_service.dart';
import '../widgets/assigned_task_card.dart';
import '../widgets/task_status_style.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class UserTasksScreen extends StatefulWidget {
  const UserTasksScreen({
    super.key,
    required this.assigneeId,
    required this.username,
  });

  final int assigneeId;
  final String username;

  @override
  State<UserTasksScreen> createState() => _UserTasksScreenState();
}

class _UserTasksScreenState extends State<UserTasksScreen> {
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
    final tasks = await ApiService.instance.getTasks(
      assigneeFilter: widget.assigneeId,
    );
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

  Future<void> _editTask(Task task) async {
    final didSave = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(existingTask: task),
      ),
    );
    if (didSave == true) {
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = TaskCounts.fromTasks(_tasks);

    return Scaffold(
      appBar: AppBar(title: Text(widget.username)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _EmployeeHeader(
                    username: widget.username,
                    counts: counts,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Assigned tasks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        onEdit: () => _editTask(task),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
    );
  }
}

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader({
    required this.username,
    required this.counts,
  });

  final String username;
  final TaskCounts counts;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${counts.total} assigned tasks',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatCell(
                  value: counts.toDo,
                  label: 'To Do',
                  color: TaskStatusStyle.toDo,
                ),
                _StatCell(
                  value: counts.pending,
                  label: 'Pending',
                  color: TaskStatusStyle.pending,
                ),
                _StatCell(
                  value: counts.completed,
                  label: 'Done',
                  color: TaskStatusStyle.completed,
                ),
                _StatCell(
                  value: counts.overdue,
                  label: 'Overdue',
                  color: TaskStatusStyle.overdue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

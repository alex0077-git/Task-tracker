import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../models/task_counts.dart';
import '../services/api_service.dart';
import '../widgets/overdue_badge.dart';
import '../widgets/priority_tag.dart';
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
    final tasks = await ApiService.instance.getTasks();
    if (!mounted) {
      return;
    }
    setState(() {
      _tasks = tasks
          .where((task) => task.assignee == widget.assigneeId)
          .toList();
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
                      _EmployeeTaskCard(
                        task: task,
                        onOpen: () => _openTask(task),
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

class _EmployeeTaskCard extends StatelessWidget {
  const _EmployeeTaskCard({
    required this.task,
    required this.onOpen,
    required this.onEdit,
  });

  final Task task;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: TaskStatusStyle.colorFor(task),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    TaskStatusStyle.labelFor(task),
                    style: TextStyle(
                      color: TaskStatusStyle.colorFor(task),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PriorityTag(priority: task.priority),
                      Text(
                        'Due ${DateFormat('d MMM yyyy').format(task.dueDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (task.isOverdue) const OverdueBadge(),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

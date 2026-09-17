import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_service.dart';
import '../widgets/priority_tag.dart';
import '../widgets/status_tag.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';
import 'workload_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _sortByPriority = false;

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

  Future<void> _openCreateForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskFormScreen()),
    );
    await _loadTasks();
  }

  Future<void> _openTaskDetail(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
    await _loadTasks();
  }

  String? _nextStatus(String status) {
    switch (status) {
      case 'To Do':
        return 'In Progress';
      case 'In Progress':
        return 'Completed';
      default:
        return null;
    }
  }

  Task _taskWithStatus(Task task, String status) {
    final today = DateTime.now();
    final dueDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    return Task(
      id: task.id,
      title: task.title,
      description: task.description,
      priority: task.priority,
      status: status,
      dueDate: task.dueDate,
      assignee: task.assignee,
      assigneeName: task.assigneeName,
      isOverdue: status != 'Completed' && dueDate.isBefore(todayDate),
    );
  }

  Future<void> _advanceStatus(Task task) async {
    if (task.id == null) {
      return;
    }

    final newStatus = _nextStatus(task.status);
    if (newStatus == null) {
      return;
    }

    final success = await ApiService.instance.updateTaskStatus(
      task.id!,
      newStatus,
    );
    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update status')),
      );
      return;
    }

    setState(() {
      _tasks = [
        for (final item in _tasks)
          if (item.id == task.id) _taskWithStatus(item, newStatus) else item,
      ];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to $newStatus')),
    );
  }

  List<Task> get _visibleTasks {
    if (!_sortByPriority) {
      return _tasks;
    }

    const rank = {'High': 0, 'Medium': 1, 'Low': 2};
    return [..._tasks]..sort((a, b) {
      return (rank[a.priority] ?? 3).compareTo(rank[b.priority] ?? 3);
    });
  }

  void _togglePrioritySort() {
    setState(() {
      _sortByPriority = !_sortByPriority;
    });
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkloadScreen()),
              );
            },
            icon: const Icon(Icons.people_outline),
            tooltip: 'Workload',
          ),
          IconButton(
            onPressed: _togglePrioritySort,
            icon: Icon(
              _sortByPriority ? Icons.flag : Icons.flag_outlined,
            ),
            tooltip: _sortByPriority
                ? 'Default order'
                : 'Sort by priority',
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: _visibleTasks.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No tasks yet')),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _visibleTasks.length,
                      itemBuilder: (context, index) {
                        final task = _visibleTasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(task.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${task.assigneeName}  •  ${_formatDate(task.dueDate)}',
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    PriorityTag(priority: task.priority),
                                    StatusTag(status: task.status),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              onPressed: () => _advanceStatus(task),
                              icon: const Icon(Icons.arrow_forward),
                              tooltip: 'Advance status',
                            ),
                            onTap: () => _openTaskDetail(task),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        tooltip: 'Create task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

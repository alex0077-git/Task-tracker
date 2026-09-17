import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../widgets/overdue_badge.dart';
import '../widgets/priority_tag.dart';
import '../widgets/status_tag.dart';
import '../widgets/task_comments.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  bool _isDeleting = false;

  bool get _isManager => ApiService.instance.isManager;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  String _formatDueDate(DateTime date) {
    return 'Due: ${DateFormat('d MMM yyyy').format(date)}';
  }

  Future<void> _openEditForm() async {
    final didSave = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(existingTask: _task),
      ),
    );
    if (!mounted || didSave != true || _task.id == null) {
      return;
    }
    await _refreshTask();
  }

  Future<void> _refreshTask() async {
    if (_task.id == null) {
      return;
    }
    final tasks = await ApiService.instance.getTasks();
    final updated = tasks.where((task) => task.id == _task.id);
    if (!mounted || updated.isEmpty) {
      return;
    }
    setState(() {
      _task = updated.first;
    });
  }

  Future<void> _openReassignDialog() async {
    if (_task.id == null) {
      return;
    }

    final users = await ApiService.instance.getUsers();
    if (!mounted) {
      return;
    }

    AppUser? selected;
    for (final user in users) {
      if (user.id == _task.assignee) {
        selected = user;
        break;
      }
    }
    selected ??= users.isEmpty ? null : users.first;

    final newAssignee = await showDialog<AppUser>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign task to employee'),
              content: users.isEmpty
                  ? const Text('No users available')
                  : DropdownButton<AppUser>(
                      isExpanded: true,
                      value: selected,
                      items: users
                          .map(
                            (user) => DropdownMenuItem(
                              value: user,
                              child: Text(user.username),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setDialogState(() {
                                selected = value;
                              });
                            },
                    ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isSaving || selected == null
                      ? null
                      : () async {
                          setDialogState(() {
                            isSaving = true;
                          });
                          final error = await ApiService.instance.reassignTask(
                            _task.id!,
                            selected!.id,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          if (error == null) {
                            Navigator.pop(context, selected);
                            return;
                          }
                          setDialogState(() {
                            isSaving = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || newAssignee == null) {
      return;
    }

    await _refreshTask();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assigned to ${newAssignee.username}')),
    );
  }

  Future<void> _confirmDelete() async {
    if (_task.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm deletion'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final success = await ApiService.instance.deleteTask(_task.id!);
    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _isDeleting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not delete task')),
    );
  }

  Future<void> _setStatus(String newStatus) async {
    if (_task.id == null || _task.status == newStatus) {
      return;
    }

    final success = await ApiService.instance.updateTaskStatus(
      _task.id!,
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

    await _refreshTask();
  }

  Future<void> _setPriority(String newPriority) async {
    if (_task.id == null || _task.priority == newPriority) {
      return;
    }

    final success = await ApiService.instance.updateTaskPriority(
      _task.id!,
      newPriority,
    );
    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update priority')),
      );
      return;
    }

    await _refreshTask();
  }

  @override
  Widget build(BuildContext context) {
    final description = _task.description.trim().isEmpty
        ? 'No description'
        : _task.description;

    return Scaffold(
      appBar: AppBar(title: const Text('Task details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _task.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(description),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Priority'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PriorityTag(priority: _task.priority),
                  if (_isManager) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final priority in const ['Low', 'Medium', 'High'])
                          ChoiceChip(
                            label: Text(priority),
                            selected: _task.priority == priority,
                            onSelected: _isDeleting
                                ? null
                                : (_) => _setPriority(priority),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Status'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusTag(status: _task.status),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in const [
                        'To Do',
                        'In Progress',
                        'Completed',
                      ])
                        ChoiceChip(
                          label: Text(status),
                          selected: _task.status == status,
                          onSelected: _isDeleting
                              ? null
                              : (_) => _setStatus(status),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due date'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(_formatDueDate(_task.dueDate)),
                  if (_task.isOverdue) const OverdueBadge(),
                ],
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Assignee'),
            subtitle: Text(_task.assigneeName),
          ),
          if (_isManager) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDeleting ? null : _openEditForm,
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDeleting ? null : _openReassignDialog,
                    child: const Text('Assign'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _isDeleting ? null : _confirmDelete,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
          if (_task.id != null) ...[
            const SizedBox(height: 32),
            TaskCommentsSection(taskId: _task.id!),
          ],
        ],
      ),
    );
  }
}

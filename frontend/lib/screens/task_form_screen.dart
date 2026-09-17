import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.existingTask});

  final Task? existingTask;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  static const _priorities = ['Low', 'Medium', 'High'];
  static const _statuses = ['To Do', 'In Progress', 'Completed'];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<AppUser> _users = [];
  AppUser? _assignee;
  String _priority = 'Medium';
  String _status = 'To Do';
  DateTime? _dueDate;
  bool _isLoadingUsers = true;
  bool _isSaving = false;
  String? _validationError;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTask;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _priority = existing.priority;
      _status = existing.status;
      _dueDate = existing.dueDate;
    }
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await ApiService.instance.getUsers();
    if (!mounted) {
      return;
    }
    AppUser? assignee;
    final existingAssigneeId = widget.existingTask?.assignee;
    if (existingAssigneeId != null) {
      for (final user in users) {
        if (user.id == existingAssigneeId) {
          assignee = user;
          break;
        }
      }
    }
    setState(() {
      _users = users;
      _assignee = assignee ?? (users.isEmpty ? null : users.first);
      _isLoadingUsers = false;
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: _isEditing ? DateTime(now.year - 5) : today,
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() {
        _dueDate = selected;
      });
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _dueDate == null) {
      setState(() {
        _validationError = 'Title and due date are required';
      });
      return;
    }
    if (_assignee == null) {
      setState(() {
        _validationError = 'An assignee is required';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _validationError = null;
    });

    final task = Task(
      id: widget.existingTask?.id,
      title: title,
      description: _descriptionController.text.trim(),
      priority: _priority,
      status: _status,
      dueDate: _dueDate!,
      assignee: _assignee!.id,
      assigneeName: _assignee!.username,
      isOverdue: false,
    );

    final success = _isEditing
        ? await ApiService.instance.updateTask(task)
        : await ApiService.instance.createTask(task);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not save task')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'New Task')),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  enabled: !_isSaving,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: _priorities
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _priority = value;
                            });
                          }
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _statuses
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _status = value;
                            });
                          }
                        },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due date'),
                  subtitle: Text(
                    _dueDate == null ? 'Select a date' : _formatDate(_dueDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _isSaving ? null : _pickDueDate,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AppUser>(
                  initialValue: _assignee,
                  decoration: const InputDecoration(
                    labelText: 'Assignee',
                    border: OutlineInputBorder(),
                  ),
                  items: _users
                      .map(
                        (user) => DropdownMenuItem(
                          value: user,
                          child: Text(user.username),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _assignee = value;
                          });
                        },
                ),
                if (_validationError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _validationError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
    );
  }
}

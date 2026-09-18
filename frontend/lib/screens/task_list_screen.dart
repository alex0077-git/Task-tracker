import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/api_service.dart';
import '../widgets/overdue_badge.dart';
import '../widgets/priority_tag.dart';
import '../widgets/status_tag.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _sortByPriority = false;
  bool _overdueOnly = false;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    final tasks = await ApiService.instance.getTasks(
      overdueOnly: _overdueOnly,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = value.trim();
      if (trimmed == _searchQuery) {
        return;
      }
      setState(() {
        _searchQuery = trimmed;
      });
      _loadTasks();
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_searchQuery.isEmpty) {
      return;
    }
    setState(() {
      _searchQuery = '';
    });
    _loadTasks();
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
    if (_overdueOnly || _searchQuery.isNotEmpty) {
      await _loadTasks();
    }
    if (!mounted) {
      return;
    }
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

  String get _emptyMessage {
    if (_searchQuery.isNotEmpty) {
      return 'No tasks found';
    }
    if (_overdueOnly) {
      return 'No overdue tasks';
    }
    return 'No tasks yet';
  }

  void _togglePrioritySort() {
    setState(() {
      _sortByPriority = !_sortByPriority;
    });
  }

  void _toggleOverdueFilter(bool selected) {
    setState(() {
      _overdueOnly = selected;
    });
    _loadTasks();
  }

  String _formatDueDate(DateTime date) {
    return 'Due: ${DateFormat('d MMM yyyy').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search tasks by title',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear search',
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _onSearchChanged(value);
                  },
                ),
                const SizedBox(height: 8),
                FilterChip(
                  label: const Text('Overdue only'),
                  selected: _overdueOnly,
                  onSelected: _toggleOverdueFilter,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: _visibleTasks.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              Center(child: Text(_emptyMessage)),
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
                                clipBehavior: Clip.antiAlias,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: task.isOverdue
                                            ? const Color(0xFFC62828)
                                            : Colors.transparent,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(task.title),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(task.assigneeName),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(_formatDueDate(task.dueDate)),
                                            if (task.isOverdue)
                                              const OverdueBadge(),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            PriorityTag(
                                              priority: task.priority,
                                            ),
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
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        tooltip: 'Create task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

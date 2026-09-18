import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/api_service.dart';
import '../shared/task_list_controller.dart';
import '../widgets/overdue_badge.dart';
import '../widgets/priority_tag.dart';
import '../widgets/task_status_style.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final TaskListController _query;
  bool _sortByPriority = false;

  @override
  void initState() {
    super.initState();
    _query = TaskListController(includeOverdueFilter: true)
      ..addListener(_onQueryChanged);
    _query.loadUsers();
    _query.loadTasks();
  }

  void _onQueryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _query
      ..removeListener(_onQueryChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _openCreateForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskFormScreen()),
    );
    await _query.loadTasks();
  }

  Future<void> _openTaskDetail(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
    await _query.loadTasks();
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

    _query.replaceTask(_taskWithStatus(task, newStatus));
    if (_query.hasActiveFilters) {
      await _query.loadTasks();
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to $newStatus')),
    );
  }

  List<Task> get _visibleTasks =>
      _query.tasksSortedByPriority(_sortByPriority);

  String get _emptyMessage {
    if (_query.hasActiveFilters) {
      return 'No tasks found';
    }
    return 'No tasks yet';
  }

  void _togglePrioritySort() {
    setState(() {
      _sortByPriority = !_sortByPriority;
    });
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
            onPressed: _query.isLoading ? null : _query.loadTasks,
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
                  controller: _query.searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search tasks by title',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _query.clearSearch,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear search',
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _query.onSearchChanged(value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('status-${_query.filterVersion}'),
                        initialValue: _query.statusFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: TaskListController.statuses
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          _query.setStatusFilter(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('priority-${_query.filterVersion}'),
                        initialValue: _query.priorityFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: TaskListController.priorities
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          _query.setPriorityFilter(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        key: ValueKey('assignee-${_query.filterVersion}'),
                        initialValue: _query.assigneeFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Assignee',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All'),
                          ),
                          for (final user in _query.users)
                            DropdownMenuItem<int?>(
                              value: user.id,
                              child: Text(user.username),
                            ),
                        ],
                        onChanged: _query.setAssigneeFilter,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Overdue only'),
                      selected: _query.overdueOnly,
                      onSelected: _query.setOverdueOnly,
                    ),
                    if (_query.hasActiveFilters)
                      ActionChip(
                        label: const Text('Clear Filters'),
                        avatar: const Icon(Icons.filter_alt_off, size: 18),
                        onPressed: _query.clearFilters,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _query.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _query.loadTasks,
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

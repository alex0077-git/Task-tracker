import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/task.dart';
import '../../screens/task_detail_screen.dart';
import '../../screens/task_form_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/priority_tag.dart';
import '../../widgets/task_status_style.dart';
import '../desktop_theme.dart';

class DesktopTasksScreen extends StatefulWidget {
  const DesktopTasksScreen({
    super.key,
    this.refreshToken = 0,
    this.onDataChanged,
    this.isManager = true,
  });

  final int refreshToken;
  final VoidCallback? onDataChanged;
  final bool isManager;

  static const statuses = ['All', 'To Do', 'In Progress', 'Completed'];
  static const priorities = ['All', 'Low', 'Medium', 'High'];

  @override
  State<DesktopTasksScreen> createState() => _DesktopTasksScreenState();
}

class _DesktopTasksScreenState extends State<DesktopTasksScreen> {
  static const _allOption = 'All';
  static const _pageSize = 5;

  final _searchController = TextEditingController();
  final _selectedIds = <int>{};

  List<Task> _tasks = [];
  List<AppUser> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = _allOption;
  String _priorityFilter = _allOption;
  int? _assigneeFilter;
  int _filterVersion = 0;
  int _page = 0;
  Timer? _searchDebounce;

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _statusFilter != _allOption ||
      _priorityFilter != _allOption ||
      (widget.isManager && _assigneeFilter != null);

  int get _pageCount {
    if (_tasks.isEmpty) {
      return 1;
    }
    return (_tasks.length / _pageSize).ceil();
  }

  List<Task> get _pageTasks {
    final start = _page * _pageSize;
    if (start >= _tasks.length) {
      return const [];
    }
    final end = (start + _pageSize).clamp(0, _tasks.length);
    return _tasks.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant DesktopTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadUsers();
      _loadTasks();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!widget.isManager) {
      return;
    }
    final users = await ApiService.instance.getUsers();
    if (!mounted) {
      return;
    }
    setState(() {
      _users = users;
    });
  }

  Future<void> _loadTasks({bool notifyChanged = false}) async {
    setState(() {
      _isLoading = true;
    });
    final tasks = await ApiService.instance.getTasks(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      statusFilter: _statusFilter == _allOption ? null : _statusFilter,
      priorityFilter: _priorityFilter == _allOption ? null : _priorityFilter,
      assigneeFilter: _assigneeFilter,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _tasks = tasks;
      _isLoading = false;
      _selectedIds.removeWhere(
        (id) => tasks.every((task) => task.id != id),
      );
      if (_page >= _pageCount) {
        _page = _pageCount - 1;
      }
      if (_page < 0) {
        _page = 0;
      }
    });
    if (notifyChanged) {
      widget.onDataChanged?.call();
    }
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
        _page = 0;
      });
      _loadTasks();
    });
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _statusFilter = _allOption;
      _priorityFilter = _allOption;
      _assigneeFilter = null;
      _filterVersion += 1;
      _page = 0;
    });
    _loadTasks();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const TaskFormScreen()),
    );
    if (created == true) {
      await _loadTasks(notifyChanged: true);
    }
  }

  Future<void> _openEdit(Task task) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(existingTask: task),
      ),
    );
    if (saved == true) {
      await _loadTasks(notifyChanged: true);
    }
  }

  Future<void> _openDetails(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
    await _loadTasks(notifyChanged: true);
  }

  Future<void> _confirmDelete(Task task) async {
    if (task.id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm deletion'),
          content: Text('Delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: DesktopColors.danger,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final success = await ApiService.instance.deleteTask(task.id!);
    if (!mounted) {
      return;
    }
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete task')),
      );
      return;
    }
    await _loadTasks(notifyChanged: true);
  }

  String _statusLabel(Task task) {
    if (task.isOverdue) {
      return 'Overdue';
    }
    if (task.status == 'To Do') {
      return 'Pending';
    }
    return task.status;
  }

  @override
  Widget build(BuildContext context) {
    final start = _tasks.isEmpty ? 0 : (_page * _pageSize) + 1;
    final end = _tasks.isEmpty
        ? 0
        : ((_page + 1) * _pageSize).clamp(0, _tasks.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.isManager ? 'Tasks' : 'My Tasks',
                  style: const TextStyle(
                    color: DesktopColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (widget.isManager)
                FilledButton.icon(
                  onPressed: _openCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: DesktopColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Task'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _FiltersBar(
            searchController: _searchController,
            statusFilter: _statusFilter,
            priorityFilter: _priorityFilter,
            assigneeFilter: _assigneeFilter,
            users: _users,
            filterVersion: _filterVersion,
            hasActiveFilters: _hasActiveFilters,
            showAssigneeFilter: widget.isManager,
            onSearchChanged: _onSearchChanged,
            onStatusChanged: (value) {
              setState(() {
                _statusFilter = value;
                _page = 0;
              });
              _loadTasks();
            },
            onPriorityChanged: (value) {
              setState(() {
                _priorityFilter = value;
                _page = 0;
              });
              _loadTasks();
            },
            onAssigneeChanged: (value) {
              setState(() {
                _assigneeFilter = value;
                _page = 0;
              });
              _loadTasks();
            },
            onClear: _clearFilters,
            onRefresh: _loadTasks,
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
                  : Column(
                      children: [
                        Expanded(
                          child: _pageTasks.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No tasks found',
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
                                        minWidth: MediaQuery.sizeOf(context)
                                                .width -
                                            320,
                                      ),
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                          DesktopColors.background,
                                        ),
                                        dataRowMinHeight: 56,
                                        dataRowMaxHeight: 64,
                                        columns: const [
                                          DataColumn(label: Text('')),
                                          DataColumn(label: Text('Task')),
                                          DataColumn(label: Text('Assignee')),
                                          DataColumn(label: Text('Priority')),
                                          DataColumn(label: Text('Due Date')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: [
                                          for (final task in _pageTasks)
                                            DataRow(
                                              cells: [
                                                DataCell(
                                                  Checkbox(
                                                    value: task.id != null &&
                                                        _selectedIds
                                                            .contains(task.id),
                                                    onChanged: task.id == null
                                                        ? null
                                                        : (checked) {
                                                            setState(() {
                                                              if (checked ==
                                                                  true) {
                                                                _selectedIds
                                                                    .add(
                                                                  task.id!,
                                                                );
                                                              } else {
                                                                _selectedIds
                                                                    .remove(
                                                                  task.id,
                                                                );
                                                              }
                                                            });
                                                          },
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    task.title,
                                                    style: const TextStyle(
                                                      color: DesktopColors
                                                          .textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  onTap: () =>
                                                      _openDetails(task),
                                                ),
                                                DataCell(
                                                  Text(
                                                    task.assigneeName,
                                                    style: const TextStyle(
                                                      color: DesktopColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  PriorityTag(
                                                    priority: task.priority,
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    DateFormat('d MMM yyyy')
                                                        .format(task.dueDate),
                                                    style: const TextStyle(
                                                      color: DesktopColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  _StatusPill(
                                                    label: _statusLabel(task),
                                                    color:
                                                        TaskStatusStyle
                                                            .colorFor(task),
                                                  ),
                                                ),
                                                DataCell(
                                                  PopupMenuButton<String>(
                                                    tooltip: 'Actions',
                                                    onSelected: (value) {
                                                      switch (value) {
                                                        case 'view':
                                                          _openDetails(task);
                                                        case 'edit':
                                                          _openEdit(task);
                                                        case 'delete':
                                                          _confirmDelete(task);
                                                      }
                                                    },
                                                    itemBuilder: (context) {
                                                      if (widget.isManager) {
                                                        return const [
                                                          PopupMenuItem(
                                                            value: 'view',
                                                            child: Text(
                                                              'View details',
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Text('Edit'),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'delete',
                                                            child: Text(
                                                              'Delete',
                                                            ),
                                                          ),
                                                        ];
                                                      }
                                                      return const [
                                                        PopupMenuItem(
                                                          value: 'view',
                                                          child: Text(
                                                            'View details',
                                                          ),
                                                        ),
                                                      ];
                                                    },
                                                    icon: const Icon(
                                                      Icons.more_horiz,
                                                      color: DesktopColors
                                                          .textSecondary,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: DesktopColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Showing $start–$end of ${_tasks.length}',
                                style: const TextStyle(
                                  color: DesktopColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _page > 0
                                    ? () {
                                        setState(() {
                                          _page -= 1;
                                        });
                                      }
                                    : null,
                                child: const Text('Previous'),
                              ),
                              const SizedBox(width: 8),
                              for (var i = 0; i < _pageCount; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: i == _page
                                          ? DesktopColors.primarySoft
                                          : null,
                                      foregroundColor: i == _page
                                          ? DesktopColors.primary
                                          : DesktopColors.textSecondary,
                                      minimumSize: const Size(36, 36),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _page = i;
                                      });
                                    },
                                    child: Text('${i + 1}'),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _page < _pageCount - 1
                                    ? () {
                                        setState(() {
                                          _page += 1;
                                        });
                                      }
                                    : null,
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.searchController,
    required this.statusFilter,
    required this.priorityFilter,
    required this.assigneeFilter,
    required this.users,
    required this.filterVersion,
    required this.hasActiveFilters,
    required this.showAssigneeFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onAssigneeChanged,
    required this.onClear,
    required this.onRefresh,
  });

  final TextEditingController searchController;
  final String statusFilter;
  final String priorityFilter;
  final int? assigneeFilter;
  final List<AppUser> users;
  final int filterVersion;
  final bool hasActiveFilters;
  final bool showAssigneeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<int?> onAssigneeChanged;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
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
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            key: ValueKey('status-$filterVersion'),
            initialValue: statusFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: DesktopTasksScreen.statuses
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value == 'All' ? 'All Status' : value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onStatusChanged(value);
              }
            },
          ),
        ),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            key: ValueKey('priority-$filterVersion'),
            initialValue: priorityFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Priority',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: DesktopTasksScreen.priorities
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value == 'All' ? 'All Priority' : value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onPriorityChanged(value);
              }
            },
          ),
        ),
        if (showAssigneeFilter)
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<int?>(
              key: ValueKey('assignee-$filterVersion'),
              initialValue: assigneeFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Assignee',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All'),
                ),
                for (final user in users)
                  DropdownMenuItem<int?>(
                    value: user.id,
                    child: Text(user.username),
                  ),
              ],
              onChanged: onAssigneeChanged,
            ),
          ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
        if (hasActiveFilters)
          ActionChip(
            label: const Text('Clear Filters'),
            onPressed: onClear,
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

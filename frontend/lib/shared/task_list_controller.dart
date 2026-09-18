import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../services/api_service.dart';

/// Shared task-list query state used by mobile and desktop task screens.
/// Layout stays in each screen; only filter/load logic lives here.
class TaskListController extends ChangeNotifier {
  TaskListController({
    this.includeAssigneeUsers = true,
    this.includeOverdueFilter = false,
    this.onQueryChanged,
  });

  static const allOption = 'All';
  static const statuses = ['All', 'To Do', 'In Progress', 'Completed'];
  static const priorities = ['All', 'Low', 'Medium', 'High'];

  /// When false (employee desktop), skip loading the users list.
  final bool includeAssigneeUsers;

  /// When true (mobile), overdue filter participates in active-filter checks.
  final bool includeOverdueFilter;

  /// Called when search/filters change (e.g. desktop resets pagination).
  final VoidCallback? onQueryChanged;

  final TextEditingController searchController = TextEditingController();

  List<Task> tasks = [];
  List<AppUser> users = [];
  bool isLoading = true;
  String searchQuery = '';
  String statusFilter = allOption;
  String priorityFilter = allOption;
  int? assigneeFilter;
  bool overdueOnly = false;
  int filterVersion = 0;

  Timer? _searchDebounce;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      (includeOverdueFilter && overdueOnly) ||
      statusFilter != allOption ||
      priorityFilter != allOption ||
      (includeAssigneeUsers && assigneeFilter != null);

  Future<void> loadUsers() async {
    if (!includeAssigneeUsers) {
      return;
    }
    final loaded = await ApiService.instance.getUsers();
    users = loaded;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    isLoading = true;
    notifyListeners();
    final loaded = await ApiService.instance.getTasks(
      overdueOnly: includeOverdueFilter ? overdueOnly : false,
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      statusFilter: statusFilter == allOption ? null : statusFilter,
      priorityFilter: priorityFilter == allOption ? null : priorityFilter,
      assigneeFilter: assigneeFilter,
    );
    tasks = loaded;
    isLoading = false;
    notifyListeners();
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = value.trim();
      if (trimmed == searchQuery) {
        return;
      }
      searchQuery = trimmed;
      onQueryChanged?.call();
      notifyListeners();
      loadTasks();
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchController.clear();
    if (searchQuery.isEmpty) {
      return;
    }
    searchQuery = '';
    onQueryChanged?.call();
    notifyListeners();
    loadTasks();
  }

  void clearFilters() {
    _searchDebounce?.cancel();
    searchController.clear();
    searchQuery = '';
    overdueOnly = false;
    statusFilter = allOption;
    priorityFilter = allOption;
    assigneeFilter = null;
    filterVersion += 1;
    onQueryChanged?.call();
    notifyListeners();
    loadTasks();
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    onQueryChanged?.call();
    notifyListeners();
    loadTasks();
  }

  void setPriorityFilter(String value) {
    priorityFilter = value;
    onQueryChanged?.call();
    notifyListeners();
    loadTasks();
  }

  void setAssigneeFilter(int? value) {
    assigneeFilter = value;
    onQueryChanged?.call();
    notifyListeners();
    loadTasks();
  }

  void setOverdueOnly(bool selected) {
    overdueOnly = selected;
    onQueryChanged?.call();
    notifyListeners();
    loadTasks();
  }

  /// Client-side High-first sort used by the mobile list.
  List<Task> tasksSortedByPriority(bool enabled) {
    if (!enabled) {
      return tasks;
    }
    const rank = {'High': 0, 'Medium': 1, 'Low': 2};
    return [...tasks]..sort((a, b) {
      return (rank[a.priority] ?? 3).compareTo(rank[b.priority] ?? 3);
    });
  }

  void replaceTask(Task updated) {
    tasks = [
      for (final item in tasks)
        if (item.id == updated.id) updated else item,
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}

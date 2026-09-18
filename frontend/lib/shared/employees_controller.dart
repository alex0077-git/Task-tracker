import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../models/task_counts.dart';
import '../services/api_service.dart';

/// Shared employees roster load: getUsers + getTasks, then per-user counts.
class EmployeesController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  List<AppUser> users = [];
  List<Task> tasks = [];
  bool isLoading = true;
  String searchQuery = '';

  Timer? _searchDebounce;

  List<AppUser> get visibleUsers {
    final query = searchQuery.toLowerCase();
    if (query.isEmpty) {
      return users;
    }
    return users.where((user) {
      return user.username.toLowerCase().startsWith(query) ||
          user.email.toLowerCase().startsWith(query);
    }).toList();
  }

  List<Task> tasksFor(AppUser user) {
    return tasks.where((task) => task.assignee == user.id).toList();
  }

  int assignedCount(AppUser user) => tasksFor(user).length;

  TaskCounts countsFor(AppUser user) => TaskCounts.fromTasks(tasksFor(user));

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final results = await Future.wait([
      ApiService.instance.getUsers(),
      ApiService.instance.getTasks(),
    ]);
    users = results[0] as List<AppUser>;
    tasks = results[1] as List<Task>;
    isLoading = false;
    notifyListeners();
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      searchQuery = value.trim();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}

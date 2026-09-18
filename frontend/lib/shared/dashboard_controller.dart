import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../models/task_counts.dart';
import '../services/api_service.dart';

/// Shared dashboard load: getTasks → TaskCounts.fromTasks.
/// Mobile and desktop keep their own layouts.
class DashboardController extends ChangeNotifier {
  List<Task> tasks = [];
  TaskCounts counts = const TaskCounts(
    toDo: 0,
    pending: 0,
    completed: 0,
    overdue: 0,
  );
  bool isLoading = true;

  List<Task> get recentTasks => tasks.take(5).toList();

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final loaded = await ApiService.instance.getTasks();
    tasks = loaded;
    counts = TaskCounts.fromTasks(loaded);
    isLoading = false;
    notifyListeners();
  }
}

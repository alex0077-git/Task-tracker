import 'task.dart';

class TaskCounts {
  const TaskCounts({
    required this.toDo,
    required this.pending,
    required this.completed,
    required this.overdue,
  });

  final int toDo;
  final int pending;
  final int completed;
  final int overdue;

  int get total => toDo + pending + completed + overdue;

  int get maxValue {
    final values = [toDo, pending, completed, overdue];
    return values.reduce((a, b) => a > b ? a : b);
  }

  factory TaskCounts.fromTasks(Iterable<Task> tasks) {
    var toDo = 0;
    var pending = 0;
    var completed = 0;
    var overdue = 0;

    for (final task in tasks) {
      if (task.isOverdue) {
        overdue += 1;
      } else if (task.status == 'Completed') {
        completed += 1;
      } else if (task.status == 'In Progress') {
        pending += 1;
      } else {
        toDo += 1;
      }
    }

    return TaskCounts(
      toDo: toDo,
      pending: pending,
      completed: completed,
      overdue: overdue,
    );
  }
}

import '../models/task.dart';

/// Shared date helpers for task due dates and overdue checks.
String formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// True when due date is before today and status is not Completed.
bool isTaskOverdue(Task task) {
  return isDueDateOverdue(task.dueDate, task.status);
}

bool isDueDateOverdue(DateTime dueDate, String status) {
  if (status == 'Completed') {
    return false;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  return due.isBefore(today);
}

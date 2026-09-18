import 'package:flutter/material.dart';

import '../models/task.dart';

/// Single source of truth for task status colors and labels.
class TaskStatusStyle {
  static const completed = Color(0xFF2E7D32);
  static const pending = Color(0xFFEF6C00);
  static const overdue = Color(0xFFC62828);
  static const toDo = Color(0xFF9E9E9E);

  static Color colorFor(Task task) {
    if (task.isOverdue) {
      return overdue;
    }
    switch (task.status) {
      case 'Completed':
        return completed;
      case 'In Progress':
        return pending;
      default:
        return toDo;
    }
  }

  static String labelFor(Task task) {
    if (task.isOverdue) {
      return 'Overdue';
    }
    if (task.status == 'In Progress') {
      return 'Pending';
    }
    return task.status;
  }

  /// Chip background colors used by [StatusTag] (list/detail pills).
  static Color chipBackgroundFor(String status) {
    switch (status) {
      case 'In Progress':
        return const Color(0xFFFFE0B2);
      case 'Completed':
        return const Color(0xFFC8E6C9);
      case 'To Do':
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  static Color chipTextFor(String status) {
    switch (status) {
      case 'In Progress':
        return const Color(0xFFE65100);
      case 'Completed':
        return const Color(0xFF2E7D32);
      case 'To Do':
      default:
        return const Color(0xFF424242);
    }
  }
}

/// Status pill for list/detail screens — colors from [TaskStatusStyle].
class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TaskStatusStyle.chipBackgroundFor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: TaskStatusStyle.chipTextFor(status),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/task.dart';

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
}

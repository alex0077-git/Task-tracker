import '../utils/date_utils.dart';

class Task {
  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.assignee,
    required this.assigneeName,
    required this.isOverdue,
  });

  final int? id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime dueDate;
  final int assignee;
  final String assigneeName;
  final bool isOverdue;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String,
      status: json['status'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      assignee: json['assignee'] as int,
      assigneeName: json['assignee_name'] as String? ?? '',
      isOverdue: json['is_overdue'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'due_date': formatDate(dueDate),
      'assignee': assignee,
      'assignee_name': assigneeName,
      'is_overdue': isOverdue,
    };
  }
}

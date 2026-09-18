import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import 'overdue_badge.dart';
import 'priority_tag.dart';
import 'task_status_style.dart';

/// Shared assigned-task card for employee home and user-tasks screens.
/// Pass [onEdit] to show the edit action (manager user-tasks view).
class AssignedTaskCard extends StatelessWidget {
  const AssignedTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onEdit,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final showEdit = onEdit != null;

    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: showEdit
              ? const EdgeInsets.fromLTRB(16, 12, 8, 12)
              : const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: TaskStatusStyle.colorFor(task),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      TaskStatusStyle.labelFor(task),
                      style: TextStyle(
                        color: TaskStatusStyle.colorFor(task),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriorityTag(priority: task.priority),
                        Text(
                          'Due ${DateFormat('d MMM yyyy').format(task.dueDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (task.isOverdue) const OverdueBadge(),
                      ],
                    ),
                  ],
                ),
              ),
              if (showEdit)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

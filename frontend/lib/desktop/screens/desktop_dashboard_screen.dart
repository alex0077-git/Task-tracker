import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../models/task_counts.dart';
import '../../services/api_service.dart';
import '../../widgets/priority_tag.dart';
import '../../widgets/task_status_style.dart';
import '../desktop_theme.dart';

class DesktopDashboardScreen extends StatefulWidget {
  const DesktopDashboardScreen({
    super.key,
    required this.onViewAllTasks,
    this.refreshToken = 0,
  });

  final VoidCallback onViewAllTasks;
  final int refreshToken;

  @override
  State<DesktopDashboardScreen> createState() => _DesktopDashboardScreenState();
}

class _DesktopDashboardScreenState extends State<DesktopDashboardScreen> {
  List<Task> _tasks = [];
  TaskCounts _counts = const TaskCounts(
    toDo: 0,
    pending: 0,
    completed: 0,
    overdue: 0,
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant DesktopDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadDashboard();
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
    });
    final tasks = await ApiService.instance.getTasks();
    if (!mounted) {
      return;
    }
    setState(() {
      _tasks = tasks;
      _counts = TaskCounts.fromTasks(tasks);
      _isLoading = false;
    });
  }

  List<Task> get _recentTasks => _tasks.take(5).toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                color: DesktopColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Here's an overview of your tasks.",
              style: TextStyle(
                color: DesktopColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final cards = [
                  _SummaryCard(
                    label: 'Total Tasks',
                    value: _counts.total,
                    icon: Icons.assignment_outlined,
                    tint: DesktopColors.primarySoft,
                    iconColor: DesktopColors.primary,
                  ),
                  _SummaryCard(
                    label: 'In Progress',
                    value: _counts.pending,
                    icon: Icons.timelapse_outlined,
                    tint: const Color(0xFFF3EEFF),
                    iconColor: DesktopColors.inProgress,
                  ),
                  _SummaryCard(
                    label: 'Completed',
                    value: _counts.completed,
                    icon: Icons.check_circle_outline,
                    tint: const Color(0xFFE8F8EF),
                    iconColor: DesktopColors.success,
                  ),
                  _SummaryCard(
                    label: 'Overdue',
                    value: _counts.overdue,
                    icon: Icons.warning_amber_rounded,
                    tint: const Color(0xFFFDECEC),
                    iconColor: DesktopColors.danger,
                  ),
                ];

                if (wide) {
                  return Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                }

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: (constraints.maxWidth - 16) / 2,
                        child: card,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 960;
                final recent = _RecentTasksCard(
                  tasks: _recentTasks,
                  onViewAll: widget.onViewAllTasks,
                );
                final chart = _TasksByStatusCard(counts: _counts);

                if (sideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: recent),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: chart),
                    ],
                  );
                }

                return Column(
                  children: [
                    recent,
                    const SizedBox(height: 16),
                    chart,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesktopColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesktopColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: DesktopColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: DesktopColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _RecentTasksCard extends StatelessWidget {
  const _RecentTasksCard({
    required this.tasks,
    required this.onViewAll,
  });

  final List<Task> tasks;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: DesktopColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesktopColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Tasks',
                  style: TextStyle(
                    color: DesktopColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No tasks yet',
                  style: TextStyle(color: DesktopColors.textSecondary),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.4),
                1: FlexColumnWidth(1.1),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  children: [
                    _HeaderCell('Task'),
                    _HeaderCell('Priority'),
                    _HeaderCell('Due Date'),
                    _HeaderCell('Status'),
                  ],
                ),
                for (final task in tasks)
                  TableRow(
                    children: [
                      _BodyCell(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DesktopColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _BodyCell(child: PriorityTag(priority: task.priority)),
                      _BodyCell(
                        child: Text(
                          DateFormat('d MMM yyyy').format(task.dueDate),
                          style: const TextStyle(
                            color: DesktopColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _BodyCell(
                        child: _StatusPill(
                          label: TaskStatusStyle.labelFor(task),
                          color: TaskStatusStyle.colorFor(task),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: DesktopColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
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
      ),
    );
  }
}

class _TasksByStatusCard extends StatelessWidget {
  const _TasksByStatusCard({required this.counts});

  final TaskCounts counts;

  @override
  Widget build(BuildContext context) {
    final sections = [
      _ChartSection('Pending', counts.toDo, DesktopColors.pending),
      _ChartSection('In Progress', counts.pending, DesktopColors.inProgress),
      _ChartSection('Completed', counts.completed, DesktopColors.success),
      _ChartSection('Overdue', counts.overdue, DesktopColors.danger),
    ];
    final total = counts.total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesktopColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesktopColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasks by Status',
            style: TextStyle(
              color: DesktopColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sectionsSpace: 3,
                        centerSpaceRadius: 48,
                        sections: total == 0
                            ? [
                                PieChartSectionData(
                                  value: 1,
                                  color: DesktopColors.border,
                                  radius: 22,
                                  showTitle: false,
                                ),
                              ]
                            : [
                                for (final section in sections)
                                  if (section.count > 0)
                                    PieChartSectionData(
                                      value: section.count.toDouble(),
                                      color: section.color,
                                      radius: 22,
                                      showTitle: false,
                                    ),
                              ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: DesktopColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          total == 1 ? 'Task' : 'Tasks',
                          style: const TextStyle(
                            color: DesktopColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < sections.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: sections[i].color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sections[i].label,
                              style: const TextStyle(
                                color: DesktopColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${sections[i].count}',
                            style: const TextStyle(
                              color: DesktopColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartSection {
  const _ChartSection(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

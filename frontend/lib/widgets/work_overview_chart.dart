import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/task_counts.dart';

class WorkOverviewChart extends StatelessWidget {
  const WorkOverviewChart({super.key, required this.counts});

  final TaskCounts counts;

  static const _pending = Color(0xFF2F80ED);
  static const _inProgress = Color(0xFF9B8AFB);
  static const _completed = Color(0xFF27C46A);
  static const _overdue = Color(0xFFEB5757);

  List<_LegendItem> get _legendItems => [
    _LegendItem(_pending, 'Pending', counts.toDo),
    _LegendItem(_inProgress, 'In Progress', counts.pending),
    _LegendItem(_completed, 'Completed', counts.completed),
    _LegendItem(_overdue, 'Overdue', counts.overdue),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks by Status',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B2559),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 148,
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(148),
                      painter: _DonutPainter(
                        slices: [
                          _Slice(counts.toDo, _pending),
                          _Slice(counts.pending, _inProgress),
                          _Slice(counts.completed, _completed),
                          _Slice(counts.overdue, _overdue),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${counts.total}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B2559),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          counts.total == 1 ? 'Task' : 'Tasks',
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8F9BBA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    for (var index = 0; index < _legendItems.length; index++) ...[
                      if (index > 0) const SizedBox(height: 12),
                      _LegendRow(item: _legendItems[index]),
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

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.item});

  final _LegendItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(
              color: Color(0xFF6B7A99),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${item.count}',
          style: const TextStyle(
            color: Color(0xFF1B2559),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LegendItem {
  const _LegendItem(this.color, this.label, this.count);

  final Color color;
  final String label;
  final int count;
}

class _Slice {
  const _Slice(this.value, this.color);

  final int value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices});

  final List<_Slice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;

    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    if (total == 0) {
      paint.color = const Color(0xFFE8EEF7);
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    const gap = 0.12;
    for (final slice in slices) {
      if (slice.value <= 0) {
        continue;
      }
      final sweep = (slice.value / total) * math.pi * 2;
      paint.color = slice.color;
      canvas.drawArc(
        rect,
        startAngle + (gap / 2),
        math.max(sweep - gap, 0.04),
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (oldDelegate.slices.length != slices.length) {
      return true;
    }
    for (var index = 0; index < slices.length; index++) {
      final current = slices[index];
      final previous = oldDelegate.slices[index];
      if (current.value != previous.value || current.color != previous.color) {
        return true;
      }
    }
    return false;
  }
}

import 'package:flutter/material.dart';

class PriorityTag extends StatelessWidget {
  const PriorityTag({super.key, required this.priority});

  final String priority;

  Color get _backgroundColor {
    switch (priority) {
      case 'High':
        return const Color(0xFFFFCDD2);
      case 'Medium':
        return const Color(0xFFFFE0B2);
      case 'Low':
      default:
        return const Color(0xFFC8E6C9);
    }
  }

  Color get _textColor {
    switch (priority) {
      case 'High':
        return const Color(0xFFC62828);
      case 'Medium':
        return const Color(0xFFE65100);
      case 'Low':
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.status});

  final String status;

  Color get _backgroundColor {
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

  Color get _textColor {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

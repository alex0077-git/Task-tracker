import 'package:flutter/material.dart';

import '../models/task_counts.dart';
import '../services/api_service.dart';
import '../widgets/work_overview_chart.dart';
import 'task_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
    });
    final tasks = await ApiService.instance.getTasks();
    if (!mounted) {
      return;
    }
    setState(() {
      _counts = TaskCounts.fromTasks(tasks);
      _isLoading = false;
    });
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const TaskFormScreen()),
    );
    if (created == true) {
      await _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        tooltip: 'Create task',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                children: [
                  WorkOverviewChart(counts: _counts),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';

import '../shared/dashboard_controller.dart';
import '../widgets/work_overview_chart.dart';
import 'task_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboard = DashboardController();

  @override
  void initState() {
    super.initState();
    _dashboard.addListener(_onChanged);
    _dashboard.load();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _dashboard
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const TaskFormScreen()),
    );
    if (created == true) {
      await _dashboard.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: _dashboard.isLoading ? null : _dashboard.load,
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
      body: _dashboard.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _dashboard.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                children: [
                  WorkOverviewChart(counts: _dashboard.counts),
                ],
              ),
            ),
    );
  }
}

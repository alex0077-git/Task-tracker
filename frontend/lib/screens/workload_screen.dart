import 'package:flutter/material.dart';

import '../services/api_service.dart';

class WorkloadScreen extends StatefulWidget {
  const WorkloadScreen({super.key});

  @override
  State<WorkloadScreen> createState() => _WorkloadScreenState();
}

class _WorkloadScreenState extends State<WorkloadScreen> {
  List<Map<String, dynamic>> _workload = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkload();
  }

  Future<void> _loadWorkload() async {
    setState(() {
      _isLoading = true;
    });
    final workload = await ApiService.instance.getUserWorkload();
    if (!mounted) {
      return;
    }
    setState(() {
      _workload = workload;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workload'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadWorkload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWorkload,
              child: _workload.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No users found')),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _workload.length,
                      itemBuilder: (context, index) {
                        final user = _workload[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text('${user['username']}'),
                            subtitle: Text(
                              'Total: ${user['total_tasks']}  •  '
                              'Completed: ${user['completed']}  •  '
                              'Pending: ${user['pending']}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

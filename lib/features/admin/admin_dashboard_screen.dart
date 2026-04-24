import 'package:flutter/material.dart';

import '../../data/fake_data.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tasks total: ${fakeTasks.length}'),
          const Text('Users total: 3 (mock)'),
          const Text('Disputes: 1 (mock)'),
          const Divider(),
          ...fakeTasks.map(
            (task) => Card(
              child: ListTile(
                title: Text(task.title),
                subtitle: Text('Current status: ${task.status.name}'),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'disputed', child: Text('Set disputed')),
                    PopupMenuItem(value: 'cancelled', child: Text('Set cancelled')),
                    PopupMenuItem(value: 'completed', child: Text('Set completed')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

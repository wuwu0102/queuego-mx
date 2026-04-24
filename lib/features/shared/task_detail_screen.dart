import 'package:flutter/material.dart';

import '../../core/models/task_item.dart';
import '../../data/fake_data.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final updates = fakeUpdates.where((u) => u.taskId == task.taskId).toList();
    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(task.description),
          const SizedBox(height: 12),
          Text('Runner: ${task.runnerId ?? 'Unassigned'}'),
          Text('Queue position: ${updates.isNotEmpty ? updates.last.queuePosition ?? '-' : '-'}'),
          Text('Estimated remaining: ${updates.isNotEmpty ? updates.last.estimatedRemainingMinutes ?? '-' : '-'} mins'),
          const Divider(height: 28),
          const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
          ...updates.map(
            (u) => Card(
              child: ListTile(
                title: Text('${u.type}: ${u.message}'),
                subtitle: Text(u.createdAt.toString()),
                trailing: u.photoUrl != null ? const Icon(Icons.image) : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Confirm complete')),
              OutlinedButton(onPressed: () {}, child: const Text('Cancel task')),
              OutlinedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Report / Dispute'),
                    content: const Text('UI placeholder for report/dispute submission and admin review workflow.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                  ),
                ),
                child: const Text('Report issue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

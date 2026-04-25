import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/firestore_task.dart';
import '../../core/services/firestore_task_service.dart';

class RunnerShell extends StatelessWidget {
  const RunnerShell({super.key});

  @override
  Widget build(BuildContext context) {
    final runnerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return OpenTasksPage(runnerId: runnerId);
  }
}

class OpenTasksPage extends StatelessWidget {
  const OpenTasksPage({super.key, required this.runnerId});

  final String runnerId;

  Future<void> _acceptTask(BuildContext context, FirestoreTask task) async {
    if (runnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('尚未登入 anonymous user')),
      );
      return;
    }

    await FirestoreTaskService.instance.markTaskAccepted(
      taskId: task.id,
      runnerId: runnerId,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已接單：${task.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任務列表（status = open）')),
      body: StreamBuilder<List<FirestoreTask>>(
        stream: FirestoreTaskService.instance.streamOpenTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('讀取失敗：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return const Center(child: Text('目前沒有 open 任務'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => _acceptTask(context, task),
                  title: Text(task.title),
                  subtitle: Text(
                    '地點: ${task.location}\n'
                    '備註: ${task.note}\n'
                    '開始: ${task.startDate} ${task.startTime}\n'
                    '時數: ${task.totalHours}（work ${task.workHours} + wait ${task.waitHours}）\n'
                    '價格: ${task.price} MXN\n'
                    '狀態: ${task.status}',
                  ),
                  trailing: const Icon(Icons.check_circle_outline),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

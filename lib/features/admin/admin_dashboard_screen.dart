import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/services/firestore_task_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console')),
      body: StreamBuilder<List<FirestoreTask>>(
        stream: FirestoreTaskService.instance.streamAllTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(s.t('loadDataRetry')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;
          final completedCount = tasks.where((task) => task.status == 'completed').length;
          final cancelledCount = tasks.where((task) => task.status == 'cancelled').length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${s.t('currentMode')}: ${s.t('modeAdmin')}'),
              const SizedBox(height: 8),
              Text('Tasks total: ${tasks.length}'),
              Text('Completed: $completedCount'),
              Text('Cancelled: $cancelledCount'),
              const Divider(),
              ...tasks.map(
                (task) => Card(
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Text(
                      'Status: ${task.status}\n'
                      'Owner: ${task.ownerId}\n'
                      'Completed at: ${_format(task.completedAt)}\n'
                      'Cancelled at: ${_format(task.cancelledAt)}',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _format(DateTime? value) =>
      value == null ? '-' : DateFormat('yyyy-MM-dd HH:mm').format(value);
}

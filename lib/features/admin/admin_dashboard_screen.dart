import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/services/firestore_task_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

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
              Text(s.t('adminInternalOnly')),
              Text(s.t('roleModeNotice')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Español MX'),
                    onPressed: () => onLocaleChanged(const Locale('es', 'MX')),
                  ),
                  ActionChip(
                    label: const Text('English'),
                    onPressed: () => onLocaleChanged(const Locale('en')),
                  ),
                  ActionChip(
                    label: const Text('繁中'),
                    onPressed: () => onLocaleChanged(const Locale('zh', 'TW')),
                  ),
                ],
              ),
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
                      'Owner email: ${task.ownerEmail ?? '-'}\n'
                      'Runner: ${task.runnerId ?? task.accepterId ?? '-'}\n'
                      'Completed at: ${_format(task.completedAt)}\n'
                      'Cancelled at: ${_format(task.cancelledAt)}\n'
                      'Legacy anonymous task: ${_isLegacyAnonymousTask(task) ? s.t('legacyAnonymousTask') : '-'}',
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

  bool _isLegacyAnonymousTask(FirestoreTask task) =>
      task.ownerId.isEmpty || (task.ownerEmail ?? '').isEmpty;
}

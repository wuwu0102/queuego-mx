import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/models/user_metrics.dart';
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
          final statusCounts = <String, int>{
            'open': 0,
            'accepted': 0,
            'arrived': 0,
            'waiting_for_customer': 0,
            'completed': 0,
            'cancelled': 0,
          };
          for (final t in tasks) {
            statusCounts[t.status] = (statusCounts[t.status] ?? 0) + 1;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${s.t('currentMode')}: ${s.t('modeAdmin')}'),
              Text(s.t('adminInternalOnly')),
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
              ...statusCounts.entries.map((e) => Text('${e.key}: ${e.value}')),
              const Divider(),
              const Text('Users'),
              StreamBuilder<List<UserMetrics>>(
                stream: FirestoreTaskService.instance.streamAllUsersMetrics(),
                builder: (context, userSnapshot) {
                  final users = userSnapshot.data ?? const <UserMetrics>[];
                  if (users.isEmpty) return const Text('-');
                  return Column(
                    children: users
                        .map(
                          (user) => ListTile(
                            dense: true,
                            title: Text(user.uid),
                            subtitle: Text(
                              'trustScore: ${user.trustScore.toStringAsFixed(1)}, ratingAvg: ${user.ratingAvg.toStringAsFixed(2)}, completedCount: ${user.completedCount}, cancelledCount: ${user.cancelledCount}',
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
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

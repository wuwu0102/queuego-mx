import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/services/firestore_task_service.dart';

class TaskHistoryScreen extends StatelessWidget {
  const TaskHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('completedHistoryTitle'))),
      body: StreamBuilder<List<FirestoreTask>>(
        stream: FirestoreTaskService.instance.streamHistoryExampleTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(s.t('loadDataRetry')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return Center(child: Text(s.t('noTasksYet')));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Text(s.t('completedHistorySubtitle')),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(s.t('historyPriceExplanation')),
              ),
              ...tasks.map((task) => _HistoryTaskCard(task: task)),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryTaskCard extends StatelessWidget {
  const _HistoryTaskCard({required this.task});

  final FirestoreTask task;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('${s.t('status')}: ${s.t('historyCompletedLabel')}'),
            Text('${s.t('locationLabel')}: ${task.location}'),
            Text('${s.t('onsiteInstructions')}: ${task.note}'),
            if (task.instructions.trim().isNotEmpty)
              Text('${s.t('instructionsLabel')}: ${task.instructions}'),
            const SizedBox(height: 4),
            _UrgencyBadge(level: task.urgencyLevel),
            Text('${s.t('historyPricePaid')}: ${task.price.toStringAsFixed(0)} MXN'),
            Text('${s.t('startDate')}: ${task.startDate} ${task.startTime}'),
            Text('${s.t('historyTaskDuration')}: ${task.estimatedHours.toStringAsFixed(1)} h'),
            Text('${s.t('historyWaitDuration')}: ${task.waitHours.toStringAsFixed(1)} h'),
            if (task.completedAt != null)
              Text('${s.t('completedAt')}: ${DateFormat('yyyy-MM-dd HH:mm').format(task.completedAt!)}'),
            Text(
              '${s.t('historyCustomerRating')}: ⭐ ${task.ratingFromCustomer?.toStringAsFixed(1) ?? '-'}',
            ),
            Text(
              '${s.t('historyRunnerRating')}: ⭐ ${task.ratingFromRunner?.toStringAsFixed(1) ?? '-'}',
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final normalized = switch (level) {
      'priority' => 'priority',
      'urgent' => 'urgent',
      _ => 'normal',
    };
    final (label, color) = switch (normalized) {
      'priority' => (s.t('urgencyPriority'), Colors.orange),
      'urgent' => ('${s.t('urgencyUrgent')} 🔥', Colors.red),
      _ => (s.t('urgencyNormal'), Colors.grey),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('${s.t('historyUrgencyLevel')}: $label'),
    );
  }
}

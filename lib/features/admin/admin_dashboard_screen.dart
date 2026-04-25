import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/models/user_metrics.dart';
import '../../core/services/auth_gate.dart';
import '../../core/services/firestore_task_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isSeeding = false;
  bool _isDeleting = false;
  bool _isConverting = false;

  Future<void> _seedDemoTasks(BuildContext context) async {
    if (_isSeeding) return;
    final user = FirebaseAuth.instance.currentUser;
    if (!isAdminUser(user)) return;
    final ownerId = user?.uid ?? '';
    if (ownerId.isEmpty) return;

    final s = AppStrings.of(context);
    final demoCount = await FirestoreTaskService.instance.countDemoTasks();
    if (!context.mounted) return;
    if (demoCount > 0) {
      final createMore = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(s.t('demoTasksExistConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (createMore != true || !context.mounted) return;
    }

    setState(() => _isSeeding = true);
    try {
      final created = await FirestoreTaskService.instance.seedDemoTasks(
        ownerId: ownerId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('demoTasksCreated').replaceAll('{count}', '$created'))),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _deleteDemoTasks(BuildContext context) async {
    if (_isDeleting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (!isAdminUser(user)) return;
    final s = AppStrings.of(context);
    setState(() => _isDeleting = true);
    try {
      final deleted = await FirestoreTaskService.instance.deleteDemoTasks();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('demoTasksDeleted').replaceAll('{count}', '$deleted'))),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _convertOpenDemos(BuildContext context) async {
    if (_isConverting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (!isAdminUser(user)) return;
    final s = AppStrings.of(context);
    setState(() => _isConverting = true);
    try {
      final converted = await FirestoreTaskService.instance.convertOpenDemoTasksToHistory();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('demoOpenTasksConverted').replaceAll('{count}', '$converted'))),
      );
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final showDemoControls = isAdminUser(user);
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
                    onPressed: () => widget.onLocaleChanged(const Locale('es', 'MX')),
                  ),
                  ActionChip(
                    label: const Text('English'),
                    onPressed: () => widget.onLocaleChanged(const Locale('en')),
                  ),
                  ActionChip(
                    label: const Text('繁中'),
                    onPressed: () => widget.onLocaleChanged(const Locale('zh', 'TW')),
                  ),
                ],
              ),
              if (showDemoControls) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _isSeeding ? null : () => _seedDemoTasks(context),
                      icon: _isSeeding
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.playlist_add),
                      label: Text(s.t('createDemoTasks')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isDeleting ? null : () => _deleteDemoTasks(context),
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_sweep_outlined),
                      label: Text(s.t('deleteDemoTasks')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isConverting ? null : () => _convertOpenDemos(context),
                      icon: _isConverting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.history_toggle_off_outlined),
                      label: Text(s.t('convertOpenDemosToHistory')),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text('Tasks total: ${tasks.length}'),
              ...statusCounts.entries.map((e) => Text('${e.key}: ${e.value}')),
              StreamBuilder<int>(
                stream: FirestoreTaskService.instance.streamUsersCount(),
                builder: (context, countSnapshot) =>
                    Text('Users total: ${countSnapshot.data ?? 0}'),
              ),
              StreamBuilder<int>(
                stream: FirestoreTaskService.instance.streamApplicationsCount(),
                builder: (context, countSnapshot) =>
                    Text('Applications total: ${countSnapshot.data ?? 0}'),
              ),
              StreamBuilder<int>(
                stream: FirestoreTaskService.instance.streamRatingsCount(),
                builder: (context, countSnapshot) =>
                    Text('Ratings total: ${countSnapshot.data ?? 0}'),
              ),
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
                      'Owner email: ${task.ownerEmail ?? '-'}\n'
                      'Runner email: ${task.runnerEmail ?? '-'}\n'
                      'isDemo: ${task.isDemo}\n'
                      'isHistoryExample: ${task.isHistoryExample}\n'
                      'Handoff code: ${task.handoffCode.isEmpty ? '-' : task.handoffCode}\n'
                      'Created at: ${_format(task.createdAt)}\n'
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

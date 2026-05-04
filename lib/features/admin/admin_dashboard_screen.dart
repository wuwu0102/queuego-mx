import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/models/user_metrics.dart';
import '../../core/services/auth_gate.dart';
import '../../core/services/firestore_task_service.dart';
import '../shared/privacy_screen.dart';
import '../shared/terms_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const List<String> _suspiciousKeywords = [
    'pasaporte',
    'ine',
    'contraseña',
    'tarjeta',
    'lugar con fila clave',
    'vender turno',
    'cita oficial',
    'información necesaria',
  ];

  bool _isSeeding = false;
  bool _isDeleting = false;
  bool _isRegenerating = false;
  String? _deletingTaskId;

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

  Future<void> _regenerateDemoPrices(BuildContext context) async {
    if (_isRegenerating) return;
    final user = FirebaseAuth.instance.currentUser;
    if (!isAdminUser(user)) return;
    final s = AppStrings.of(context);
    setState(() => _isRegenerating = true);
    try {
      final regenerated = await FirestoreTaskService.instance.regenerateDemoPrices();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('demoPricesRegenerated').replaceAll('{count}', '$regenerated'))),
      );
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  Future<void> _deleteTask(BuildContext context, FirestoreTask task) async {
    if (_deletingTaskId != null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (!isAdminUser(user)) return;
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(s.t('deleteTaskConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.t('deleteTask')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _deletingTaskId = task.id);
    try {
      await FirestoreTaskService.instance.deleteTaskById(task.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('taskDeletedSuccess'))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('taskDeleteFailed'))),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingTaskId = null);
      }
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
            'pending': 0,
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
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsScreen()),
                    ),
                    child: Text(s.t('terms')),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    ),
                    child: Text(s.t('privacy')),
                  ),
                ],
              ),
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
                    label: const Text('中文'),
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
                      onPressed: _isRegenerating ? null : () => _regenerateDemoPrices(context),
                      icon: _isRegenerating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_fix_high_outlined),
                      label: Text(s.t('regenerateDemoPrices')),
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
                (task) {
                  final isDeletingTask = _deletingTaskId == task.id;
                  return Card(
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Text(
                        'Task ID: ${task.id}\n'
                        'Status: ${task.status}\n'
                        'Owner email: ${task.ownerEmail ?? '-'}\n'
                        'Runner email: ${task.runnerEmail ?? '-'}\n'
                        'isDemo: ${task.isDemo}\n'
                        'isHistoryExample: ${task.isHistoryExample}\n'
                        'Handoff code: ${task.handoffCode.isEmpty ? '-' : task.handoffCode}\n'
                        'Created at: ${_format(task.createdAt)}\n'
                        'Completed at: ${_format(task.completedAt)}\n'
                        'Cancelled at: ${_format(task.cancelledAt)}\n'
                        'Legacy anonymous task: ${_isLegacyAnonymousTask(task) ? s.t('legacyAnonymousTask') : '-'}'
                        '${_suspiciousKeywordsText(task, s)}',
                      ),
                      trailing: showDemoControls
                          ? OutlinedButton(
                              onPressed: isDeletingTask
                                  ? null
                                  : () => _deleteTask(context, task),
                              child: isDeletingTask
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(s.t('deleteTask')),
                            )
                          : null,
                    ),
                  );
                },
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

  String _suspiciousKeywordsText(FirestoreTask task, AppStrings s) {
    final haystack = '${task.title} ${task.note} ${task.location}'.toLowerCase();
    final hits = _suspiciousKeywords.where(haystack.contains).toList(growable: false);
    if (hits.isEmpty) return '';
    return '\n${s.t('adminSuspiciousKeywords')}: ${hits.join(', ')}';
  }
}

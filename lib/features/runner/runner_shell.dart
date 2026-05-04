import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/models/task_application.dart';
import '../../core/models/task_message.dart';
import '../../core/models/user_metrics.dart';
import '../../core/services/auth_gate.dart';
import '../../core/services/firestore_task_service.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/utils/number_parsing.dart';

const String projectContactPhone = '';

class RunnerShell extends StatefulWidget {
  const RunnerShell({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  State<RunnerShell> createState() => _RunnerShellState();
}

class _RunnerShellState extends State<RunnerShell> {
  late int current;

  @override
  void initState() {
    super.initState();
    current = widget.initialTab.clamp(0, 2).toInt();
  }

  void _onDestinationSelected(int value) {
    setState(() => current = value);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final runnerId = user?.uid ?? '';
    final s = AppStrings.of(context);
    final pages = [
      OpenTasksPage(runnerId: runnerId),
      RunnerApplicationsPage(runnerId: runnerId),
      RunnerActiveTasksPage(runnerId: runnerId),
    ];

    return Scaffold(
      body: pages[current],
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            label: s.t('availableTasks'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            label: s.t('myApplications'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.run_circle_outlined),
            label: s.t('activeTasks'),
          ),
        ],
      ),
    );
  }
}

class _ModeHeader extends StatelessWidget {
  const _ModeHeader();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        '${s.t('currentMode')}: ${s.t('modeRunner')}\n${s.t('roleModeNotice')}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class OpenTasksPage extends StatelessWidget {
  const OpenTasksPage({super.key, required this.runnerId});

  final String runnerId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('availableTasks'))),
      body: StreamBuilder<List<FirestoreTask>>(
        stream: FirestoreTaskService.instance.streamOpenTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(s.t('loadDataRetry')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return Center(child: Text(s.t('noOpenTasks')));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _ModeHeader(),
              const SizedBox(height: 8),
              Text(
                '${s.t('availableTasks')}: ${tasks.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ...tasks.map((task) => _OpenTaskCard(task: task, runnerId: runnerId)),
            ],
          );
        },
      ),
    );
  }
}

class _OpenTaskCard extends StatelessWidget {
  const _OpenTaskCard({required this.task, required this.runnerId});

  final FirestoreTask task;
  final String runnerId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isGuest = runnerId.isEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${s.t('locationLabel')}: ${task.location}'),
            Text('${s.t('onsiteInstructions')}: ${task.note}'),
            Text('${s.t('startDate')}: ${task.startDate} ${task.startTime}'),
            Text('${s.t('paymentEstimated')}: ${roundToTen(task.price).toStringAsFixed(0)} MXN'),
            Text('${s.t('historyUrgencyLevel')}: ${_urgencyLabel(s, task.urgencyLevel)}'),
            Text('${s.t('historyTimeSaved')}: ${(task.workHours + task.waitHours).toStringAsFixed(1)} h'),
            Text('${s.t('historyCustomerRating')}: ⭐ ${task.ratingFromCustomer?.toStringAsFixed(1) ?? '-'}'),
            if (_requiresExtraInstitutionReminder(task)) ...[
              const SizedBox(height: 4),
              Text(s.t('institutionRiskNoticeEs'), style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            if (isGuest)
              _ApplyTaskAction(task: task)
            else
              StreamBuilder<TaskApplication?>(
                stream: FirestoreTaskService.instance.streamRunnerApplicationForTask(
                  runnerId: runnerId,
                  taskId: task.id,
                ),
                builder: (context, snapshot) {
                  final existing = snapshot.data;
                  if (existing != null) {
                    return Text(
                      s.t('alreadyAppliedTask'),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    );
                  }
                  return _ApplyTaskAction(task: task);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ApplyTaskAction extends StatelessWidget {
  const _ApplyTaskAction({required this.task});

  final FirestoreTask task;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.t('acceptSafetyHint'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              final canContinue = await ensureRoleAllowed(context, forPosting: false);
              if (!canContinue || !context.mounted) return;
              final user = FirebaseAuth.instance.currentUser;
              final userId = user?.uid ?? '';
              if (userId.isEmpty) return;
              showDialog<void>(
                context: context,
                builder: (_) => ApplyTaskDialog(task: task, runnerId: userId),
              );
            },
            icon: const Icon(Icons.send_outlined),
            label: Text(s.t('applyTask')),
          ),
        ),
      ],
    );
  }
}

String _urgencyLabel(AppStrings s, String urgency) {
  switch (urgency) {
    case 'priority':
      return s.t('urgencyPriority');
    case 'urgent':
      return s.t('urgencyUrgent');
    default:
      return s.t('urgencyNormal');
  }
}

bool _requiresExtraInstitutionReminder(FirestoreTask task) {
  final haystack = '${task.title} ${task.location}'.toLowerCase();
  return haystack.contains('sat') ||
      haystack.contains('gobierno') ||
      haystack.contains('hospital') ||
      haystack.contains('imss');
}

class ApplyTaskDialog extends StatefulWidget {
  const ApplyTaskDialog({
    super.key,
    required this.task,
    required this.runnerId,
  });

  final FirestoreTask task;
  final String runnerId;

  @override
  State<ApplyTaskDialog> createState() => _ApplyTaskDialogState();
}

class _ApplyTaskDialogState extends State<ApplyTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _offerController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final profile = await UserProfileService.instance.fetchProfile(widget.runnerId);
      final email = user?.email?.trim() ?? '';
      final emailPrefix = email.contains('@') ? email.split('@').first : '';
      final fallbackName = emailPrefix.isNotEmpty ? emailPrefix : 'Runner';
      final profileName = profile?.displayName.trim() ?? '';
      final rawOffer = _toNullableDouble(_offerController.text.trim());
      await FirestoreTaskService.instance.applyForTask(
        taskId: widget.task.id,
        runnerId: widget.runnerId,
        runnerName: profileName.isNotEmpty ? profileName : fallbackName,
        runnerEmail: email,
        proposedPriceMxn: rawOffer == null ? null : roundToTen(rawOffer),
        message: _messageController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('applicationSubmitted'))),
      );
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('alreadyAppliedTask'))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      title: Text(s.t('applyTask')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numericField(
                controller: _offerController,
                label: s.t('myOfferMxn'),
                required: false,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _messageController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: s.t('messageToCustomer')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(s.t('cancel')),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(s.t('submitApplication')),
        ),
      ],
    );
  }

  Widget _numericField({
    required TextEditingController controller,
    required String label,
    required bool required,
  }) {
    final s = AppStrings.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if ((value == null || value.trim().isEmpty) && !required) return null;
        if (value == null || value.trim().isEmpty) return s.t('requiredField');
        if (double.tryParse(value.trim()) == null) return s.t('invalidNumber');
        return null;
      },
    );
  }

  double? _toNullableDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }
}

class RunnerApplicationsPage extends StatelessWidget {
  const RunnerApplicationsPage({super.key, required this.runnerId});

  final String runnerId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isGuest = runnerId.isEmpty;
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text(s.t('myApplications'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.t('formalLoginRequired'), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ensureFormalLogin(context, pendingAction: PendingAuthAction.myApplications),
                  child: Text(s.t('loginAction')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.t('myApplications'))),
      body: StreamBuilder<List<TaskApplication>>(
        stream: FirestoreTaskService.instance.streamApplicationsByRunner(runnerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(s.t('loadDataRetry')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snapshot.data!;
          if (apps.isEmpty) {
            return Center(child: Text(s.t('noApplicationsYet')));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _ModeHeader(),
              const SizedBox(height: 10),
              ...apps.map(
                (app) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('${s.t('taskId')}: ${app.taskId}'),
                    subtitle: Text(
                      '${s.t('myOfferMxn')}: '
                      '${app.proposedPriceMxn == null ? s.t('acceptOriginalPrice') : '${roundToTen(app.proposedPriceMxn!).toStringAsFixed(0)} MXN'}\n'
                      '${s.t('messageToCustomer')}: ${app.message}\n'
                      '${s.t('status')}: ${s.statusLabel(app.status)}',
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
}

class RunnerActiveTasksPage extends StatelessWidget {
  const RunnerActiveTasksPage({super.key, required this.runnerId});

  final String runnerId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isGuest = runnerId.isEmpty;
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text(s.t('activeTasks'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.t('formalLoginRequired'), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ensureFormalLogin(context, pendingAction: PendingAuthAction.activeTasks),
                  child: Text(s.t('loginAction')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.t('activeTasks'))),
      body: StreamBuilder<List<FirestoreTask>>(
        stream: FirestoreTaskService.instance.streamRunnerActiveTasks(runnerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(s.t('loadDataRetry')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return Center(child: Text(s.t('noActiveTasks')));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _ModeHeader(),
              const SizedBox(height: 10),
              ...tasks.map((task) => _RunnerActiveTaskCard(task: task, runnerId: runnerId)),
            ],
          );
        },
      ),
    );
  }
}

class _RunnerActiveTaskCard extends StatefulWidget {
  const _RunnerActiveTaskCard({required this.task, required this.runnerId});

  final FirestoreTask task;
  final String runnerId;

  @override
  State<_RunnerActiveTaskCard> createState() => _RunnerActiveTaskCardState();
}

class _RunnerActiveTaskCardState extends State<_RunnerActiveTaskCard> {
  final _progressController = TextEditingController();
  final _progressImageUrlController = TextEditingController();
  final _handoffCodeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _progressController.dispose();
    _progressImageUrlController.dispose();
    _handoffCodeController.dispose();
    super.dispose();
  }

  Future<void> _markArrived() async {
    final s = AppStrings.of(context);
    final canContinue = await ensureRoleAllowed(context, forPosting: false);
    if (!canContinue) return;
    setState(() => _loading = true);
    try {
      await FirestoreTaskService.instance.markArrived(
        taskId: widget.task.id,
        runnerId: widget.runnerId,
        progressNote: _progressController.text.trim(),
        progressImageUrl: _progressImageUrlController.text.trim(),
      );
      _progressController.clear();
      _progressImageUrlController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('arrivedSaved'))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateProgress() async {
    final s = AppStrings.of(context);
    final canContinue = await ensureRoleAllowed(context, forPosting: false);
    if (!canContinue) return;
    final note = _progressController.text.trim();
    if (note.isEmpty) return;
    setState(() => _loading = true);
    try {
      await FirestoreTaskService.instance.updateProgress(
        taskId: widget.task.id,
        senderId: widget.runnerId,
        senderRole: 'runner',
        progressNote: note,
        progressImageUrl: _progressImageUrlController.text.trim(),
      );
      _progressController.clear();
      _progressImageUrlController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('progressSaved'))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _notifyWaitingForCustomer() async {
    final s = AppStrings.of(context);
    final canContinue = await ensureRoleAllowed(context, forPosting: false);
    if (!canContinue) return;
    setState(() => _loading = true);
    try {
      await FirestoreTaskService.instance.notifyWaitingForCustomer(
        taskId: widget.task.id,
        runnerId: widget.runnerId,
        progressNote: _progressController.text.trim(),
        progressImageUrl: _progressImageUrlController.text.trim(),
      );
      _progressController.clear();
      _progressImageUrlController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('runnerNearlyThereSent'))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeByCode() async {
    final s = AppStrings.of(context);
    final canContinue = await ensureRoleAllowed(context, forPosting: false);
    if (!canContinue) return;
    setState(() => _loading = true);
    try {
      await FirestoreTaskService.instance.completeTaskByHandoffCode(
        task: widget.task,
        handoffCodeInput: _handoffCodeController.text.trim(),
      );
      _handoffCodeController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('taskCompleted'))),
      );
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('codeMismatch'))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _showWhatsAppButton => [
        'accepted',
        'arrived',
        'waiting_for_customer',
      ].contains(widget.task.status) &&
      projectContactPhone.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final task = widget.task;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${s.t('locationLabel')}: ${task.location}'),
            Text('${task.isHistoryExample || task.isDemo ? s.t('historyReferencePayment') : s.t('historyPricePaid')}: ${roundToTen(task.price).toStringAsFixed(0)} MXN'),
            Text('${s.t('customerArrivalBufferHours')}: ${task.waitHours}'),
            Text('${s.t('historyUrgencyLevel')}: ${_urgencyLabel(s, task.urgencyLevel)}'),
            Text('${s.t('historyTimeSaved')}: ${(task.workHours + task.waitHours).toStringAsFixed(1)} h'),
            if (_requiresExtraInstitutionReminder(task)) ...[
              Text(s.t('institutionRiskNoticeEs'), style: Theme.of(context).textTheme.bodySmall),
            ] else ...[
              Text(s.t('globalComplianceNoticeEs'), style: Theme.of(context).textTheme.bodySmall),
            ],
            Text('${s.t('status')}: ${s.statusLabel(task.status)}'),
            _TrustScorePanel(userId: task.ownerId),
            if ((task.progressNote ?? '').isNotEmpty)
              Text('${s.t('latestProgress')}: ${task.progressNote}'),
            if ((task.progressImageUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              _ProgressPhotoLink(url: task.progressImageUrl!, label: s.t('progressPhotoProof')),
            ],
            if (task.arrivedAt != null)
              Text('${s.t('arrivedAt')}: ${_formatTime(task.arrivedAt!)}'),
            if (task.readyForHandoffAt != null)
              Text('${s.t('readyForHandoffAt')}: ${_formatTime(task.readyForHandoffAt!)}'),
            if (task.completedAt != null)
              Text('${s.t('completedAt')}: ${_formatTime(task.completedAt!)}'),
            if (task.status != 'completed') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _progressController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: s.t('updateProgress'),
                  hintText: s.t('progressHint'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _progressImageUrlController,
                decoration: InputDecoration(
                  labelText: s.t('progressPhotoUrlLabel'),
                  hintText: s.t('progressPhotoUrlHint'),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (task.status == 'accepted')
                    FilledButton(
                      onPressed: _loading ? null : _markArrived,
                      child: Text(s.t('arriveNow')),
                    ),
                  if (task.status == 'accepted' ||
                      task.status == 'arrived' ||
                      task.status == 'waiting_for_customer')
                    OutlinedButton(
                      onPressed: _loading ? null : _updateProgress,
                      child: Text(s.t('updateProgress')),
                    ),
                  if (task.status == 'arrived')
                    FilledButton.tonal(
                      onPressed: _loading ? null : _notifyWaitingForCustomer,
                      child: Text(s.t('runnerNearlyThere')),
                    ),
                ],
              ),
            ],
            if (task.status == 'waiting_for_customer') ...[
              const SizedBox(height: 10),
              Text(
                s.t('runnerWaitingCodePrompt'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _handoffCodeController,
                decoration: InputDecoration(
                  labelText: s.t('enterHandoffCode'),
                  hintText: s.t('handoffInputPlaceholder'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _completeByCode,
                child: Text(s.t('completeByCode')),
              ),
            ],
            if (task.status == 'completed')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  s.t('taskCompleted'),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            if (_showWhatsAppButton)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton.icon(
                  onPressed: () => _showWhatsAppHint(context),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(s.t('requestWhatsappContact')),
                ),
              ),
            if (task.status == 'accepted' ||
                task.status == 'arrived' ||
                task.status == 'waiting_for_customer')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _TaskMessagesSection(task: task, userId: widget.runnerId, role: 'runner'),
              ),
            if (task.status == 'completed')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _SubmitRatingButton(
                  task: task,
                  fromUserId: widget.runnerId,
                  toUserId: task.ownerId,
                  role: 'runner',
                  ctaLabel: s.t('rateCustomer'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showWhatsAppHint(BuildContext context) {
    final s = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.t('requestWhatsappContact')),
        content: Text(s.t('platformHandoffNotice')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('cancel')),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) => DateFormat('yyyy-MM-dd HH:mm').format(value);
}

class _TaskMessagesSection extends StatefulWidget {
  const _TaskMessagesSection({
    required this.task,
    required this.userId,
    required this.role,
  });

  final FirestoreTask task;
  final String userId;
  final String role;

  @override
  State<_TaskMessagesSection> createState() => _TaskMessagesSectionState();
}

class _ProgressPhotoLink extends StatelessWidget {
  const _ProgressPhotoLink({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(url)),
        );
      },
      child: Row(
        children: [
          const Icon(Icons.image_outlined, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label: $url',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


class _TrustScorePanel extends StatelessWidget {
  const _TrustScorePanel({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    return StreamBuilder<UserMetrics>(
      stream: FirestoreTaskService.instance.streamUserMetrics(userId),
      builder: (context, snapshot) {
        final metrics = snapshot.data ??
            UserMetrics(
              uid: userId,
              ratingAvg: 0,
              ratingCount: 0,
              completedCount: 0,
              cancelledCount: 0,
              trustScore: 0,
            );
        final trustText = s
            .t('trustScoreLabel')
            .replaceAll('{score}', metrics.trustScore.toStringAsFixed(0));
        final ratingText = s
            .t('ratingSummary')
            .replaceAll('{avg}', metrics.ratingAvg.toStringAsFixed(1))
            .replaceAll('{count}', '${metrics.ratingCount}');
        final highTrust = metrics.trustScore >= 70;
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trustText),
              Text(ratingText),
              Text(
                highTrust ? s.t('trustedUserHint') : s.t('lowTrustHint'),
                style: TextStyle(
                  color: highTrust
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SubmitRatingButton extends StatelessWidget {
  const _SubmitRatingButton({
    required this.task,
    required this.fromUserId,
    required this.toUserId,
    required this.role,
    required this.ctaLabel,
  });

  final FirestoreTask task;
  final String fromUserId;
  final String toUserId;
  final String role;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    if (fromUserId.isEmpty || toUserId.isEmpty) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    final rated = role == 'customer' ? task.ratedByCustomer : task.ratedByRunner;
    if (rated) return Text(s.t('alreadyRated'));
    return TextButton(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => _RatingDialog(
          taskId: task.id,
          fromUserId: fromUserId,
          toUserId: toUserId,
          role: role,
        ),
      ),
      child: Text(ctaLabel),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog({
    required this.taskId,
    required this.fromUserId,
    required this.toUserId,
    required this.role,
  });

  final String taskId;
  final String fromUserId;
  final String toUserId;
  final String role;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    final canContinue = await ensureRoleAllowed(context, forPosting: false);
    if (!canContinue) return;
    setState(() => _submitting = true);
    try {
      await FirestoreTaskService.instance.submitRating(
        taskId: widget.taskId,
        fromUserId: widget.fromUserId,
        toUserId: widget.toUserId,
        fromRole: widget.role,
        rating: _rating.toDouble(),
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('reviewSubmitted'))),
      );
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('alreadyRated'))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      title: Text(s.t('submitReview')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _rating,
            items: [1, 2, 3, 4, 5]
                .map((value) => DropdownMenuItem(value: value, child: Text('⭐ $value')))
                .toList(growable: false),
            onChanged: (value) => setState(() => _rating = value ?? 5),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(hintText: s.t('ratingCommentHint')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(s.t('cancel')),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(s.t('submitReview')),
        ),
      ],
    );
  }
}

class _TaskMessagesSectionState extends State<_TaskMessagesSection> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final canContinue = await ensureRoleAllowed(context, forPosting: false);
    if (!canContinue) return;
    setState(() => _sending = true);
    try {
      await FirestoreTaskService.instance.sendTaskMessage(
        taskId: widget.task.id,
        senderId: widget.userId,
        senderRole: widget.role,
        text: text,
      );
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.t('taskMessages'), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(s.t('platformSafetyReminder')),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<TaskMessage>>(
          stream: FirestoreTaskService.instance.streamTaskMessages(widget.task.id),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <TaskMessage>[];
            return Column(
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView(
                    shrinkWrap: true,
                    children: items
                        .map(
                          (m) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(m.text),
                            subtitle: Text(
                              '${m.senderRole} • ${m.createdAt == null ? '-' : DateFormat('MM/dd HH:mm').format(m.createdAt!)}',
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 2,
                        decoration: InputDecoration(hintText: s.t('messageInputHint')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/models/task_application.dart';
import '../../core/models/task_message.dart';
import '../../core/models/user_metrics.dart';
import '../../core/services/firestore_task_service.dart';
import '../../core/services/auth_gate.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isFormal = isFormallyLoggedIn(user);
    final uid = isFormal ? (user?.uid ?? '') : '';
    final s = AppStrings.of(context);
    final pages = [
      CreateTaskPage(
        onCreated: () => setState(() => current = 1),
      ),
      OwnerTasksPage(ownerId: uid),
    ];

    return Scaffold(
      body: pages[current],
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (value) => setState(() => current = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            label: s.t('createTask'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            label: s.t('myTasks'),
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
        '${s.t('currentMode')}: ${s.t('modeCustomer')}\n${s.t('roleModeNotice')}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({
    super.key,
    required this.onCreated,
  });

  final VoidCallback onCreated;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  final _workHoursController = TextEditingController(text: '1');
  final _waitHoursController = TextEditingController(text: '0');
  final _priceController = TextEditingController(text: '120');

  DateTime? _startDate;
  TimeOfDay? _startTime;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    _workHoursController.dispose();
    _waitHoursController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double get _workHours => double.tryParse(_workHoursController.text.trim()) ?? 0;
  double get _waitHours => double.tryParse(_waitHoursController.text.trim()) ?? 0;
  double get _totalHours => _workHours + _waitHours;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _startDate ?? now,
    );
    if (picked == null) return;
    setState(() => _startDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() => _startTime = picked);
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    final canContinue = await ensureFormalLogin(context);
    if (!canContinue) return;
    if (!_formKey.currentState!.validate() || _startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('fillAllFields'))),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    final ownerId = user?.uid ?? '';
    final ownerEmail = user?.email ?? '';
    if (ownerId.isEmpty || ownerEmail.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await FirestoreTaskService.instance.addTask(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        note: _noteController.text.trim(),
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        startTime: _startTime!.format(context),
        workHours: _workHours,
        waitHours: _waitHours,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        ownerId: ownerId,
        ownerEmail: ownerEmail,
      );
      _formKey.currentState!.reset();
      _titleController.clear();
      _locationController.clear();
      _noteController.clear();
      _workHoursController.text = '1';
      _waitHoursController.text = '0';
      _priceController.text = '120';
      setState(() {
        _startDate = null;
        _startTime = null;
      });
      widget.onCreated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('taskPublished'))),
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
    return Scaffold(
      appBar: AppBar(title: Text(s.t('publishTask'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ModeHeader(),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: s.t('taskDescription')),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: s.t('locationInput')),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: s.t('onsiteInstructions')),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  title: Text(
                    _startDate == null
                        ? s.t('startDateInput')
                        : DateFormat('yyyy-MM-dd').format(_startDate!),
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  title: Text(
                    _startTime == null
                        ? s.t('startTimeSlotInput')
                        : _startTime!.format(context),
                  ),
                  trailing: const Icon(Icons.schedule),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 10),
                _NumberField(
                  controller: _workHoursController,
                  label: s.t('estimatedTaskHoursInput'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _NumberField(
                  controller: _waitHoursController,
                  label: s.t('customerArrivalBufferHoursInput'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'totalHours = ${_totalHours.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(height: 10),
                _NumberField(controller: _priceController, label: s.t('totalPriceMxnInput')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.publish),
                    label: Text(
                      _submitting ? s.t('saving') : s.t('publishTaskButton'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    final s = AppStrings.of(context);
    if (value == null || value.trim().isEmpty) return s.t('requiredField');
    return null;
  }
}

class OwnerTasksPage extends StatelessWidget {
  const OwnerTasksPage({super.key, required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('myTasks'))),
      body: StreamBuilder<List<FirestoreTask>>(
        stream: FirestoreTaskService.instance.streamTasksByOwner(ownerId),
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
              const _ModeHeader(),
              const SizedBox(height: 10),
              ...tasks.map((task) => _TaskCard(task: task, ownerId: ownerId)),
            ],
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.ownerId});

  final FirestoreTask task;
  final String ownerId;

  bool get _showCancel => task.status == 'open';

  Future<void> _cancelTask(BuildContext context) async {
    final s = AppStrings.of(context);
    final canContinue = await ensureFormalLogin(context);
    if (!canContinue) return;
    await FirestoreTaskService.instance.cancelTask(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.t('taskCancelled'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerTaskApplicationsPage(task: task),
          ),
        ),
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.t('locationLabel')}: ${task.location}'),
            Text('${s.t('startDate')}: ${task.startDate} ${task.startTime}'),
            Text('${s.t('totalPrice')}: ${task.price} MXN'),
            Text('${s.t('status')}: ${s.statusLabel(task.status)}'),
            if ((task.accepterId ?? '').isNotEmpty)
              _TrustScorePanel(userId: task.accepterId!),
            if ((task.progressImageUrl ?? '').isNotEmpty)
              _ProgressPhotoLink(url: task.progressImageUrl!, label: s.t('progressPhotoProof')),
            if (task.status == 'arrived') ...[
              const SizedBox(height: 6),
              Text(s.t('runnerArrivedNotice')),
              if ((task.progressNote ?? '').isNotEmpty)
                Text('${s.t('latestProgress')}: ${task.progressNote}'),
              if (task.arrivedAt != null)
                Text('${s.t('arrivedAt')}: ${DateFormat('yyyy-MM-dd HH:mm').format(task.arrivedAt!)}'),
            ],
            if (task.status == 'waiting_for_customer') ...[
              const SizedBox(height: 6),
              Text(s.t('runnerNotifiedYou')),
              Text(
                s.t('runnerReadyNotice'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              Text(s.t('customerWaitHoursNotice').replaceAll('{hours}', '${task.waitHours}')),
              if ((task.progressNote ?? '').isNotEmpty)
                Text('${s.t('latestProgress')}: ${task.progressNote}'),
              if (task.readyForHandoffAt != null)
                Text(
                  '${s.t('readyForHandoffAt')}: '
                  '${DateFormat('yyyy-MM-dd HH:mm').format(task.readyForHandoffAt!)}',
                ),
            ],
            if (_showHandoffCode(task.status, ownerId.isNotEmpty)) ...[
              const SizedBox(height: 6),
              _HandoffCodeCard(task: task),
            ],
            if (task.status == 'open')
              StreamBuilder<int>(
                stream: FirestoreTaskService.instance.streamTaskApplicationCount(task.id),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Text(s.t('applicantsCount').replaceAll('{count}', '$count'));
                },
              ),
            if (_showCancel)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _cancelTask(context),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(s.t('cancelTask')),
                ),
              ),
            if (_showMessageArea(task.status))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _CustomerTaskMessagesSection(task: task, ownerId: ownerId),
              ),
            if (_showWhatsAppButton(task.status))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextButton.icon(
                  onPressed: () => _showWhatsAppHint(context),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(s.t('requestWhatsappContact')),
                ),
              ),
            if (task.status == 'completed') ...[
              const SizedBox(height: 8),
              Text(
                s.t('taskCompletedLabel'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              if (task.completedAt != null)
                Text('${s.t('completedAt')}: ${DateFormat('yyyy-MM-dd HH:mm').format(task.completedAt!)}'),
              _SubmitRatingButton(
                task: task,
                fromUserId: ownerId,
                toUserId: task.accepterId ?? '',
                role: 'customer',
                ctaLabel: s.t('rateRunner'),
              ),
            ],
            if (task.status == 'cancelled' && task.cancelledAt != null)
              Text('${s.t('cancelledAt')}: ${DateFormat('yyyy-MM-dd HH:mm').format(task.cancelledAt!)}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  bool _showMessageArea(String status) =>
      status == 'accepted' || status == 'arrived' || status == 'waiting_for_customer';

  bool _showWhatsAppButton(String status) =>
      status == 'accepted' || status == 'arrived' || status == 'waiting_for_customer';

  bool _showHandoffCode(String status, bool isOwner) =>
      isOwner &&
      (status == 'accepted' || status == 'arrived' || status == 'waiting_for_customer');

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

class CustomerTaskApplicationsPage extends StatelessWidget {
  const CustomerTaskApplicationsPage({
    super.key,
    required this.task,
  });

  final FirestoreTask task;

  Future<void> _accept(BuildContext context, TaskApplication app) async {
    final s = AppStrings.of(context);
    final canContinue = await ensureFormalLogin(context);
    if (!canContinue) return;
    await FirestoreTaskService.instance.acceptApplication(task: task, application: app);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.t('applicationAccepted'))),
    );
  }

  Future<void> _reject(BuildContext context, TaskApplication app) async {
    final s = AppStrings.of(context);
    final canContinue = await ensureFormalLogin(context);
    if (!canContinue) return;
    await FirestoreTaskService.instance.rejectApplication(app.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.t('applicationRejected'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('taskApplicants'))),
      body: StreamBuilder<List<FirestoreTask>>(
        stream: FirestoreTaskService.instance.streamTasksByOwner(task.ownerId),
        builder: (context, taskSnapshot) {
          final allTasks = taskSnapshot.data ?? const <FirestoreTask>[];
          FirestoreTask latestTask = task;
          for (final item in allTasks) {
            if (item.id == task.id) {
              latestTask = item;
              break;
            }
          }
          return StreamBuilder<List<TaskApplication>>(
            stream: FirestoreTaskService.instance.streamApplicationsByTask(task.id),
            builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(s.t('loadDataRetry')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_showHandoffCode(
                latestTask.status,
                (FirebaseAuth.instance.currentUser?.uid ?? '') == latestTask.ownerId,
              ))
                _HandoffCodeCard(task: latestTask),
              if (apps.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(child: Text(s.t('noApplicantsYet'))),
                )
              else
                ...apps.map((app) {
                  final isPending = latestTask.status == 'open' && app.status == 'pending';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.runnerName, style: Theme.of(context).textTheme.titleMedium),
                          _TrustScorePanel(userId: app.runnerId),
                          const SizedBox(height: 8),
                          Text(
                            app.proposedPriceMxn == null
                                ? '${s.t('myOfferMxn')}: ${s.t('acceptOriginalPrice')}'
                                : '${s.t('myOfferMxn')}: ${app.proposedPriceMxn} MXN',
                          ),
                          Text('${s.t('messageToCustomer')}: ${app.message}'),
                          Text('${s.t('status')}: ${s.statusLabel(app.status)}'),
                          if (isPending) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilledButton(
                                  onPressed: () => _accept(context, app),
                                  child: Text(s.t('acceptApplication')),
                                ),
                                OutlinedButton(
                                  onPressed: () => _reject(context, app),
                                  child: Text(s.t('rejectApplication')),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
            },
          );
        },
      ),
    );
  }
}

class _HandoffCodeCard extends StatelessWidget {
  const _HandoffCodeCard({required this.task});

  final FirestoreTask task;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.t('handoffCardCode').replaceAll('{code}', task.handoffCode),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(s.t('handoffCardInstruction')),
        ],
      ),
    );
  }
}

bool _showHandoffCode(String status, bool isOwner) =>
    isOwner &&
    (status == 'accepted' || status == 'arrived' || status == 'waiting_for_customer');


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
    if (rated) {
      return Text(s.t('alreadyRated'));
    }
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
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('ratingRequired'))),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await FirestoreTaskService.instance.submitRating(
        taskId: widget.taskId,
        fromUserId: widget.fromUserId,
        toUserId: widget.toUserId,
        role: widget.role,
        rating: _rating,
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
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: s.t('ratingCommentHint')),
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return s.t('requiredField');
        if (double.tryParse(value.trim()) == null) return s.t('invalidNumber');
        return null;
      },
      onChanged: onChanged,
    );
  }
}

class _CustomerTaskMessagesSection extends StatefulWidget {
  const _CustomerTaskMessagesSection({required this.task, required this.ownerId});

  final FirestoreTask task;
  final String ownerId;

  @override
  State<_CustomerTaskMessagesSection> createState() =>
      _CustomerTaskMessagesSectionState();
}

class _CustomerTaskMessagesSectionState extends State<_CustomerTaskMessagesSection> {
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
    final canContinue = await ensureFormalLogin(context);
    if (!canContinue) return;
    setState(() => _sending = true);
    try {
      await FirestoreTaskService.instance.sendTaskMessage(
        taskId: widget.task.id,
        senderId: widget.ownerId,
        senderRole: 'customer',
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
                SizedBox(
                  height: 160,
                  child: ListView(
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

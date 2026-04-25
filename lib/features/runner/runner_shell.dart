import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/models/task_application.dart';
import '../../core/services/firestore_task_service.dart';

class RunnerShell extends StatefulWidget {
  const RunnerShell({super.key});

  @override
  State<RunnerShell> createState() => _RunnerShellState();
}

class _RunnerShellState extends State<RunnerShell> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final runnerId = FirebaseAuth.instance.currentUser?.uid ?? '';
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
        onDestinationSelected: (value) => setState(() => current = value),
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _OpenTaskCard(task: task, runnerId: runnerId);
            },
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
            Text('${s.t('totalPrice')}: ${task.price} MXN'),
            const SizedBox(height: 8),
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
                return Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: runnerId.isEmpty
                        ? null
                        : () => showDialog<void>(
                              context: context,
                              builder: (_) => ApplyTaskDialog(task: task, runnerId: runnerId),
                            ),
                    icon: const Icon(Icons.send_outlined),
                    label: Text(s.t('applyTask')),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
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
  final _arrivalController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _offerController.dispose();
    _arrivalController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final shortId = widget.runnerId.length <= 6
          ? widget.runnerId
          : widget.runnerId.substring(0, 6);
      await FirestoreTaskService.instance.applyForTask(
        taskId: widget.task.id,
        runnerId: widget.runnerId,
        runnerName: user?.displayName ?? 'Runner $shortId',
        proposedPriceMxn: double.parse(_offerController.text.trim()),
        estimatedArrivalHours: double.parse(_arrivalController.text.trim()),
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
              ),
              const SizedBox(height: 10),
              _numericField(
                controller: _arrivalController,
                label: s.t('arrivalHoursInput'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _messageController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: s.t('messageToCustomer')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return s.t('requiredField');
                  return null;
                },
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

  Widget _numericField({required TextEditingController controller, required String label}) {
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
    );
  }
}

class RunnerApplicationsPage extends StatelessWidget {
  const RunnerApplicationsPage({super.key, required this.runnerId});

  final String runnerId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('${s.t('taskId')}: ${app.taskId}'),
                  subtitle: Text(
                    '${s.t('myOfferMxn')}: ${app.proposedPriceMxn} MXN\n'
                    '${s.t('arrivalHoursInput')}: ${app.estimatedArrivalHours}\n'
                    '${s.t('messageToCustomer')}: ${app.message}\n'
                    '${s.t('status')}: ${s.statusLabel(app.status)}',
                  ),
                ),
              );
            },
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Text(
                    '${s.t('locationLabel')}: ${task.location}\n'
                    '${s.t('totalPrice')}: ${task.price} MXN\n'
                    '${s.t('customerArrivalBufferHours')}: ${task.waitHours}\n'
                    '${s.t('status')}: ${s.statusLabel(task.status)}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

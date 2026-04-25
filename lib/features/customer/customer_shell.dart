import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/firestore_task.dart';
import '../../core/models/task_application.dart';
import '../../core/services/firestore_task_service.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final s = AppStrings.of(context);
    final pages = [
      CreateTaskPage(
        ownerId: uid,
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

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({
    super.key,
    required this.ownerId,
    required this.onCreated,
  });

  final String ownerId;
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
    if (!_formKey.currentState!.validate() || _startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('fillAllFields'))),
      );
      return;
    }
    if (widget.ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('notLoggedIn'))),
      );
      return;
    }

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
        ownerId: widget.ownerId,
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskCard(task: task);
            },
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final FirestoreTask task;

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
            if (task.status == 'open')
              StreamBuilder<int>(
                stream: FirestoreTaskService.instance.streamTaskApplicationCount(task.id),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Text(s.t('applicantsCount').replaceAll('{count}', '$count'));
                },
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
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
    await FirestoreTaskService.instance.acceptApplication(task: task, application: app);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.t('applicationAccepted'))),
    );
  }

  Future<void> _reject(BuildContext context, TaskApplication app) async {
    final s = AppStrings.of(context);
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
      body: StreamBuilder<List<TaskApplication>>(
        stream: FirestoreTaskService.instance.streamApplicationsByTask(task.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(s.t('loadDataRetry')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snapshot.data!;
          if (apps.isEmpty) {
            return Center(child: Text(s.t('noApplicantsYet')));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              final isPending = task.status == 'open' && app.status == 'pending';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.runnerName, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('${s.t('myOfferMxn')}: ${app.proposedPriceMxn} MXN'),
                      Text('${s.t('arrivalHoursInput')}: ${app.estimatedArrivalHours}'),
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
            },
          );
        },
      ),
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

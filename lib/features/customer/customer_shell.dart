import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/mvp_task.dart';
import '../../data/mock_task_repository.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  static const _customerId = 'customer_demo';
  int current = 0;

  void _goToMyTasks() => setState(() => current = 1);

  @override
  Widget build(BuildContext context) {
    final pages = [
      CreateTaskPage(customerId: _customerId, onCreated: _goToMyTasks),
      const CustomerTasksPage(customerId: _customerId),
    ];

    final s = AppStrings.of(context);
    return Scaffold(
      body: pages[current],
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (v) => setState(() => current = v),
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
    required this.customerId,
    required this.onCreated,
  });

  final String customerId;
  final VoidCallback onCreated;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  static const _timeSlots = [
    '04:00',
    '05:00',
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
  ];

  static const _durationKeys = [
    'duration_30m',
    'duration_1h',
    'duration_2h',
    'duration_3h',
    'duration_half_day',
    'duration_full_day',
    'duration_not_sure',
  ];

  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime? _startDate;
  String? _startTimeSlot;
  String? _estimatedDuration;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
  }

  void _submit() {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _startTimeSlot == null ||
        _estimatedDuration == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t('requiredField'))));
      return;
    }

    MockTaskRepository.instance.createTask(
      locationText: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      instructions: _instructionsController.text.trim(),
      startDate: _startDate!,
      startTimeSlot: _startTimeSlot!,
      estimatedDuration: _estimatedDuration!,
      priceMxn: int.parse(_priceController.text.trim()),
      customerId: widget.customerId,
    );

    _formKey.currentState!.reset();
    _locationController.clear();
    _descriptionController.clear();
    _instructionsController.clear();
    _priceController.clear();
    setState(() {
      _startDate = null;
      _startTimeSlot = null;
      _estimatedDuration = null;
    });

    widget.onCreated();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t('taskPublished'))));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('publishTask'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t('mvpFormTitle'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: s.t('locationInput'),
                        helperText: s.t('locationHint'),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? s.t('requiredField')
                              : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: s.t('taskDescription'),
                      ),
                      minLines: 2,
                      maxLines: 3,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? s.t('requiredField')
                              : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        labelText: s.t('onsiteInstructions'),
                      ),
                      minLines: 2,
                      maxLines: 3,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? s.t('requiredField')
                              : null,
                    ),
                    const SizedBox(height: 10),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: s.t('startDateInput'),
                        border: const OutlineInputBorder(),
                        errorText: _startDate == null ? s.t('requiredField') : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _startDate == null
                                  ? s.t('selectDate')
                                  : DateFormat('yyyy-MM-dd').format(_startDate!),
                            ),
                          ),
                          IconButton(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _startTimeSlot,
                      decoration: InputDecoration(labelText: s.t('startTimeSlotInput')),
                      items: _timeSlots
                          .map(
                            (slot) => DropdownMenuItem(value: slot, child: Text(slot)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _startTimeSlot = v),
                      validator: (v) => v == null ? s.t('requiredField') : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _estimatedDuration,
                      decoration: InputDecoration(labelText: s.t('estimatedDurationInput')),
                      items: _durationKeys
                          .map(
                            (durationKey) => DropdownMenuItem(
                              value: durationKey,
                              child: Text(s.t(durationKey)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _estimatedDuration = v),
                      validator: (v) => v == null ? s.t('requiredField') : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(),
                      decoration: InputDecoration(labelText: s.t('priceMxnInput')),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return s.t('requiredField');
                        }
                        return int.tryParse(v.trim()) == null
                            ? s.t('invalidPrice')
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.publish),
                        label: Text(s.t('publishTaskButton')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerTasksPage extends StatelessWidget {
  const CustomerTasksPage({super.key, required this.customerId});

  final String customerId;

  Color _statusColor(MvpTaskStatus status) {
    return switch (status) {
      MvpTaskStatus.open => Colors.blue,
      MvpTaskStatus.accepted => Colors.orange,
      MvpTaskStatus.arrived => Colors.deepOrange,
      MvpTaskStatus.inProgress => Colors.purple,
      MvpTaskStatus.completed => Colors.green,
    };
  }

  bool _isGoogleMapsLink(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('google.com/maps') || normalized.contains('maps.app.goo.gl');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AnimatedBuilder(
      animation: MockTaskRepository.instance,
      builder: (context, _) {
        final tasks = MockTaskRepository.instance.tasksForCustomer(customerId);
        return Scaffold(
          appBar: AppBar(title: Text(s.t('myTasks'))),
          body: tasks.isEmpty
              ? Center(child: Text(s.t('noTasksYet')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.t('locationLabel')}: ${task.locationText}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_isGoogleMapsLink(task.locationText))
                              TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.open_in_new),
                                label: Text(s.t('openLocation')),
                              ),
                            const SizedBox(height: 6),
                            Text('${s.t('taskDescription')}: ${task.description}'),
                            const SizedBox(height: 6),
                            Text(
                              '${s.t('startDate')}: ${DateFormat('yyyy-MM-dd').format(task.startDate)}',
                            ),
                            Text('${s.t('startTimeSlot')}: ${task.startTimeSlot}'),
                            Text(
                              '${s.t('estimatedDuration')}: ${s.t(task.estimatedDuration)}',
                            ),
                            Text('${s.t('price')}: ${task.displayPriceMxn} MXN'),
                            Text('${s.t('onsiteInstructions')}: ${task.instructions}'),
                            if (task.negotiationStatus == NegotiationStatus.pending &&
                                task.runnerCounterOfferMxn != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${s.t('runnerCounterOffer')}: ${task.runnerCounterOfferMxn} MXN',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton(
                                    onPressed: () {
                                      MockTaskRepository.instance.respondCounterOffer(
                                        taskId: task.id,
                                        customerId: customerId,
                                        accepted: true,
                                      );
                                    },
                                    child: Text(s.t('acceptCounterOffer')),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      MockTaskRepository.instance.respondCounterOffer(
                                        taskId: task.id,
                                        customerId: customerId,
                                        accepted: false,
                                      );
                                    },
                                    child: Text(s.t('rejectCounterOffer')),
                                  ),
                                ],
                              ),
                            ],
                            if (task.progressNote != null) ...[
                              const SizedBox(height: 4),
                              Text('${s.t('latestProgress')}: ${task.progressNote}'),
                            ],
                            if (task.checkInPhotoUrl != null) ...[
                              const SizedBox(height: 4),
                              Text('${s.t('checkInPhoto')}: ${task.checkInPhotoUrl}'),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  backgroundColor: _statusColor(
                                    task.status,
                                  ).withOpacity(0.15),
                                  label: Text(s.statusLabel(task.status.name)),
                                ),
                                const Spacer(),
                                Text(
                                  '${s.t('handoffCode')}: ${task.handoffCode}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (task.status == MvpTaskStatus.completed) ...[
                              const SizedBox(height: 10),
                              Text(s.t('ratingPrompt')),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: List.generate(
                                  5,
                                  (i) => OutlinedButton(
                                    onPressed: () {},
                                    child: Text('${i + 1}★'),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _estimatedTaskHoursController = TextEditingController(text: '1');
  final _customerArrivalBufferHoursController = TextEditingController(text: '0');
  final _hourlyRateController = TextEditingController(text: '120');

  DateTime? _startDate;
  String? _startTimeSlot;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _estimatedTaskHoursController.dispose();
    _customerArrivalBufferHoursController.dispose();
    _hourlyRateController.dispose();
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

  double get _estimatedTaskHours =>
      double.tryParse(_estimatedTaskHoursController.text.trim()) ?? 0;
  double get _customerArrivalBufferHours =>
      double.tryParse(_customerArrivalBufferHoursController.text.trim()) ?? 0;
  double get _hourlyRate => double.tryParse(_hourlyRateController.text.trim()) ?? 0;

  double get _estimatedTotalHours => _estimatedTaskHours + _customerArrivalBufferHours;
  double get _suggestedTotalPrice => _estimatedTotalHours * _hourlyRate;

  void _submit() {
    final s = AppStrings.of(context);
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _startTimeSlot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.t('requiredField'))));
      return;
    }

    MockTaskRepository.instance.createTask(
      locationText: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      instructions: _instructionsController.text.trim(),
      startDate: _startDate!,
      startTimeSlot: _startTimeSlot!,
      estimatedTaskHours: _estimatedTaskHours,
      customerArrivalBufferHours: _customerArrivalBufferHours,
      hourlyRateMxn: _hourlyRate,
      customerId: widget.customerId,
    );

    _formKey.currentState!.reset();
    _locationController.clear();
    _descriptionController.clear();
    _instructionsController.clear();
    _estimatedTaskHoursController.text = '1';
    _customerArrivalBufferHoursController.text = '0';
    _hourlyRateController.text = '120';
    setState(() {
      _startDate = null;
      _startTimeSlot = null;
    });

    widget.onCreated();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.t('taskPublished'))));
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
                          (v == null || v.trim().isEmpty) ? s.t('requiredField') : null,
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
                          (v == null || v.trim().isEmpty) ? s.t('requiredField') : null,
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
                          (v == null || v.trim().isEmpty) ? s.t('requiredField') : null,
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
                      value: _startTimeSlot,
                      decoration: InputDecoration(labelText: s.t('startTimeSlotInput')),
                      items: _timeSlots
                          .map((slot) => DropdownMenuItem(value: slot, child: Text(slot)))
                          .toList(),
                      onChanged: (v) => setState(() => _startTimeSlot = v),
                      validator: (v) => v == null ? s.t('requiredField') : null,
                    ),
                    const SizedBox(height: 10),
                    _DecimalInputField(
                      controller: _estimatedTaskHoursController,
                      labelText: s.t('estimatedTaskHoursInput'),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.t('requiredField');
                        final number = double.tryParse(v.trim());
                        if (number == null) return s.t('invalidNumber');
                        if (number < 0.5 || number > 24) return '0.5 ~ 24';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _DecimalInputField(
                      controller: _customerArrivalBufferHoursController,
                      labelText: s.t('customerArrivalBufferHoursInput'),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.t('requiredField');
                        final number = double.tryParse(v.trim());
                        if (number == null) return s.t('invalidNumber');
                        if (number < 0 || number > 6) return '0 ~ 6';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _DecimalInputField(
                      controller: _hourlyRateController,
                      labelText: s.t('hourlyRateMxnInput'),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.t('requiredField');
                        final number = double.tryParse(v.trim());
                        if (number == null || number < 0) return s.t('invalidNumber');
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('${s.t('estimatedTotalHours')}: ${_estimatedTotalHours.toStringAsFixed(2)} h'),
                    Text('${s.t('suggestedTotalPrice')}: ${_suggestedTotalPrice.toStringAsFixed(2)} MXN'),
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
      MvpTaskStatus.negotiating => Colors.brown,
      MvpTaskStatus.accepted => Colors.orange,
      MvpTaskStatus.arrived => Colors.deepOrange,
      MvpTaskStatus.inProgress => Colors.purple,
      MvpTaskStatus.waitingForCustomer => Colors.amber,
      MvpTaskStatus.completed => Colors.green,
      MvpTaskStatus.cancelled => Colors.red,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${s.t('locationLabel')}: ${task.locationText}', style: Theme.of(context).textTheme.titleMedium),
                            if (_isGoogleMapsLink(task.locationText))
                              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.open_in_new), label: Text(s.t('openLocation'))),
                            const SizedBox(height: 6),
                            Text('${s.t('taskDescription')}: ${task.description}'),
                            Text('${s.t('startDate')}: ${DateFormat('yyyy-MM-dd').format(task.startDate)}'),
                            Text('${s.t('startTimeSlot')}: ${task.startTimeSlot}'),
                            Text('${s.t('estimatedTaskHours')}: ${task.estimatedTaskHours} h'),
                            Text('${s.t('customerArrivalBufferHours')}: ${task.customerArrivalBufferHours} h'),
                            Text('${s.t('hourlyRate')}: ${task.hourlyRateMxn.toStringAsFixed(2)} MXN'),
                            Text('${s.t('suggestedTotalPrice')}: ${task.displayTotalPriceMxn.toStringAsFixed(2)} MXN'),
                            Text('${s.t('onsiteInstructions')}: ${task.instructions}'),
                            if (task.negotiationStatus == NegotiationStatus.pending && task.runnerCounterOfferTotalMxn != null) ...[
                              const Divider(height: 20),
                              Text('${s.t('runnerCounterOffer')}: ${task.runnerCounterOfferTotalMxn!.toStringAsFixed(2)} MXN', style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, children: [
                                FilledButton(onPressed: () => MockTaskRepository.instance.respondCounterOffer(taskId: task.id, customerId: customerId, accepted: true), child: Text(s.t('acceptCounterOffer'))),
                                OutlinedButton(onPressed: () => MockTaskRepository.instance.respondCounterOffer(taskId: task.id, customerId: customerId, accepted: false), child: Text(s.t('rejectCounterOffer'))),
                              ]),
                            ],
                            if (task.status == MvpTaskStatus.waitingForCustomer && task.waitingStartedAt != null) ...[
                              const SizedBox(height: 8),
                              Text('${s.t('customerArrivalBufferHours')}: ${task.customerArrivalBufferHours} h'),
                              if (DateTime.now().difference(task.waitingStartedAt!).inMinutes >
                                  (task.customerArrivalBufferHours * 60))
                                Text(s.t('waitingExceeded'), style: const TextStyle(color: Colors.red)),
                            ],
                            if (task.progressNote != null) Text('${s.t('latestProgress')}: ${task.progressNote}'),
                            if (task.checkInImageBytes != null) ...[
                              const SizedBox(height: 8),
                              Text('${s.t('checkInPhoto')}: ${s.t('imageSelected')}'),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(task.checkInImageBytes!, height: 120, fit: BoxFit.cover),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(children: [
                              Chip(backgroundColor: _statusColor(task.status).withOpacity(0.15), label: Text(s.statusLabel(task.status.name))),
                              const Spacer(),
                              Text('${s.t('handoffCode')}: ${task.handoffCode}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ]),
                            if (task.status == MvpTaskStatus.completed)
                              _ReviewSection(task: task, fromUserId: customerId, toUserId: task.runnerId ?? ''),
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

class _DecimalInputField extends StatelessWidget {
  const _DecimalInputField({required this.controller, required this.labelText, required this.validator, required this.onChanged});

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(labelText: labelText),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class _ReviewSection extends StatefulWidget {
  const _ReviewSection({required this.task, required this.fromUserId, required this.toUserId});

  final MvpTask task;
  final String fromUserId;
  final String toUserId;

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (widget.toUserId.isEmpty ||
        MockTaskRepository.instance.hasReview(taskId: widget.task.id, fromUserId: widget.fromUserId, toUserId: widget.toUserId)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(s.t('rateRunner')),
        Wrap(
          spacing: 6,
          children: List.generate(5, (i) => ChoiceChip(label: Text('${i + 1}★'), selected: _rating == i + 1, onSelected: (_) => setState(() => _rating = i + 1))),
        ),
        const SizedBox(height: 8),
        TextField(controller: _commentController, decoration: InputDecoration(labelText: s.t('ratingCommentHint'))),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            MockTaskRepository.instance.submitReview(
              taskId: widget.task.id,
              fromUserId: widget.fromUserId,
              toUserId: widget.toUserId,
              rating: _rating,
              comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
            );
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('reviewSubmitted'))));
          },
          child: Text(s.t('submitReview')),
        ),
      ],
    );
  }
}

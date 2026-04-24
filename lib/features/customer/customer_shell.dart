import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final s = AppStrings.of(context);
    final normalized = _timeController.text.trim().replaceFirst(' ', 'T');
    final parsedStartTime = DateTime.tryParse(normalized);
    if (parsedStartTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.t('startTimeFormatHint'))));
      return;
    }

    MockTaskRepository.instance.createTask(
      locationText: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      instructions: _instructionsController.text.trim(),
      startTime: parsedStartTime,
      priceMxn: int.parse(_priceController.text.trim()),
      customerId: widget.customerId,
    );

    _formKey.currentState!.reset();
    _locationController.clear();
    _descriptionController.clear();
    _instructionsController.clear();
    _timeController.clear();
    _priceController.clear();

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
                      decoration: InputDecoration(labelText: s.t('locationInput')),
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
                    TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        labelText: s.t('startTimeInput'),
                        hintText: '2026-04-24 14:30',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? s.t('requiredField')
                              : null,
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
                              task.locationText,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(task.description),
                            const SizedBox(height: 6),
                            Text('${s.t('startTime')}: ${task.startTime.toLocal()}'),
                            Text('${s.t('price')}: ${task.priceMxn} MXN'),
                            Text('${s.t('onsiteInstructions')}: ${task.instructions}'),
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

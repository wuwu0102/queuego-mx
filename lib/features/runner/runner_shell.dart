import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/mvp_task.dart';
import '../../core/utils/image_picker_bridge.dart';
import '../../data/mock_task_repository.dart';

class RunnerShell extends StatefulWidget {
  const RunnerShell({super.key});

  @override
  State<RunnerShell> createState() => _RunnerShellState();
}

class _RunnerShellState extends State<RunnerShell> {
  static const _runnerId = 'runner_demo';
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final pages = [
      OpenTasksPage(runnerId: _runnerId),
      ActiveTasksPage(runnerId: _runnerId),
      CompletedRunnerTasksPage(runnerId: _runnerId),
    ];
    return Scaffold(
      body: pages[current],
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (v) => setState(() => current = v),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.search), label: s.t('availableTasks')),
          NavigationDestination(icon: const Icon(Icons.run_circle_outlined), label: s.t('activeTasks')),
          NavigationDestination(icon: const Icon(Icons.task_alt), label: s.t('completedTasks')),
        ],
      ),
    );
  }
}

class OpenTasksPage extends StatelessWidget {
  const OpenTasksPage({super.key, required this.runnerId});

  final String runnerId;

  Future<void> _showCounterOfferDialog(BuildContext context, MvpTask task, String runnerId) async {
    final s = AppStrings.of(context);
    final priceController = TextEditingController(text: '${task.totalPriceMxn.toStringAsFixed(2)}');
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.t('proposeCounterOffer')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.t('estimatedTaskHours')}: ${task.estimatedTaskHours} h'),
            Text('${s.t('customerArrivalBufferHours')}: ${task.customerArrivalBufferHours} h'),
            Text('${s.t('originalTotalPrice')}: ${task.totalPriceMxn.toStringAsFixed(2)} MXN'),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(labelText: s.t('counterOfferPriceInput')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(priceController.text.trim());
              if (value == null || value < 0) return;
              MockTaskRepository.instance.proposeCounterOffer(taskId: task.id, runnerId: runnerId, counterOfferTotalMxn: value);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('counterOfferSubmitted'))));
            },
            child: Text(s.t('submitCounterOffer')),
          ),
        ],
      ),
    );
    priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AnimatedBuilder(
      animation: MockTaskRepository.instance,
      builder: (context, _) {
        final openTasks = MockTaskRepository.instance.openTasks();
        return Scaffold(
          appBar: AppBar(title: Text(s.t('availableTasks'))),
          body: openTasks.isEmpty
              ? Center(child: Text(s.t('noOpenTasks')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: openTasks.length,
                  itemBuilder: (context, index) {
                    final task = openTasks[index];
                    return _TaskRunnerCard(
                      task: task,
                      bottom: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: () {
                              MockTaskRepository.instance.acceptTask(taskId: task.id, runnerId: runnerId);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('taskAccepted'))));
                            },
                            child: Text(s.t('acceptTask')),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => _showCounterOfferDialog(context, task, runnerId),
                            child: Text(s.t('proposeCounterOffer')),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class ActiveTasksPage extends StatelessWidget {
  const ActiveTasksPage({super.key, required this.runnerId});

  final String runnerId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AnimatedBuilder(
      animation: MockTaskRepository.instance,
      builder: (context, _) {
        final tasks = MockTaskRepository.instance.activeTasksForRunner(runnerId);
        return Scaffold(
          appBar: AppBar(title: Text(s.t('activeTasks'))),
          body: tasks.isEmpty
              ? Center(child: Text(s.t('noActiveTasks')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => _RunnerTaskActionsCard(task: tasks[index], runnerId: runnerId),
                ),
        );
      },
    );
  }
}

class _RunnerTaskActionsCard extends StatefulWidget {
  const _RunnerTaskActionsCard({required this.task, required this.runnerId});

  final MvpTask task;
  final String runnerId;

  @override
  State<_RunnerTaskActionsCard> createState() => _RunnerTaskActionsCardState();
}

class _RunnerTaskActionsCardState extends State<_RunnerTaskActionsCard> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _showCheckInDialog(BuildContext context) async {
    final s = AppStrings.of(context);
    final noteController = TextEditingController();
    Uint8List? imageBytes;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(s.t('arriveDialogTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: noteController, decoration: InputDecoration(labelText: s.t('arrivePositionHint')), maxLines: 2),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await pickImageBytes();
                  if (selected == null) return;
                  setDialogState(() => imageBytes = selected);
                },
                icon: const Icon(Icons.upload_file),
                label: Text(s.t('uploadImage')),
              ),
              if (imageBytes != null) ...[
                const SizedBox(height: 8),
                Text(s.t('imageSelected')),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(imageBytes!, height: 120, fit: BoxFit.cover)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (noteController.text.trim().isEmpty || imageBytes == null) return;
                MockTaskRepository.instance.checkInTask(
                  taskId: widget.task.id,
                  runnerId: widget.runnerId,
                  progressNote: noteController.text.trim(),
                  checkInImageBytes: imageBytes!,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('arrivedSaved'))));
              },
              child: Text(s.t('saveArrived')),
            ),
          ],
        ),
      ),
    );

    noteController.dispose();
  }

  Future<void> _showProgressDialog(BuildContext context) async {
    final s = AppStrings.of(context);
    final progressController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.t('updateProgress')),
        content: TextField(controller: progressController, decoration: InputDecoration(labelText: s.t('progressHint')), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (progressController.text.trim().isEmpty) return;
              MockTaskRepository.instance.updateProgress(taskId: widget.task.id, runnerId: widget.runnerId, progressNote: progressController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('progressSaved'))));
            },
            child: Text(s.t('updateProgress')),
          ),
        ],
      ),
    );

    progressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return _TaskRunnerCard(
      task: widget.task,
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.task.status == MvpTaskStatus.accepted) ...[
            FilledButton.icon(onPressed: () => _showCheckInDialog(context), icon: const Icon(Icons.pin_drop_outlined), label: Text(s.t('arriveNow'))),
            const SizedBox(height: 8),
          ],
          if (widget.task.status == MvpTaskStatus.arrived || widget.task.status == MvpTaskStatus.inProgress)
            FilledButton.tonal(
              onPressed: () => MockTaskRepository.instance.markWaitingForCustomer(taskId: widget.task.id, runnerId: widget.runnerId),
              child: Text(s.t('runnerNearlyThere')),
            ),
          if (widget.task.status == MvpTaskStatus.waitingForCustomer && widget.task.waitingStartedAt != null) ...[
            Text('${s.t('customerArrivalBufferHours')}: ${widget.task.customerArrivalBufferHours} h'),
            if (DateTime.now().difference(widget.task.waitingStartedAt!).inMinutes > (widget.task.customerArrivalBufferHours * 60))
              Text(s.t('waitingExceeded'), style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => _showProgressDialog(context), icon: const Icon(Icons.update), label: Text(s.t('updateProgress'))),
          const SizedBox(height: 8),
          TextField(controller: _codeController, decoration: InputDecoration(labelText: s.t('enterHandoffCode'), border: const OutlineInputBorder())),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              final success = MockTaskRepository.instance.completeByHandoffCode(taskId: widget.task.id, runnerId: widget.runnerId, handoffCode: _codeController.text);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? s.t('taskCompleted') : s.t('codeMismatch'))));
              if (success) _codeController.clear();
            },
            child: Text(s.t('completeByCode')),
          ),
        ],
      ),
    );
  }
}

class CompletedRunnerTasksPage extends StatelessWidget {
  const CompletedRunnerTasksPage({super.key, required this.runnerId});

  final String runnerId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AnimatedBuilder(
      animation: MockTaskRepository.instance,
      builder: (context, _) {
        final tasks = MockTaskRepository.instance.completedTasksForRunner(runnerId);
        return Scaffold(
          appBar: AppBar(title: Text(s.t('completedTasks'))),
          body: tasks.isEmpty
              ? Center(child: Text(s.t('noTasksYet')))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: tasks.map((task) => Card(child: Padding(padding: const EdgeInsets.all(12), child: _RunnerReviewSection(task: task, runnerId: runnerId)))).toList(),
                ),
        );
      },
    );
  }
}

class _RunnerReviewSection extends StatefulWidget {
  const _RunnerReviewSection({required this.task, required this.runnerId});

  final MvpTask task;
  final String runnerId;

  @override
  State<_RunnerReviewSection> createState() => _RunnerReviewSectionState();
}

class _RunnerReviewSectionState extends State<_RunnerReviewSection> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (MockTaskRepository.instance.hasReview(taskId: widget.task.id, fromUserId: widget.runnerId, toUserId: widget.task.customerId)) {
      return const SizedBox.shrink();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${s.t('taskDescription')}: ${widget.task.description}'),
      const SizedBox(height: 8),
      Text(s.t('rateCustomer')),
      Wrap(spacing: 6, children: List.generate(5, (i) => ChoiceChip(label: Text('${i + 1}★'), selected: _rating == i + 1, onSelected: (_) => setState(() => _rating = i + 1)))),
      const SizedBox(height: 8),
      TextField(controller: _commentController, decoration: InputDecoration(labelText: s.t('ratingCommentHint'))),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: () {
          MockTaskRepository.instance.submitReview(taskId: widget.task.id, fromUserId: widget.runnerId, toUserId: widget.task.customerId, rating: _rating, comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim());
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('reviewSubmitted'))));
        },
        child: Text(s.t('submitReview')),
      ),
    ]);
  }
}

class _TaskRunnerCard extends StatelessWidget {
  const _TaskRunnerCard({required this.task, required this.bottom});

  final MvpTask task;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.t('locationLabel')}: ${task.locationText}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('${s.t('taskDescription')}: ${task.description}'),
            const SizedBox(height: 6),
            Text('${s.t('startDate')}: ${DateFormat('yyyy-MM-dd').format(task.startDate)}'),
            Text('${s.t('startTimeSlot')}: ${task.startTimeSlot}'),
            Text('${s.t('estimatedTaskHours')}: ${task.estimatedTaskHours} h'),
            Text('${s.t('customerArrivalBufferHours')}: ${task.customerArrivalBufferHours} h'),
            Text('${s.t('totalPrice')}: ${task.displayTotalPriceMxn.toStringAsFixed(2)} MXN'),
            Text('${s.t('onsiteInstructions')}: ${task.instructions}'),
            if (task.progressNote != null) Text('${s.t('latestProgress')}: ${task.progressNote}'),
            const SizedBox(height: 12),
            bottom,
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/mvp_task.dart';
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
    ];
    return Scaffold(
      body: pages[current],
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (v) => setState(() => current = v),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: s.t('availableTasks'),
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
                      bottom: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            MockTaskRepository.instance.acceptTask(
                              taskId: task.id,
                              runnerId: runnerId,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.t('taskAccepted'))),
                            );
                          },
                          child: Text(s.t('acceptTask')),
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
                  itemBuilder: (context, index) => _RunnerTaskActionsCard(
                    task: tasks[index],
                    runnerId: runnerId,
                  ),
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
    final photoController = TextEditingController(text: 'https://mock.queuego/checkin.jpg');

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.t('arriveDialogTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: s.t('arrivePositionHint')),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: photoController,
              decoration: InputDecoration(labelText: s.t('photoMockHint')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (noteController.text.trim().isEmpty ||
                  photoController.text.trim().isEmpty) {
                return;
              }
              MockTaskRepository.instance.checkInTask(
                taskId: widget.task.id,
                runnerId: widget.runnerId,
                progressNote: noteController.text.trim(),
                checkInPhotoUrl: photoController.text.trim(),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.t('arrivedSaved'))),
              );
            },
            child: Text(s.t('saveArrived')),
          ),
        ],
      ),
    );

    noteController.dispose();
    photoController.dispose();
  }

  Future<void> _showProgressDialog(BuildContext context) async {
    final s = AppStrings.of(context);
    final progressController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.t('updateProgress')),
        content: TextField(
          controller: progressController,
          decoration: InputDecoration(labelText: s.t('progressHint')),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (progressController.text.trim().isEmpty) return;
              MockTaskRepository.instance.updateProgress(
                taskId: widget.task.id,
                runnerId: widget.runnerId,
                progressNote: progressController.text.trim(),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.t('progressSaved'))),
              );
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
            FilledButton.icon(
              onPressed: () => _showCheckInDialog(context),
              icon: const Icon(Icons.pin_drop_outlined),
              label: Text(s.t('arriveNow')),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () => _showProgressDialog(context),
            icon: const Icon(Icons.update),
            label: Text(s.t('updateProgress')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: s.t('enterHandoffCode'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              final success = MockTaskRepository.instance.completeByHandoffCode(
                taskId: widget.task.id,
                runnerId: widget.runnerId,
                handoffCode: _codeController.text,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? s.t('taskCompleted') : s.t('codeMismatch'),
                  ),
                ),
              );
              if (success) _codeController.clear();
            },
            child: Text(s.t('completeByCode')),
          ),
        ],
      ),
    );
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
            Text(task.locationText, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(task.description),
            const SizedBox(height: 6),
            Text('${s.t('onsiteInstructions')}: ${task.instructions}'),
            Text('${s.t('startTime')}: ${task.startTime.toLocal()}'),
            Text('${s.t('price')}: ${task.priceMxn} MXN'),
            if (task.progressNote != null)
              Text('${s.t('latestProgress')}: ${task.progressNote}'),
            const SizedBox(height: 12),
            bottom,
          ],
        ),
      ),
    );
  }
}

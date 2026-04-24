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
      InProgressTasksPage(runnerId: _runnerId),
    ];
    return Scaffold(
      body: pages[current],
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (v) => setState(() => current = v),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.search), label: s.t('availableTasks')),
          NavigationDestination(icon: const Icon(Icons.run_circle_outlined), label: s.t('inProgressTasks')),
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
                      actionText: s.t('acceptTask'),
                      onPressed: () {
                        MockTaskRepository.instance.acceptTask(taskId: task.id, runnerId: runnerId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.t('taskAccepted'))),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class InProgressTasksPage extends StatelessWidget {
  const InProgressTasksPage({super.key, required this.runnerId});

  final String runnerId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AnimatedBuilder(
      animation: MockTaskRepository.instance,
      builder: (context, _) {
        final acceptedTasks = MockTaskRepository.instance.acceptedTasksForRunner(runnerId);
        return Scaffold(
          appBar: AppBar(title: Text(s.t('inProgressTasks'))),
          body: acceptedTasks.isEmpty
              ? Center(child: Text(s.t('noInProgressTasks')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: acceptedTasks.length,
                  itemBuilder: (context, index) {
                    final task = acceptedTasks[index];
                    return _TaskRunnerCard(
                      task: task,
                      actionText: s.t('markCompleted'),
                      onPressed: () {
                        MockTaskRepository.instance.markCompleted(taskId: task.id, runnerId: runnerId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.t('taskCompleted'))),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _TaskRunnerCard extends StatelessWidget {
  const _TaskRunnerCard({
    required this.task,
    required this.actionText,
    required this.onPressed,
  });

  final MvpTask task;
  final String actionText;
  final VoidCallback onPressed;

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
            Text('${s.t('startTime')}: ${task.startTime.toLocal()}'),
            Text('${s.t('price')}: ${task.priceMxn.toStringAsFixed(0)} MXN'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onPressed, child: Text(actionText)),
            ),
          ],
        ),
      ),
    );
  }
}

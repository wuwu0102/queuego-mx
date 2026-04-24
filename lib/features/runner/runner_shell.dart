import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';
import '../../data/fake_data.dart';
import '../shared/task_detail_screen.dart';

class RunnerShell extends StatefulWidget {
  const RunnerShell({super.key});

  @override
  State<RunnerShell> createState() => _RunnerShellState();
}

class _RunnerShellState extends State<RunnerShell> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const FindTasksPage(), const OngoingTasksPage(), const EarningsPage(), const RunnerProfilePage()];
    return Scaffold(
      body: pages[current],
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (v) => setState(() => current = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: '找任務'),
          NavigationDestination(icon: Icon(Icons.run_circle_outlined), label: '進行中'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: '收益'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}

class FindTasksPage extends StatelessWidget {
  const FindTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final openTasks = fakeTasks.where((t) => t.status == TaskStatus.open).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Open Tasks')),
      body: ListView(
        children: openTasks
            .map(
              (t) => Card(
                child: ListTile(
                  title: Text(t.title),
                  subtitle: Text('${t.placeName} · ${t.arrivalTime}'),
                  trailing: FilledButton(onPressed: () {}, child: const Text('Accept')),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class OngoingTasksPage extends StatelessWidget {
  const OngoingTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ongoing = fakeTasks.where((t) => t.status == TaskStatus.inProgress).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Accepted Tasks')),
      body: ListView(
        children: ongoing
            .map(
              (t) => ListTile(
                title: Text(t.title),
                subtitle: const Text('Check-in / upload photo / queue update / complete'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: t))),
              ),
            )
            .toList(),
      ),
    );
  }
}

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Payment status scaffold: unpaid/authorized/paid/refunded')));
  }
}

class RunnerProfilePage extends StatelessWidget {
  const RunnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ListTile(
        title: Text('Runner Demo'),
        subtitle: Text('Rating 4.8 · Completed 42 · KYC: mock verified · Payout: placeholder'),
      ),
    );
  }
}

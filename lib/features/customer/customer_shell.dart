import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';
import '../../data/fake_data.dart';
import '../shared/task_detail_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const CreateTaskPage(), const CustomerTasksPage(), const MessagesPage(), const ProfilePage()];
    return Scaffold(
      body: pages[current],
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (v) => setState(() => current = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_box_outlined), label: '建立任務'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: '我的任務'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '訊息'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}

class CreateTaskPage extends StatelessWidget {
  const CreateTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create On-site Task')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TextField(decoration: InputDecoration(labelText: 'Task title')),
          DropdownButtonFormField<TaskCategory>(
            value: TaskCategory.queueAssistance,
            items: TaskCategory.values
                .map((v) => DropdownMenuItem(value: v, child: Text(v.name)))
                .toList(),
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: 'Task category'),
          ),
          const TextField(decoration: InputDecoration(labelText: 'Place name')),
          const TextField(decoration: InputDecoration(labelText: 'Address')),
          const TextField(decoration: InputDecoration(labelText: 'Date')),
          const TextField(decoration: InputDecoration(labelText: 'Arrival time')),
          const TextField(decoration: InputDecoration(labelText: 'Estimated wait minutes')),
          const TextField(decoration: InputDecoration(labelText: 'Task description')),
          const TextField(decoration: InputDecoration(labelText: 'Offered price (MXN)')),
          CheckboxListTile(value: true, onChanged: (_) {}, title: const Text('Requires photo updates')),
          CheckboxListTile(value: true, onChanged: (_) {}, title: const Text('Requires live updates')),
          CheckboxListTile(value: true, onChanged: (_) {}, title: const Text('Prohibited actions acknowledged')),
          const SizedBox(height: 8),
          FilledButton(onPressed: () {}, child: const Text('Save Draft / Publish')),
        ],
      ),
    );
  }
}

class CustomerTasksPage extends StatelessWidget {
  const CustomerTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: ListView(
        children: fakeTasks
            .map(
              (t) => ListTile(
                title: Text(t.title),
                subtitle: Text('${t.placeName} · ${t.status.name}'),
                trailing: Text('${t.offeredPrice.toStringAsFixed(0)} ${t.currency}'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: t))),
              ),
            )
            .toList(),
      ),
    );
  }
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Use task_updates timeline as MVP messaging.')),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Customer profile and settings')),
    );
  }
}

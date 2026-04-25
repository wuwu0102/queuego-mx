import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/models/firestore_task.dart';
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: '發任務'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: '我的任務'),
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
    if (!_formKey.currentState!.validate() || _startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請完整填寫欄位')),
      );
      return;
    }
    if (widget.ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('尚未登入 anonymous user')),
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
        const SnackBar(content: Text('任務已寫入 Firestore')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('建立任務（Firestore）')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'title（任務內容）'),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'location（地點）'),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'note（現場指示）'),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.grey)),
                  title: Text(_startDate == null ? 'startDate（開始日期）' : DateFormat('yyyy-MM-dd').format(_startDate!)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.grey)),
                  title: Text(_startTime == null ? 'startTime（開始時間）' : _startTime!.format(context)),
                  trailing: const Icon(Icons.schedule),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 10),
                _NumberField(controller: _workHoursController, label: 'workHours（工作時數）', onChanged: (_) => setState(() {})),
                const SizedBox(height: 10),
                _NumberField(controller: _waitHoursController, label: 'waitHours（等待時數）', onChanged: (_) => setState(() {})),
                const SizedBox(height: 10),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'totalHours（自動）= ${_totalHours.toStringAsFixed(2)}'),
                ),
                const SizedBox(height: 10),
                _NumberField(controller: _priceController, label: 'price（總價 MXN）'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.publish),
                    label: Text(_submitting ? '寫入中...' : '發任務（寫入 Firestore）'),
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
    if (value == null || value.trim().isEmpty) return '必填';
    return null;
  }
}

class OwnerTasksPage extends StatelessWidget {
  const OwnerTasksPage({super.key, required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的任務（Firestore）')),
      body: StreamBuilder<List<FirestoreTask>>(
        stream: FirestoreTaskService.instance.streamTasksByOwner(ownerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('讀取失敗：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return const Center(child: Text('尚無任務'));
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(task.title),
        subtitle: Text(
          '地點: ${task.location}\n'
          '日期: ${task.startDate} ${task.startTime}\n'
          '工時: ${task.workHours} + 等待: ${task.waitHours} = ${task.totalHours}\n'
          '價格: ${task.price} MXN\n'
          '狀態: ${task.status}\n'
          'ownerId: ${task.ownerId}\n'
          'accepterId: ${task.accepterId ?? "-"}',
        ),
        isThreeLine: true,
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
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '必填';
        if (double.tryParse(value.trim()) == null) return '請輸入數字';
        return null;
      },
      onChanged: onChanged,
    );
  }
}

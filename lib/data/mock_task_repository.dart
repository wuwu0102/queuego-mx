import 'package:flutter/foundation.dart';

import '../core/models/mvp_task.dart';

class MockTaskRepository extends ChangeNotifier {
  MockTaskRepository._();

  static final MockTaskRepository instance = MockTaskRepository._();

  final List<MvpTask> _tasks = [];

  List<MvpTask> get tasks => List.unmodifiable(_tasks);

  List<MvpTask> tasksForCustomer(String customerId) =>
      _tasks.where((task) => task.customerId == customerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<MvpTask> openTasks() =>
      _tasks.where((task) => task.status == MvpTaskStatus.open).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<MvpTask> acceptedTasksForRunner(String runnerId) =>
      _tasks
          .where(
            (task) =>
                task.status == MvpTaskStatus.accepted &&
                task.runnerId == runnerId,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  MvpTask createTask({
    required String locationText,
    required String description,
    required DateTime startTime,
    required double priceMxn,
    required String customerId,
  }) {
    final task = MvpTask(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      locationText: locationText,
      description: description,
      startTime: startTime,
      priceMxn: priceMxn,
      status: MvpTaskStatus.open,
      customerId: customerId,
      runnerId: null,
      createdAt: DateTime.now(),
    );
    _tasks.insert(0, task);
    notifyListeners();
    return task;
  }

  bool acceptTask({required String taskId, required String runnerId}) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return false;
    final task = _tasks[index];
    if (task.status != MvpTaskStatus.open) return false;

    _tasks[index] = task.copyWith(status: MvpTaskStatus.accepted, runnerId: runnerId);
    notifyListeners();
    return true;
  }

  bool markCompleted({required String taskId, required String runnerId}) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return false;
    final task = _tasks[index];
    if (task.status != MvpTaskStatus.accepted || task.runnerId != runnerId) {
      return false;
    }

    _tasks[index] = task.copyWith(status: MvpTaskStatus.completed);
    notifyListeners();
    return true;
  }
}

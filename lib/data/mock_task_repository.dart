import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/models/mvp_task.dart';

class MockTaskRepository extends ChangeNotifier {
  MockTaskRepository._();

  static final MockTaskRepository instance = MockTaskRepository._();

  final List<MvpTask> _tasks = [];
  final Random _random = Random();

  List<MvpTask> get tasks => List.unmodifiable(_tasks);

  List<MvpTask> tasksForCustomer(String customerId) =>
      _tasks.where((task) => task.customerId == customerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<MvpTask> openTasks() =>
      _tasks.where((task) => task.status == MvpTaskStatus.open).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<MvpTask> activeTasksForRunner(String runnerId) =>
      _tasks
          .where((task) => task.runnerId == runnerId && task.isRunnerActive)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  MvpTask createTask({
    required String locationText,
    required String description,
    required String instructions,
    required DateTime startTime,
    required int priceMxn,
    required String customerId,
  }) {
    final task = MvpTask(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      locationText: locationText,
      description: description,
      instructions: instructions,
      startTime: startTime,
      priceMxn: priceMxn,
      status: MvpTaskStatus.open,
      customerId: customerId,
      runnerId: null,
      checkInPhotoUrl: null,
      progressNote: null,
      handoffCode: _generateHandoffCode(),
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

    _tasks[index] =
        task.copyWith(status: MvpTaskStatus.accepted, runnerId: runnerId);
    notifyListeners();
    return true;
  }

  bool checkInTask({
    required String taskId,
    required String runnerId,
    required String progressNote,
    required String checkInPhotoUrl,
  }) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return false;
    final task = _tasks[index];
    if (task.runnerId != runnerId || task.status != MvpTaskStatus.accepted) {
      return false;
    }

    _tasks[index] = task.copyWith(
      status: MvpTaskStatus.arrived,
      progressNote: progressNote,
      checkInPhotoUrl: checkInPhotoUrl,
    );
    notifyListeners();
    return true;
  }

  bool updateProgress({
    required String taskId,
    required String runnerId,
    required String progressNote,
  }) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return false;
    final task = _tasks[index];
    if (!task.isRunnerActive || task.runnerId != runnerId) return false;

    _tasks[index] = task.copyWith(
      status: MvpTaskStatus.inProgress,
      progressNote: progressNote,
    );
    notifyListeners();
    return true;
  }

  bool completeByHandoffCode({
    required String taskId,
    required String runnerId,
    required String handoffCode,
  }) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return false;
    final task = _tasks[index];
    if (!task.isRunnerActive || task.runnerId != runnerId) return false;
    if (task.handoffCode.trim().toUpperCase() !=
        handoffCode.trim().toUpperCase()) {
      return false;
    }

    _tasks[index] = task.copyWith(status: MvpTaskStatus.completed);
    notifyListeners();
    return true;
  }

  String _generateHandoffCode() {
    final number = 1000 + _random.nextInt(9000);
    return 'QG-$number';
  }
}

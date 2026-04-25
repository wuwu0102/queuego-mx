import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../core/models/mvp_task.dart';
import '../core/models/review_item.dart';

class MockTaskRepository extends ChangeNotifier {
  MockTaskRepository._();

  static final MockTaskRepository instance = MockTaskRepository._();

  final List<MvpTask> _tasks = [];
  final List<ReviewItem> _reviews = [];
  final math.Random _random = math.Random();

  List<MvpTask> get tasks => List.unmodifiable(_tasks);
  List<ReviewItem> get reviews => List.unmodifiable(_reviews);

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

  List<MvpTask> completedTasksForRunner(String runnerId) =>
      _tasks
          .where(
            (task) => task.runnerId == runnerId &&
                task.status == MvpTaskStatus.completed,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  MvpTask createTask({
    required String locationText,
    required String description,
    required String instructions,
    required DateTime startDate,
    required String startTimeSlot,
    required double estimatedTaskHours,
    required double customerArrivalBufferHours,
    required double totalPriceMxn,
    required String customerId,
  }) {
    final task = MvpTask(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      locationText: locationText,
      description: description,
      instructions: instructions,
      startDate: startDate,
      startTimeSlot: startTimeSlot,
      estimatedTaskHours: estimatedTaskHours,
      customerArrivalBufferHours: customerArrivalBufferHours,
      totalPriceMxn: totalPriceMxn,
      status: MvpTaskStatus.open,
      customerId: customerId,
      runnerId: null,
      checkInImageBytes: null,
      progressNote: null,
      handoffCode: _generateHandoffCode(),
      createdAt: DateTime.now(),
      waitingStartedAt: null,
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

    _tasks[index] = task.copyWith(
      status: MvpTaskStatus.accepted,
      runnerId: runnerId,
      negotiationStatus: NegotiationStatus.none,
      clearRunnerCounterOfferMxn: true,
    );
    notifyListeners();
    return true;
  }

  bool proposeCounterOffer({
    required String taskId,
    required String runnerId,
    required double counterOfferTotalMxn,
  }) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return false;
    final task = _tasks[index];
    if (task.status != MvpTaskStatus.open || counterOfferTotalMxn < 0) {
      return false;
    }

    _tasks[index] = task.copyWith(
      runnerId: runnerId,
      status: MvpTaskStatus.negotiating,
      runnerCounterOfferTotalMxn: counterOfferTotalMxn,
      negotiationStatus: NegotiationStatus.pending,
    );
    notifyListeners();
    return true;
  }

  bool respondCounterOffer({
    required String taskId,
    required String customerId,
    required bool accepted,
  }) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return false;
    final task = _tasks[index];
    if (task.customerId != customerId ||
        task.negotiationStatus != NegotiationStatus.pending ||
        task.runnerId == null) {
      return false;
    }

    _tasks[index] = task.copyWith(
      status: accepted ? MvpTaskStatus.accepted : MvpTaskStatus.open,
      negotiationStatus: accepted
          ? NegotiationStatus.accepted
          : NegotiationStatus.rejected,
      clearRunnerId: !accepted,
    );
    notifyListeners();
    return true;
  }

  bool checkInTask({
    required String taskId,
    required String runnerId,
    required String progressNote,
    required Uint8List checkInImageBytes,
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
      checkInImageBytes: checkInImageBytes,
    );
    notifyListeners();
    return true;
  }

  bool markWaitingForCustomer({required String taskId, required String runnerId}) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return false;
    final task = _tasks[index];
    if (task.runnerId != runnerId ||
        (task.status != MvpTaskStatus.arrived &&
            task.status != MvpTaskStatus.inProgress)) {
      return false;
    }

    _tasks[index] = task.copyWith(
      status: MvpTaskStatus.waitingForCustomer,
      waitingStartedAt: DateTime.now(),
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
      status: task.status == MvpTaskStatus.waitingForCustomer
          ? MvpTaskStatus.waitingForCustomer
          : MvpTaskStatus.inProgress,
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

    final taskCode = _normalizeCode(task.handoffCode);
    final inputCode = _normalizeCode(handoffCode);
    final inputDigitsOnly = inputCode.replaceAll(RegExp(r'[^0-9]'), '');

    if (taskCode != inputCode && !taskCode.endsWith(inputDigitsOnly)) {
      return false;
    }

    _tasks[index] = task.copyWith(
      status: MvpTaskStatus.completed,
      clearWaitingStartedAt: true,
    );
    notifyListeners();
    return true;
  }

  bool submitReview({
    required String taskId,
    required String fromUserId,
    required String toUserId,
    required int rating,
    String? comment,
  }) {
    if (rating < 1 || rating > 5) return false;
    final matches = _tasks.where((item) => item.id == taskId);
    if (matches.isEmpty || matches.first.status != MvpTaskStatus.completed) return false;
    final task = matches.first;

    final duplicate = _reviews.any(
      (item) =>
          item.taskId == taskId &&
          item.fromUserId == fromUserId &&
          item.toUserId == toUserId,
    );
    if (duplicate) return false;

    _reviews.add(
      ReviewItem(
        taskId: taskId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  bool hasReview({
    required String taskId,
    required String fromUserId,
    required String toUserId,
  }) => _reviews.any(
    (item) =>
        item.taskId == taskId &&
        item.fromUserId == fromUserId &&
        item.toUserId == toUserId,
  );

  String _normalizeCode(String code) =>
      code.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  String _generateHandoffCode() {
    final number = 1000 + _random.nextInt(9000);
    return 'QG-$number';
  }
}

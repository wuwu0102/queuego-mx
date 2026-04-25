import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore_task.dart';
import '../models/task_application.dart';
import '../models/task_message.dart';

class FirestoreTaskService {
  FirestoreTaskService._();

  static final FirestoreTaskService instance = FirestoreTaskService._();

  CollectionReference<Map<String, dynamic>> get _tasks =>
      FirebaseFirestore.instance.collection('tasks');

  CollectionReference<Map<String, dynamic>> get _applications =>
      FirebaseFirestore.instance.collection('applications');

  static const List<String> _runnerActiveStatuses = [
    'accepted',
    'arrived',
    'in_progress',
    'waiting_for_customer',
  ];

  static const List<String> _runnerVisibleApplicationStatuses = [
    'pending',
    'accepted',
  ];

  CollectionReference<Map<String, dynamic>> _messages(String taskId) =>
      _tasks.doc(taskId).collection('messages');

  Future<void> addTask({
    required String title,
    required String location,
    required String note,
    required String startDate,
    required String startTime,
    required double workHours,
    required double waitHours,
    required double price,
    required String ownerId,
  }) async {
    final totalHours = workHours + waitHours;
    await _tasks.add({
      'title': title,
      'location': location,
      'note': note,
      'startDate': startDate,
      'startTime': startTime,
      'workHours': workHours,
      'waitHours': waitHours,
      'totalHours': totalHours,
      'price': price,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': ownerId,
      'accepterId': null,
      'arrivedAt': null,
      'progressNote': null,
      'progressImageUrl': null,
      'progressUpdatedAt': null,
      'readyForHandoffAt': null,
      'completedAt': null,
      'cancelledAt': null,
      'whatsappNumber': null,
      'handoffCode': _generateHandoffCode(),
    });
  }

  Stream<List<FirestoreTask>> streamOpenTasks() {
    return _tasks.where('status', isEqualTo: 'open').snapshots().map((snapshot) {
      final tasks = snapshot.docs.map(FirestoreTask.fromDoc).toList(growable: false);
      return _sortTasksByCreatedAtDesc(tasks);
    });
  }

  Stream<List<FirestoreTask>> streamTasksByOwner(String ownerId) {
    return _tasks.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map(FirestoreTask.fromDoc)
          .where((task) => task.ownerId == ownerId)
          .toList(growable: false);
      return _sortTasksByCreatedAtDesc(tasks);
    });
  }

  Stream<List<FirestoreTask>> streamAllTasks() {
    return _tasks.snapshots().map((snapshot) {
      final tasks = snapshot.docs.map(FirestoreTask.fromDoc).toList(growable: false);
      return _sortTasksByCreatedAtDesc(tasks);
    });
  }

  Stream<List<FirestoreTask>> streamRunnerActiveTasks(String runnerId) {
    return _tasks.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map(FirestoreTask.fromDoc)
          .where(
            (task) =>
                task.accepterId == runnerId &&
                _runnerActiveStatuses.contains(task.status),
          )
          .toList(growable: false);
      return _sortTasksByCreatedAtDesc(tasks);
    });
  }

  Stream<int> streamTaskApplicationCount(String taskId) {
    return _applications
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<TaskApplication>> streamApplicationsByTask(String taskId) {
    return _applications
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snapshot) {
      final apps = snapshot.docs.map(TaskApplication.fromDoc).toList(growable: false);
      return _sortApplicationsByCreatedAtDesc(apps);
    });
  }

  Stream<List<TaskApplication>> streamApplicationsByRunner(String runnerId) {
    return _applications
        .where('runnerId', isEqualTo: runnerId)
        .snapshots()
        .map((snapshot) {
      final apps = snapshot.docs.map(TaskApplication.fromDoc).toList(growable: false);
      return _sortApplicationsByCreatedAtDesc(apps);
    });
  }

  Stream<TaskApplication?> streamRunnerApplicationForTask({
    required String runnerId,
    required String taskId,
  }) {
    return _applications
        .where('runnerId', isEqualTo: runnerId)
        .snapshots()
        .map((snapshot) {
      final matches = snapshot.docs
          .map(TaskApplication.fromDoc)
          .where(
            (app) =>
                app.taskId == taskId &&
                _runnerVisibleApplicationStatuses.contains(app.status),
          )
          .toList(growable: false);
      if (matches.isEmpty) return null;
      return _sortApplicationsByCreatedAtDesc(matches).first;
    });
  }

  Future<void> applyForTask({
    required String taskId,
    required String runnerId,
    required String runnerName,
    required double? proposedPriceMxn,
    required String message,
  }) async {
    final existed = await _applications.where('runnerId', isEqualTo: runnerId).get();
    final alreadyApplied = existed.docs.map(TaskApplication.fromDoc).any(
          (app) =>
              app.taskId == taskId &&
              _runnerVisibleApplicationStatuses.contains(app.status),
        );
    if (alreadyApplied) {
      throw StateError('already_applied');
    }

    final docRef = _applications.doc();
    await docRef.set({
      'id': docRef.id,
      'taskId': taskId,
      'runnerId': runnerId,
      'runnerName': runnerName,
      'proposedPriceMxn': proposedPriceMxn,
      'message': message,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptApplication({
    required FirestoreTask task,
    required TaskApplication application,
  }) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final taskRef = _tasks.doc(task.id);
      final appRef = _applications.doc(application.id);

      transaction.update(appRef, {'status': 'accepted'});

      final relatedApps = await _applications.where('taskId', isEqualTo: task.id).get();

      for (final doc in relatedApps.docs) {
        final app = TaskApplication.fromDoc(doc);
        if (app.status != 'pending') continue;
        if (doc.id == application.id) continue;
        transaction.update(doc.reference, {'status': 'rejected'});
      }

      transaction.update(taskRef, {
        'status': 'accepted',
        'accepterId': application.runnerId,
        'price': application.proposedPriceMxn ?? task.price,
      });
    });
  }

  Future<void> rejectApplication(String applicationId) async {
    await _applications.doc(applicationId).update({'status': 'rejected'});
  }

  Future<void> cancelTask(String taskId) async {
    await _tasks.doc(taskId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markArrived({
    required String taskId,
    required String runnerId,
    String? progressNote,
    String? progressImageUrl,
  }) async {
    await _tasks.doc(taskId).update({
      'status': 'arrived',
      'arrivedAt': FieldValue.serverTimestamp(),
      if (_hasText(progressNote)) 'progressNote': progressNote!.trim(),
      if (_hasText(progressImageUrl)) 'progressImageUrl': progressImageUrl!.trim(),
      'progressUpdatedAt': FieldValue.serverTimestamp(),
    });
    if (_hasText(progressNote)) {
      await sendTaskMessage(
        taskId: taskId,
        senderId: runnerId,
        senderRole: 'runner',
        text: progressNote!.trim(),
      );
    }
  }

  Future<void> updateProgress({
    required String taskId,
    required String senderId,
    required String senderRole,
    required String progressNote,
    String? progressImageUrl,
  }) async {
    await _tasks.doc(taskId).update({
      'progressNote': progressNote.trim(),
      if (_hasText(progressImageUrl)) 'progressImageUrl': progressImageUrl!.trim(),
      'progressUpdatedAt': FieldValue.serverTimestamp(),
    });
    await sendTaskMessage(
      taskId: taskId,
      senderId: senderId,
      senderRole: senderRole,
      text: progressNote.trim(),
    );
  }

  Future<void> notifyWaitingForCustomer({
    required String taskId,
    required String runnerId,
    String? progressNote,
    String? progressImageUrl,
  }) async {
    await _tasks.doc(taskId).update({
      'status': 'waiting_for_customer',
      'readyForHandoffAt': FieldValue.serverTimestamp(),
      if (_hasText(progressNote)) 'progressNote': progressNote!.trim(),
      if (_hasText(progressImageUrl)) 'progressImageUrl': progressImageUrl!.trim(),
      'progressUpdatedAt': FieldValue.serverTimestamp(),
    });
    if (_hasText(progressNote)) {
      await sendTaskMessage(
        taskId: taskId,
        senderId: runnerId,
        senderRole: 'runner',
        text: progressNote!.trim(),
      );
    }
  }

  Future<void> completeTaskByHandoffCode({
    required FirestoreTask task,
    required String handoffCodeInput,
  }) async {
    final expectedCode = _normalizeCode(task.handoffCode ?? '');
    final expectedDigits = _digitsOnly(expectedCode);
    final inputCode = _normalizeCode(handoffCodeInput);
    final inputDigits = _digitsOnly(inputCode);
    final matches =
        inputCode.isNotEmpty &&
        (inputCode == expectedCode ||
            (inputDigits.isNotEmpty && inputDigits == expectedDigits));
    if (!matches) {
      throw StateError('code_mismatch');
    }
    await _tasks.doc(task.id).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> generateHandoffCodeForTask(String taskId) async {
    final code = _generateHandoffCode();
    await _tasks.doc(taskId).update({'handoffCode': code});
    return code;
  }

  Stream<List<TaskMessage>> streamTaskMessages(String taskId) {
    return _messages(taskId).snapshots().map((snapshot) {
      final items = snapshot.docs.map(TaskMessage.fromDoc).toList(growable: false);
      return _sortMessagesByCreatedAtAsc(items);
    });
  }

  Future<void> sendTaskMessage({
    required String taskId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    if (!_hasText(text) || senderId.isEmpty) return;
    await _messages(taskId).add({
      'taskId': taskId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  List<FirestoreTask> _sortTasksByCreatedAtDesc(List<FirestoreTask> tasks) {
    final sorted = List<FirestoreTask>.from(tasks);
    sorted.sort((a, b) => _compareDateDesc(a.createdAt, b.createdAt));
    return sorted;
  }

  List<TaskApplication> _sortApplicationsByCreatedAtDesc(
    List<TaskApplication> applications,
  ) {
    final sorted = List<TaskApplication>.from(applications);
    sorted.sort((a, b) => _compareDateDesc(a.createdAt, b.createdAt));
    return sorted;
  }

  int _compareDateDesc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  List<TaskMessage> _sortMessagesByCreatedAtAsc(List<TaskMessage> messages) {
    final sorted = List<TaskMessage>.from(messages);
    sorted.sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return -1;
      if (tb == null) return 1;
      return ta.compareTo(tb);
    });
    return sorted;
  }

  bool _hasText(String? text) => text != null && text.trim().isNotEmpty;

  String _generateHandoffCode() {
    final rng = Random();
    final digits = List.generate(4, (_) => rng.nextInt(10)).join();
    return 'QG-$digits';
  }

  String _normalizeCode(String code) =>
      code.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');
}

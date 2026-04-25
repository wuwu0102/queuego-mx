import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore_task.dart';
import '../models/task_application.dart';

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
    await _tasks.doc(taskId).update({'status': 'cancelled'});
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
}

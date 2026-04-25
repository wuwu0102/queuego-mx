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
    return _tasks
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FirestoreTask.fromDoc).toList());
  }

  Stream<List<FirestoreTask>> streamTasksByOwner(String ownerId) {
    return _tasks
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FirestoreTask.fromDoc).toList());
  }

  Stream<List<FirestoreTask>> streamRunnerActiveTasks(String runnerId) {
    return _tasks
        .where('accepterId', isEqualTo: runnerId)
        .where('status', whereIn: const [
          'accepted',
          'arrived',
          'in_progress',
          'waiting_for_customer',
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FirestoreTask.fromDoc).toList());
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(TaskApplication.fromDoc).toList(growable: false));
  }

  Stream<List<TaskApplication>> streamApplicationsByRunner(String runnerId) {
    return _applications
        .where('runnerId', isEqualTo: runnerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(TaskApplication.fromDoc).toList(growable: false));
  }

  Stream<TaskApplication?> streamRunnerApplicationForTask({
    required String runnerId,
    required String taskId,
  }) {
    return _applications
        .where('runnerId', isEqualTo: runnerId)
        .where('taskId', isEqualTo: taskId)
        .where('status', whereIn: const ['pending', 'accepted'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return TaskApplication.fromDoc(snapshot.docs.first);
    });
  }

  Future<void> applyForTask({
    required String taskId,
    required String runnerId,
    required String runnerName,
    required double proposedPriceMxn,
    required double estimatedArrivalHours,
    required String message,
  }) async {
    final existed = await _applications
        .where('taskId', isEqualTo: taskId)
        .where('runnerId', isEqualTo: runnerId)
        .where('status', whereIn: const ['pending', 'accepted'])
        .limit(1)
        .get();
    if (existed.docs.isNotEmpty) {
      throw StateError('already_applied');
    }

    final docRef = _applications.doc();
    await docRef.set({
      'id': docRef.id,
      'taskId': taskId,
      'runnerId': runnerId,
      'runnerName': runnerName,
      'proposedPriceMxn': proposedPriceMxn,
      'estimatedArrivalHours': estimatedArrivalHours,
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

      final pendingApps = await _applications
          .where('taskId', isEqualTo: task.id)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in pendingApps.docs) {
        if (doc.id == application.id) continue;
        transaction.update(doc.reference, {'status': 'rejected'});
      }

      transaction.update(taskRef, {
        'status': 'accepted',
        'accepterId': application.runnerId,
        'price': application.proposedPriceMxn,
        'waitHours': application.estimatedArrivalHours,
      });
    });
  }

  Future<void> rejectApplication(String applicationId) async {
    await _applications.doc(applicationId).update({'status': 'rejected'});
  }
}

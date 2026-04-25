import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore_task.dart';

class FirestoreTaskService {
  FirestoreTaskService._();

  static final FirestoreTaskService instance = FirestoreTaskService._();

  CollectionReference<Map<String, dynamic>> get _tasks =>
      FirebaseFirestore.instance.collection('tasks');

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

  Future<void> markTaskAccepted({
    required String taskId,
    required String runnerId,
  }) async {
    await _tasks.doc(taskId).update({
      'status': 'accepted',
      'accepterId': runnerId,
    });
  }
}

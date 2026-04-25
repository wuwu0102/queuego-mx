import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore_task.dart';
import '../models/task_application.dart';
import '../models/task_message.dart';
import '../models/user_metrics.dart';

class FirestoreTaskService {
  FirestoreTaskService._();

  static final FirestoreTaskService instance = FirestoreTaskService._();

  CollectionReference<Map<String, dynamic>> get _tasks =>
      FirebaseFirestore.instance.collection('tasks');

  CollectionReference<Map<String, dynamic>> get _applications =>
      FirebaseFirestore.instance.collection('applications');

  CollectionReference<Map<String, dynamic>> get _messages =>
      FirebaseFirestore.instance.collection('taskMessages');

  CollectionReference<Map<String, dynamic>> get _ratings =>
      FirebaseFirestore.instance.collection('ratings');

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  static const List<String> _runnerActiveStatuses = [
    'accepted',
    'arrived',
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
    required String ownerEmail,
  }) async {
    final totalHours = workHours + waitHours;
    await _ensureUserMetrics(ownerId);
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
      'ownerEmail': ownerEmail,
      'runnerId': null,
      'runnerEmail': null,
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
      'handoffVerified': false,
      'ratingFromCustomer': null,
      'ratingFromRunner': null,
      'ratedByCustomer': false,
      'ratedByRunner': false,
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
                ((task.runnerId ?? task.accepterId ?? '') == runnerId) &&
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

  Stream<UserMetrics> streamUserMetrics(String uid) {
    return _users.doc(uid).snapshots().map((doc) => UserMetrics.fromDoc(uid, doc.data()));
  }

  Future<void> applyForTask({
    required String taskId,
    required String runnerId,
    required String runnerName,
    required String runnerEmail,
    required double? proposedPriceMxn,
    required String message,
  }) async {
    await _ensureUserMetrics(runnerId);
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
      'runnerEmail': runnerEmail,
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
    await _ensureUserMetrics(application.runnerId);
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
        'runnerId': application.runnerId,
        'runnerEmail': application.runnerEmail,
        'accepterId': application.runnerId,
        'price': application.proposedPriceMxn ?? task.price,
      });
    });
  }

  Future<void> rejectApplication(String applicationId) async {
    await _applications.doc(applicationId).update({'status': 'rejected'});
  }

  Future<void> cancelTask(String taskId) async {
    final ref = _tasks.doc(taskId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final task = FirestoreTask.fromDoc(snapshot);
      if (task.status != 'open') {
        throw StateError('cancel_forbidden');
      }
      transaction.update(ref, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    });

    final taskDoc = await ref.get();
    final task = FirestoreTask.fromDoc(taskDoc);
    if (task.ownerId.isNotEmpty) {
      await _incrementCounter(task.ownerId, cancelledDelta: 1);
    }
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
    final expectedCode = _normalizeCode(task.handoffCode);
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
      'handoffVerified': true,
    });

    if (task.ownerId.isNotEmpty) {
      await _incrementCounter(task.ownerId, completedDelta: 1);
    }
    final runnerId = task.runnerId ?? task.accepterId ?? '';
    if (runnerId.isNotEmpty) {
      await _incrementCounter(runnerId, completedDelta: 1);
    }
  }

  Future<String> generateHandoffCodeForTask(String taskId) async {
    final code = _generateHandoffCode();
    await _tasks.doc(taskId).update({'handoffCode': code});
    return code;
  }

  Stream<List<TaskMessage>> streamTaskMessages(String taskId) {
    return _messages.where('taskId', isEqualTo: taskId).snapshots().map((snapshot) {
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
    await _messages.add({
      'taskId': taskId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<bool> streamHasRated({
    required String taskId,
    required String fromUserId,
  }) {
    final ratingId = _ratingDocId(taskId: taskId, fromUserId: fromUserId);
    return _ratings.doc(ratingId).snapshots().map((doc) => doc.exists);
  }

  Future<void> submitRating({
    required String taskId,
    required String fromUserId,
    required String toUserId,
    required String role,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) throw StateError('invalid_rating');
    if (fromUserId.isEmpty || toUserId.isEmpty) throw StateError('invalid_user');

    await _ensureUserMetrics(fromUserId);
    await _ensureUserMetrics(toUserId);

    final ratingId = _ratingDocId(taskId: taskId, fromUserId: fromUserId);
    final taskRef = _tasks.doc(taskId);
    final ratingRef = _ratings.doc(ratingId);
    final userRef = _users.doc(toUserId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final taskSnap = await transaction.get(taskRef);
      final task = FirestoreTask.fromDoc(taskSnap);
      if (task.status != 'completed') {
        throw StateError('task_not_completed');
      }

      final existed = await transaction.get(ratingRef);
      if (existed.exists) {
        throw StateError('already_rated');
      }

      final userSnap = await transaction.get(userRef);
      final userData = userSnap.data() ?? <String, dynamic>{};
      final ratingCount = (userData['ratingCount'] as num?)?.toInt() ?? 0;
      final ratingAvg = (userData['ratingAvg'] as num?)?.toDouble() ?? 0;
      final nextCount = ratingCount + 1;
      final nextAvg = ((ratingAvg * ratingCount) + rating) / nextCount;
      final completedCount = (userData['completedCount'] as num?)?.toInt() ?? 0;
      final cancelledCount = (userData['cancelledCount'] as num?)?.toInt() ?? 0;
      final trustScore = _calcTrustScore(
        ratingAvg: nextAvg,
        completedCount: completedCount,
        cancelledCount: cancelledCount,
      );

      transaction.set(ratingRef, {
        'taskId': taskId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'role': role,
        'rating': rating,
        'comment': comment?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final isCustomerRating = role == 'customer';
      transaction.update(taskRef, {
        if (isCustomerRating) 'ratingFromCustomer': rating.toDouble(),
        if (isCustomerRating) 'ratedByCustomer': true,
        if (!isCustomerRating) 'ratingFromRunner': rating.toDouble(),
        if (!isCustomerRating) 'ratedByRunner': true,
      });

      transaction.set(userRef, {
        'ratingAvg': nextAvg,
        'ratingCount': nextCount,
        'completedCount': completedCount,
        'cancelledCount': cancelledCount,
        'trustScore': trustScore,
      }, SetOptions(merge: true));
    });
  }

  Future<void> _ensureUserMetrics(String uid) async {
    if (uid.isEmpty) return;
    await _users.doc(uid).set({
      'ratingAvg': 0.0,
      'ratingCount': 0,
      'completedCount': 0,
      'cancelledCount': 0,
      'trustScore': 0.0,
    }, SetOptions(merge: true));
  }

  Future<void> _incrementCounter(
    String uid, {
    int completedDelta = 0,
    int cancelledDelta = 0,
  }) async {
    if (uid.isEmpty) return;
    final ref = _users.doc(uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final ratingAvg = (data['ratingAvg'] as num?)?.toDouble() ?? 0;
      final ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;
      final completed = (data['completedCount'] as num?)?.toInt() ?? 0;
      final cancelled = (data['cancelledCount'] as num?)?.toInt() ?? 0;
      final nextCompleted = max(0, completed + completedDelta);
      final nextCancelled = max(0, cancelled + cancelledDelta);
      final trust = _calcTrustScore(
        ratingAvg: ratingAvg,
        completedCount: nextCompleted,
        cancelledCount: nextCancelled,
      );
      transaction.set(ref, {
        'ratingAvg': ratingAvg,
        'ratingCount': ratingCount,
        'completedCount': nextCompleted,
        'cancelledCount': nextCancelled,
        'trustScore': trust,
      }, SetOptions(merge: true));
    });
  }

  double _calcTrustScore({
    required double ratingAvg,
    required int completedCount,
    required int cancelledCount,
  }) {
    final score = (ratingAvg * 20) + (completedCount * 2) - (cancelledCount * 5);
    return score.clamp(0, 100).toDouble();
  }

  String _ratingDocId({required String taskId, required String fromUserId}) =>
      '${taskId}_$fromUserId';

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
    final value = Random().nextInt(900000) + 100000;
    return '$value';
  }

  String _normalizeCode(String code) =>
      code.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');
}

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
    String? ownerEmail,
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
      'ownerRole': 'customer',
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

  Future<void> migrateAnonymousUserData({
    required String fromAnonymousUid,
    required String toFormalUid,
    String? formalEmail,
    String? formalDisplayName,
  }) async {
    if (fromAnonymousUid.isEmpty || toFormalUid.isEmpty || fromAnonymousUid == toFormalUid) {
      return;
    }
    final batch = FirebaseFirestore.instance.batch();
    final normalizedEmail = formalEmail?.trim();
    final normalizedName = formalDisplayName?.trim();

    final ownedTasks = await _tasks.where('ownerId', isEqualTo: fromAnonymousUid).get();
    for (final doc in ownedTasks.docs) {
      batch.set(doc.reference, {
        'ownerId': toFormalUid,
        if (_hasText(normalizedEmail)) 'ownerEmail': normalizedEmail,
      }, SetOptions(merge: true));
    }

    final runnerTasks = await _tasks.where('runnerId', isEqualTo: fromAnonymousUid).get();
    for (final doc in runnerTasks.docs) {
      batch.set(doc.reference, {
        'runnerId': toFormalUid,
        'accepterId': toFormalUid,
        if (_hasText(normalizedEmail)) 'runnerEmail': normalizedEmail,
      }, SetOptions(merge: true));
    }

    final acceptedTasks = await _tasks.where('accepterId', isEqualTo: fromAnonymousUid).get();
    for (final doc in acceptedTasks.docs) {
      batch.set(doc.reference, {
        'accepterId': toFormalUid,
        if (_hasText(normalizedEmail)) 'runnerEmail': normalizedEmail,
      }, SetOptions(merge: true));
    }

    final applications = await _applications.where('runnerId', isEqualTo: fromAnonymousUid).get();
    for (final doc in applications.docs) {
      batch.set(doc.reference, {
        'runnerId': toFormalUid,
        if (_hasText(normalizedEmail)) 'runnerEmail': normalizedEmail,
        if (_hasText(normalizedName)) 'runnerName': normalizedName,
      }, SetOptions(merge: true));
    }

    final messages = await _messages.where('senderId', isEqualTo: fromAnonymousUid).get();
    for (final doc in messages.docs) {
      batch.set(doc.reference, {'senderId': toFormalUid}, SetOptions(merge: true));
    }

    batch.set(_users.doc(fromAnonymousUid), {'migratedToUid': toFormalUid}, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<List<FirestoreTask>> streamOpenTasks() {
    return _tasks.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map(FirestoreTask.fromDoc)
          .where((task) => task.status != 'cancelled' && task.status != 'completed')
          .toList(growable: false);
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


  Stream<List<UserMetrics>> streamAllUsersMetrics() {
    return _users.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserMetrics.fromDoc(doc.id, doc.data()))
          .toList(growable: false);
    });
  }

  Stream<UserMetrics> streamUserMetrics(String uid) {
    return _users.doc(uid).snapshots().map((doc) => UserMetrics.fromDoc(uid, doc.data()));
  }

  Stream<int> streamUsersCount() =>
      _users.snapshots().map((snapshot) => snapshot.docs.length);

  Stream<int> streamApplicationsCount() =>
      _applications.snapshots().map((snapshot) => snapshot.docs.length);

  Stream<int> streamRatingsCount() =>
      _ratings.snapshots().map((snapshot) => snapshot.docs.length);

  Future<int> countDemoTasks() async {
    final snapshot = await _tasks.where('isDemo', isEqualTo: true).get();
    return snapshot.docs.length;
  }

  Future<int> seedDemoTasks({
    required String ownerId,
    required String ownerEmail,
  }) async {
    final today = DateTime.now();
    final demoTasks = <Map<String, dynamic>>[
      {
        'title': 'SAT Guadalajara',
        'location': 'SAT Guadalajara Centro',
        'note': 'Necesito apoyo para hacer fila para trámite fiscal. Pago 300 MXN.',
        'instructions': 'Esperar en la fila principal y avisar cuando falten 15 lugares.',
        'startDate': _formatDate(today.add(const Duration(days: 1))),
        'startTime': '08:30',
        'workHours': 2.0,
        'waitHours': 1.0,
        'price': 300.0,
      },
      {
        'title': 'IMSS Clínica',
        'location': 'IMSS Clínica 46 Guadalajara',
        'note': 'Ayuda para esperar turno y avisar cuando falte poco. Pago 350 MXN.',
        'instructions': 'Quédate en fila de citas y avisa cuando queden pocos turnos.',
        'startDate': _formatDate(today.add(const Duration(days: 1))),
        'startTime': '09:00',
        'workHours': 2.0,
        'waitHours': 1.0,
        'price': 350.0,
      },
      {
        'title': 'Banco BBVA',
        'location': 'Sucursal BBVA Chapalita',
        'note': 'Esperar turno para atención en sucursal. Pago 200 MXN.',
        'instructions': 'Tomar lugar en ventanilla y compartir avance cada 20 minutos.',
        'startDate': _formatDate(today.add(const Duration(days: 2))),
        'startTime': '10:00',
        'workHours': 1.5,
        'waitHours': 1.0,
        'price': 200.0,
      },
      {
        'title': 'Costco Guadalajara',
        'location': 'Costco López Mateos',
        'note': 'Guardar lugar en fila para entrada. Pago 150 MXN.',
        'instructions': 'Resguardar lugar en fila de acceso y avisar antes de entrar.',
        'startDate': _formatDate(today.add(const Duration(days: 2))),
        'startTime': '11:30',
        'workHours': 1.0,
        'waitHours': 1.0,
        'price': 150.0,
      },
      {
        'title': 'Concierto / Evento',
        'location': 'Auditorio Telmex',
        'note': 'Guardar lugar en fila antes de entrar. Pago 250 MXN.',
        'instructions': 'Mantener el lugar en fila general y avisar al abrir puertas.',
        'startDate': _formatDate(today.add(const Duration(days: 3))),
        'startTime': '16:00',
        'workHours': 2.0,
        'waitHours': 1.0,
        'price': 250.0,
      },
      {
        'title': 'Hospital privado',
        'location': 'Hospital Puerta de Hierro',
        'note': 'Esperar en recepción y avisar cuando sea el turno. Pago 300 MXN.',
        'instructions': 'Registrar llegada en recepción y notificar cuando llamen al paciente.',
        'startDate': _formatDate(today.add(const Duration(days: 3))),
        'startTime': '12:00',
        'workHours': 2.0,
        'waitHours': 1.0,
        'price': 300.0,
      },
      {
        'title': 'Oficina de gobierno',
        'location': 'Recaudadora Estatal Guadalajara',
        'note': 'Apoyo en fila para trámite administrativo. Pago 400 MXN.',
        'instructions': 'Formarse en ventanilla de trámites y avisar cuando falten 10 personas.',
        'startDate': _formatDate(today.add(const Duration(days: 4))),
        'startTime': '09:30',
        'workHours': 2.5,
        'waitHours': 1.0,
        'price': 400.0,
      },
      {
        'title': 'Paquetería',
        'location': 'Centro de envíos DHL Providencia',
        'note': 'Esperar turno para recolección o entrega. Pago 180 MXN.',
        'instructions': 'Esperar turno en mostrador y avisar cuando el número esté por salir.',
        'startDate': _formatDate(today.add(const Duration(days: 4))),
        'startTime': '13:30',
        'workHours': 1.5,
        'waitHours': 1.0,
        'price': 180.0,
      },
    ];

    for (final task in demoTasks) {
      final workHours = (task['workHours'] as num).toDouble();
      final waitHours = (task['waitHours'] as num).toDouble();
      await _tasks.add({
        'title': task['title'],
        'location': task['location'],
        'note': task['note'],
        'instructions': task['instructions'],
        'startDate': task['startDate'],
        'startTime': task['startTime'],
        'workHours': workHours,
        'waitHours': waitHours,
        'totalHours': workHours + waitHours,
        'price': task['price'],
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'ownerId': ownerId,
        'ownerEmail': ownerEmail,
        'ownerRole': 'customer',
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
        'isDemo': true,
      });
    }
    return demoTasks.length;
  }

  Future<int> deleteDemoTasks() async {
    final snapshot = await _tasks.where('isDemo', isEqualTo: true).get();
    if (snapshot.docs.isEmpty) return 0;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  Future<void> applyForTask({
    required String taskId,
    required String runnerId,
    required String runnerName,
    required String runnerEmail,
    required double? proposedPriceMxn,
    required String message,
  }) async {
    await ensureTaskLegacyCompatibility(taskId);
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
      'runnerOffer': proposedPriceMxn,
      'message': message,
      'runnerMessage': message,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptApplication({
    required FirestoreTask task,
    required TaskApplication application,
  }) async {
    await ensureTaskLegacyCompatibility(task.id);
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
        'acceptedAt': FieldValue.serverTimestamp(),
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
      if (task.status != 'open' && task.status != 'negotiating') {
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
    await ensureTaskLegacyCompatibility(taskId);
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
    await ensureTaskLegacyCompatibility(taskId);
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
    await ensureTaskLegacyCompatibility(task.id);
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

  Future<void> ensureTaskLegacyCompatibility(String taskId) async {
    if (taskId.isEmpty) return;
    final ref = _tasks.doc(taskId);
    final snapshot = await ref.get();
    if (!snapshot.exists) return;
    final data = snapshot.data() ?? <String, dynamic>{};
    final updates = <String, dynamic>{};
    final handoffCode = data['handoffCode'];
    final handoffText = handoffCode is String ? handoffCode : '$handoffCode';
    if (!_hasText(handoffCode == null ? null : handoffText)) {
      updates['handoffCode'] = _generateHandoffCode();
    }
    if (data['ratedByCustomer'] == null) {
      updates['ratedByCustomer'] = false;
    }
    if (data['ratedByRunner'] == null) {
      updates['ratedByRunner'] = false;
    }
    if (data['handoffVerified'] == null) {
      updates['handoffVerified'] = false;
    }
    if (updates.isEmpty) return;
    await ref.set(updates, SetOptions(merge: true));
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

      final fromRole = role == 'customer' ? 'customer' : 'runner';
      final toRole = role == 'customer' ? 'runner' : 'customer';

      transaction.set(ratingRef, {
        'taskId': taskId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromRole': fromRole,
        'toRole': toRole,
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
      'ratingAvg': 5.0,
      'ratingCount': 0,
      'completedCount': 0,
      'cancelledCount': 0,
      'trustScore': 80.0,
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
    sorted.sort((a, b) {
      final openA = a.status == 'open' ? 1 : 0;
      final openB = b.status == 'open' ? 1 : 0;
      if (openA != openB) return openB.compareTo(openA);
      final created = _compareDateDesc(a.createdAt, b.createdAt);
      if (created != 0) return created;
      return (b.price).compareTo(a.price);
    });
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
    final value = Random().nextInt(9000) + 1000;
    return 'QG-$value';
  }

  String _normalizeCode(String code) =>
      code.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

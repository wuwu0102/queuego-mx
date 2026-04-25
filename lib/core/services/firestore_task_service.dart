import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/firestore_task.dart';
import '../models/task_application.dart';
import '../models/task_message.dart';
import '../models/user_metrics.dart';
import '../utils/number_parsing.dart';

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
  static const Map<String, List<int>> _demoHistoryPriceRangesMxn = {
    'Paquetería DHL': [420, 520],
    'Banco BBVA': [450, 580],
    'Costco Guadalajara': [380, 480],
    'SAT Guadalajara': [700, 900],
    'IMSS Clínica': [700, 950],
    'Hospital privado': [700, 1000],
    'Oficina de gobierno': [750, 1100],
    'Concierto / Evento': [800, 1300],
  };

  Future<void> addTask({
    required String title,
    required String location,
    required String note,
    required String startDate,
    required String startTime,
    required double estimatedHours,
    required double waitingHours,
    required String priority,
    required double userInputPrice,
    required String ownerId,
    String? ownerEmail,
  }) async {
    final normalizedPriority = _normalizeUrgencyLevel(priority);
    final totalPrice = userInputPrice;
    await _ensureUserMetrics(ownerId);
    await _tasks.add({
      'title': title,
      'location': location,
      'note': note,
      'startDate': startDate,
      'startTime': startTime,
      'priority': normalizedPriority,
      'estimatedHours': estimatedHours,
      'waitingHours': waitingHours,
      'workHours': estimatedHours,
      'waitHours': waitingHours,
      'totalHours': estimatedHours + waitingHours,
      'price': totalPrice,
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
          .where((task) => task.status == 'open' && !task.isHistoryExample)
          .toList(growable: false);
      return _sortTasksByCreatedAtDesc(tasks);
    });
  }

  Stream<List<FirestoreTask>> streamHistoryExampleTasks() {
    return _tasks.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map(FirestoreTask.fromDoc)
          .where((task) => task.status == 'completed' && task.isHistoryExample)
          .toList(growable: false);
      return _sortTasksByCompletedAtDesc(tasks);
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
  }) async {
    final now = DateTime.now();
    final random = math.Random();
    final usedPrices = <int>{};
    final demoCustomerEmail = 'demo_customer@queuego.mx';
    final demoRunnerEmail = 'demo_runner@queuego.mx';
    final createdTimes = _generateDemoCreatedTimes(now);
    final demoTasks = <Map<String, dynamic>>[
      {
        'title': 'SAT Guadalajara',
        'location': 'SAT Guadalajara Centro',
        'note': 'Fila para trámite fiscal presencial con validación de documentos.',
        'instructions': 'Formarse desde la entrada principal y avisar cuando falten 15 turnos.',
        'startDate': _formatDate(now.subtract(const Duration(days: 2))),
        'startTime': '11:07',
        'basePrice': 200.0,
        'estimatedHours': 2.0,
        'waitHours': 1.0,
        'urgencyLevel': 'priority',
      },
      {
        'title': 'IMSS Clínica',
        'location': 'IMSS Clínica 46 Guadalajara',
        'note': 'Gestión de fila para consulta externa y cambio de ventanilla.',
        'instructions': 'Tomar lugar en admisión y reportar avance cada 20 minutos.',
        'startDate': _formatDate(now.subtract(const Duration(days: 1))),
        'startTime': '15:19',
        'basePrice': 240.0,
        'estimatedHours': 2.0,
        'waitHours': 1.0,
        'urgencyLevel': 'priority',
      },
      {
        'title': 'Banco BBVA',
        'location': 'Sucursal BBVA Chapalita',
        'note': 'Asistencia para fila de caja y firma de documentación bancaria.',
        'instructions': 'Mantener lugar en ventanilla y confirmar tiempo de atención estimado.',
        'startDate': _formatDate(now.subtract(const Duration(days: 4))),
        'startTime': '09:34',
        'basePrice': 120.0,
        'estimatedHours': 1.0,
        'waitHours': 1.0,
        'urgencyLevel': 'normal',
      },
      {
        'title': 'Costco Guadalajara',
        'location': 'Costco López Mateos',
        'note': 'Reserva de turno en acceso principal durante hora pico.',
        'instructions': 'Asegurar posición en la fila y avisar cuando falten 10 minutos para entrar.',
        'startDate': _formatDate(now.subtract(const Duration(days: 6))),
        'startTime': '13:52',
        'basePrice': 100.0,
        'estimatedHours': 1.0,
        'waitHours': 1.0,
        'urgencyLevel': 'normal',
      },
      {
        'title': 'Concierto / Evento',
        'location': 'Auditorio Telmex',
        'note': 'Cobertura de fila premium para acceso preferente a evento nocturno.',
        'instructions': 'Resguardar posición en fila general y confirmar apertura de puertas en tiempo real.',
        'startDate': _formatDate(now.subtract(const Duration(days: 8))),
        'startTime': '17:03',
        'basePrice': 260.0,
        'estimatedHours': 3.0,
        'waitHours': 2.0,
        'urgencyLevel': 'urgent',
      },
      {
        'title': 'Hospital privado',
        'location': 'Hospital Puerta de Hierro',
        'note': 'Gestión de fila en admisión para ingreso programado.',
        'instructions': 'Realizar check-in en recepción y notificar al paciente cuando falte poco.',
        'startDate': _formatDate(now.subtract(const Duration(days: 10))),
        'startTime': '10:41',
        'basePrice': 220.0,
        'estimatedHours': 2.0,
        'waitHours': 1.0,
        'urgencyLevel': 'priority',
      },
      {
        'title': 'Oficina de gobierno',
        'location': 'Recaudadora Estatal Guadalajara',
        'note': 'Fila para trámite administrativo con validación en ventanilla oficial.',
        'instructions': 'Permanecer en fila de trámites y avisar cuando queden 10 personas.',
        'startDate': _formatDate(now.subtract(const Duration(days: 12))),
        'startTime': '12:26',
        'basePrice': 210.0,
        'estimatedHours': 2.0,
        'waitHours': 2.0,
        'urgencyLevel': 'priority',
      },
      {
        'title': 'Paquetería DHL',
        'location': 'Centro de envíos DHL Providencia',
        'note': 'Apoyo para fila de envío prioritario con documentación física.',
        'instructions': 'Tomar turno en mostrador y avisar cuando el folio esté próximo a pantalla.',
        'startDate': _formatDate(now.subtract(const Duration(days: 13))),
        'startTime': '16:48',
        'basePrice': 120.0,
        'estimatedHours': 1.0,
        'waitHours': 1.0,
        'urgencyLevel': 'normal',
      },
    ];

    for (var i = 0; i < demoTasks.length; i++) {
      final task = demoTasks[i];
      final createdAt = createdTimes[i];
      final completedAt = createdAt.add(Duration(minutes: 45 + (i * 17)));
      final seededPrice = _pickDemoHistoryPriceMxn(
        title: (task['title'] as String?) ?? '',
        random: random,
        usedPrices: usedPrices,
      );
      final basePrice = parseDouble(seededPrice);
      final urgencyLevel = (task['urgencyLevel'] as String?) ?? 'normal';
      final estimatedHours = parseDouble(task['estimatedHours']);
      final waitHours = parseDouble(task['waitHours']);
      final finalPrice = parseDouble(seededPrice);
      await _tasks.add({
        'title': task['title'],
        'location': task['location'],
        'note': task['note'],
        'instructions': task['instructions'],
        'startDate': task['startDate'],
        'startTime': task['startTime'],
        'basePrice': basePrice,
        'urgencyLevel': urgencyLevel,
        'estimatedHours': estimatedHours,
        'workHours': estimatedHours,
        'waitHours': waitHours,
        'totalHours': estimatedHours + waitHours,
        'price': finalPrice,
        'status': 'completed',
        'createdAt': Timestamp.fromDate(createdAt),
        'ownerId': ownerId,
        'ownerEmail': demoCustomerEmail,
        'ownerRole': 'customer',
        'runnerId': 'demo_runner',
        'runnerEmail': demoRunnerEmail,
        'accepterId': 'demo_runner',
        'arrivedAt': null,
        'progressNote': null,
        'progressImageUrl': null,
        'progressUpdatedAt': null,
        'readyForHandoffAt': null,
        'completedAt': Timestamp.fromDate(completedAt),
        'cancelledAt': null,
        'whatsappNumber': null,
        'handoffCode': _generateHandoffCode(),
        'handoffVerified': true,
        'ratingFromCustomer': 5.0,
        'ratingFromRunner': 5.0,
        'ratedByCustomer': true,
        'ratedByRunner': true,
        'isDemo': true,
        'isHistoryExample': true,
      });
    }
    return demoTasks.length;
  }

  Future<int> deleteDemoTasks() async {
    final snapshot = await _tasks
        .where('isDemo', isEqualTo: true)
        .where('isHistoryExample', isEqualTo: true)
        .get();
    if (snapshot.docs.isEmpty) return 0;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  Future<int> regenerateDemoPrices() async {
    final snapshot = await _tasks
        .where('isDemo', isEqualTo: true)
        .where('isHistoryExample', isEqualTo: true)
        .get();
    if (snapshot.docs.isEmpty) return 0;
    final batch = FirebaseFirestore.instance.batch();
    final random = math.Random();
    final usedPrices = <int>{};
    for (final doc in snapshot.docs) {
      final task = FirestoreTask.fromDoc(doc);
      final regeneratedPrice = _pickDemoHistoryPriceMxn(
        title: task.title,
        random: random,
        usedPrices: usedPrices,
        fallbackPrice: task.price,
      );
      batch.set(doc.reference, {
        'price': parseDouble(regeneratedPrice),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  Future<int> convertOpenDemoTasksToHistory() async {
    final snapshot = await _tasks
        .where('isDemo', isEqualTo: true)
        .where('status', isEqualTo: 'open')
        .get();
    if (snapshot.docs.isEmpty) return 0;

    final batch = FirebaseFirestore.instance.batch();
    final convertedTimes = _generateDemoCreatedTimes(DateTime.now());
    for (var i = 0; i < snapshot.docs.length; i++) {
      final doc = snapshot.docs[i];
      final completedAt = convertedTimes[i % convertedTimes.length];
      batch.set(doc.reference, {
        'status': 'completed',
        'isHistoryExample': true,
        'completedAt': Timestamp.fromDate(completedAt),
        'handoffVerified': true,
        'ratedByCustomer': true,
        'ratedByRunner': true,
        'ratingFromCustomer': 5.0,
        'ratingFromRunner': 5.0,
        'runnerEmail': 'demo_runner@queuego.mx',
        'ownerEmail': 'demo_customer@queuego.mx',
      }, SetOptions(merge: true));
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

  Stream<bool> streamHasRated({required String taskId, required String fromUserId}) {
    return _ratings
        .where('taskId', isEqualTo: taskId)
        .where('fromUserId', isEqualTo: fromUserId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<void> submitRating({
    required String taskId,
    required String fromUserId,
    required String toUserId,
    required double rating,
    required String role,
  }) async {
    if (rating < 1 || rating > 5) throw StateError('invalid_rating');
    if (fromUserId.isEmpty || toUserId.isEmpty) throw StateError('invalid_user');
    final taskRef = _tasks.doc(taskId);
    final taskSnap = await taskRef.get();
    final task = FirestoreTask.fromDoc(taskSnap);
    if (task.status != 'completed') {
      throw StateError('task_not_completed');
    }

    final existed = await _ratings
        .where('taskId', isEqualTo: taskId)
        .where('fromUserId', isEqualTo: fromUserId)
        .limit(1)
        .get();
    if (existed.docs.isNotEmpty) {
      throw StateError('already_rated');
    }

    await _ratings.add({
      'taskId': taskId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'rating': rating,
      'role': role,
      'createdAt': Timestamp.now(),
    });

    final isOwnerRating = role == 'owner';
    await taskRef.update({
      if (isOwnerRating) 'ratingFromCustomer': rating,
      if (isOwnerRating) 'ratedByCustomer': true,
      if (!isOwnerRating) 'ratingFromRunner': rating,
      if (!isOwnerRating) 'ratedByRunner': true,
    });

    await updateUserRating(toUserId);
  }

  Future<void> updateUserRating(String userId) async {
    final ratings = await FirebaseFirestore.instance
        .collection('ratings')
        .where('toUserId', isEqualTo: userId)
        .get();

    double avg = 0;
    if (ratings.docs.isNotEmpty) {
      avg = ratings.docs
              .map((e) => (e['rating'] as num).toDouble())
              .reduce((a, b) => a + b) /
          ratings.docs.length;
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'ratingAvg': avg,
      'ratingCount': ratings.docs.length,
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
      final ratingAvg = parseDouble(data['ratingAvg']);
      final ratingCount = parseInt(data['ratingCount']);
      final completed = parseInt(data['completedCount']);
      final cancelled = parseInt(data['cancelledCount']);
      final nextCompleted = math.max(0, completed + completedDelta);
      final nextCancelled = math.max(0, cancelled + cancelledDelta);
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

  List<FirestoreTask> _sortTasksByCompletedAtDesc(List<FirestoreTask> tasks) {
    final copy = [...tasks];
    copy.sort((a, b) {
      final completedA = a.completedAt;
      final completedB = b.completedAt;
      if (completedA == null && completedB == null) return 0;
      if (completedA == null) return 1;
      if (completedB == null) return -1;
      return completedB.compareTo(completedA);
    });
    return copy;
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

  String _normalizeUrgencyLevel(String value) {
    switch (value) {
      case 'priority':
      case 'urgent':
        return value;
      default:
        return 'normal';
    }
  }

  String _generateHandoffCode() {
    final value = math.Random().nextInt(9000) + 1000;
    return 'QG-$value';
  }

  int _pickDemoHistoryPriceMxn({
    required String title,
    required math.Random random,
    required Set<int> usedPrices,
    double? fallbackPrice,
  }) {
    final range = _demoHistoryPriceRangesMxn[title];
    if (range == null) {
      var fallback = parseDouble(fallbackPrice).round();
      if (fallback <= 0) fallback = 420;
      while (usedPrices.contains(fallback)) {
        fallback += 1;
      }
      usedPrices.add(fallback);
      return fallback;
    }

    final min = range[0];
    final max = range[1];
    var price = min + random.nextInt((max - min) + 1);
    var retries = 0;
    while (usedPrices.contains(price) && retries < 20) {
      price = min + random.nextInt((max - min) + 1);
      retries += 1;
    }
    while (usedPrices.contains(price)) {
      price += 1;
      if (price > max) {
        price = min;
      }
    }
    usedPrices.add(price);
    return price;
  }

  List<DateTime> _generateDemoCreatedTimes(DateTime now) {
    return [
      _demoDateAt(now: now, daysAgo: 1, hour: 9, minute: 7),
      _demoDateAt(now: now, daysAgo: 3, hour: 11, minute: 19),
      _demoDateAt(now: now, daysAgo: 4, hour: 14, minute: 34),
      _demoDateAt(now: now, daysAgo: 6, hour: 10, minute: 52),
      _demoDateAt(now: now, daysAgo: 7, hour: 16, minute: 26),
      _demoDateAt(now: now, daysAgo: 8, hour: 13, minute: 3),
      _demoDateAt(now: now, daysAgo: 11, hour: 17, minute: 41),
      _demoDateAt(now: now, daysAgo: 14, hour: 12, minute: 48),
    ];
  }

  DateTime _demoDateAt({
    required DateTime now,
    required int daysAgo,
    required int hour,
    required int minute,
  }) {
    final base = now.subtract(Duration(days: daysAgo));
    return DateTime(base.year, base.month, base.day, hour, minute);
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

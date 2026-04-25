import 'package:cloud_firestore/cloud_firestore.dart';

class TaskApplication {
  const TaskApplication({
    required this.id,
    required this.taskId,
    required this.runnerId,
    required this.runnerName,
    required this.runnerEmail,
    required this.proposedPriceMxn,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String runnerId;
  final String runnerName;
  final String? runnerEmail;
  final double? proposedPriceMxn;
  final String message;
  final String status;
  final DateTime? createdAt;

  factory TaskApplication.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return TaskApplication(
      id: doc.id,
      taskId: (data['taskId'] ?? '') as String,
      runnerId: (data['runnerId'] ?? '') as String,
      runnerName: (data['runnerName'] ?? '') as String,
      runnerEmail: data['runnerEmail'] as String?,
      proposedPriceMxn: _toNullableDouble(data['proposedPriceMxn']),
      message: (data['message'] ?? '') as String,
      status: (data['status'] ?? 'pending') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskApplication {
  const TaskApplication({
    required this.id,
    required this.taskId,
    required this.runnerId,
    required this.runnerName,
    required this.proposedPriceMxn,
    required this.estimatedArrivalHours,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String runnerId;
  final String runnerName;
  final double proposedPriceMxn;
  final double estimatedArrivalHours;
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
      proposedPriceMxn: _toDouble(data['proposedPriceMxn']),
      estimatedArrivalHours: _toDouble(data['estimatedArrivalHours']),
      message: (data['message'] ?? '') as String,
      status: (data['status'] ?? 'pending') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskMessage {
  const TaskMessage({
    required this.id,
    required this.taskId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime? createdAt;

  factory TaskMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return TaskMessage(
      id: doc.id,
      taskId: (data['taskId'] ?? '') as String,
      senderId: (data['senderId'] ?? '') as String,
      senderRole: (data['senderRole'] ?? '') as String,
      text: (data['text'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

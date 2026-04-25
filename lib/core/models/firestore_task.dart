import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTask {
  const FirestoreTask({
    required this.id,
    required this.title,
    required this.location,
    required this.note,
    required this.startDate,
    required this.startTime,
    required this.workHours,
    required this.waitHours,
    required this.totalHours,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.ownerId,
  });

  final String id;
  final String title;
  final String location;
  final String note;
  final String startDate;
  final String startTime;
  final double workHours;
  final double waitHours;
  final double totalHours;
  final double price;
  final String status;
  final DateTime? createdAt;
  final String ownerId;

  factory FirestoreTask.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FirestoreTask(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      location: (data['location'] ?? '') as String,
      note: (data['note'] ?? '') as String,
      startDate: (data['startDate'] ?? '') as String,
      startTime: (data['startTime'] ?? '') as String,
      workHours: _numToDouble(data['workHours']),
      waitHours: _numToDouble(data['waitHours']),
      totalHours: _numToDouble(data['totalHours']),
      price: _numToDouble(data['price']),
      status: (data['status'] ?? 'open') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      ownerId: (data['ownerId'] ?? '') as String,
    );
  }

  static double _numToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

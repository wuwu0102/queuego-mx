import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTask {
  const FirestoreTask({
    required this.id,
    required this.title,
    required this.location,
    required this.note,
    required this.instructions,
    required this.startDate,
    required this.startTime,
    required this.basePrice,
    required this.urgencyLevel,
    required this.estimatedHours,
    required this.workHours,
    required this.waitHours,
    required this.totalHours,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.ownerId,
    required this.ownerEmail,
    required this.ownerRole,
    required this.runnerId,
    required this.runnerEmail,
    required this.accepterId,
    required this.acceptedAt,
    required this.arrivedAt,
    required this.progressNote,
    required this.progressImageUrl,
    required this.progressUpdatedAt,
    required this.readyForHandoffAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.whatsappNumber,
    required this.handoffCode,
    required this.handoffVerified,
    required this.ratingFromCustomer,
    required this.ratingFromRunner,
    required this.ratedByCustomer,
    required this.ratedByRunner,
    required this.isDemo,
    required this.isHistoryExample,
  });

  final String id;
  final String title;
  final String location;
  final String note;
  final String instructions;
  final String startDate;
  final String startTime;
  final double basePrice;
  final String urgencyLevel;
  final double estimatedHours;
  final double workHours;
  final double waitHours;
  final double totalHours;
  final double price;
  final String status;
  final DateTime? createdAt;
  final String ownerId;
  final String? ownerEmail;
  final String ownerRole;
  final String? runnerId;
  final String? runnerEmail;
  final String? accepterId;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final String? progressNote;
  final String? progressImageUrl;
  final DateTime? progressUpdatedAt;
  final DateTime? readyForHandoffAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? whatsappNumber;
  final String handoffCode;
  final bool handoffVerified;
  final double? ratingFromCustomer;
  final double? ratingFromRunner;
  final bool ratedByCustomer;
  final bool ratedByRunner;
  final bool isDemo;
  final bool isHistoryExample;

  factory FirestoreTask.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FirestoreTask(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      location: (data['location'] ?? '') as String,
      note: (data['note'] ?? '') as String,
      instructions: (data['instructions'] ?? data['note'] ?? '') as String,
      startDate: (data['startDate'] ?? '') as String,
      startTime: (data['startTime'] ?? '') as String,
      basePrice: _numToDouble(data['basePrice']),
      urgencyLevel: (data['urgencyLevel'] ?? 'normal') as String,
      estimatedHours: _numToDouble(data['estimatedHours'] ?? data['workHours']),
      workHours: _numToDouble(data['workHours'] ?? data['estimatedHours']),
      waitHours: _numToDouble(data['waitHours']),
      totalHours: _numToDouble(data['totalHours']),
      price: _numToDouble(data['price']),
      status: (data['status'] ?? 'open') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      ownerId: (data['ownerId'] ?? '') as String,
      ownerEmail: data['ownerEmail'] as String?,
      ownerRole: (data['ownerRole'] ?? 'customer') as String,
      runnerId: data['runnerId'] as String?,
      runnerEmail: data['runnerEmail'] as String?,
      accepterId: data['accepterId'] as String?,
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      arrivedAt: (data['arrivedAt'] as Timestamp?)?.toDate(),
      progressNote: data['progressNote'] as String?,
      progressImageUrl: data['progressImageUrl'] as String?,
      progressUpdatedAt: (data['progressUpdatedAt'] as Timestamp?)?.toDate(),
      readyForHandoffAt: (data['readyForHandoffAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      whatsappNumber: data['whatsappNumber'] as String?,
      handoffCode: (data['handoffCode'] ?? '') as String,
      handoffVerified: (data['handoffVerified'] ?? false) as bool,
      ratingFromCustomer: _nullableNumToDouble(data['ratingFromCustomer']),
      ratingFromRunner: _nullableNumToDouble(data['ratingFromRunner']),
      ratedByCustomer: (data['ratedByCustomer'] ?? false) as bool,
      ratedByRunner: (data['ratedByRunner'] ?? false) as bool,
      isDemo: (data['isDemo'] ?? false) as bool,
      isHistoryExample: (data['isHistoryExample'] ?? false) as bool,
    );
  }

  static double _numToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static double? _nullableNumToDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}

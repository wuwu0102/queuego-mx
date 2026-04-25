import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    required this.createdAt,
    required this.ratingAvg,
    required this.ratingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.trustScore,
  });

  final String uid;
  final String email;
  final String role;
  final String displayName;
  final DateTime? createdAt;
  final double ratingAvg;
  final int ratingCount;
  final int completedCount;
  final int cancelledCount;
  final double trustScore;

  bool get canPostTasks => role == 'customer' || role == 'both';
  bool get canTakeTasks => role == 'runner' || role == 'both';

  factory UserProfile.fromDoc(String uid, Map<String, dynamic>? data) {
    final raw = data ?? <String, dynamic>{};
    return UserProfile(
      uid: uid,
      email: (raw['email'] ?? '') as String,
      role: (raw['role'] ?? 'both') as String,
      displayName: (raw['displayName'] ?? '') as String,
      createdAt: (raw['createdAt'] as Timestamp?)?.toDate(),
      ratingAvg: (raw['ratingAvg'] as num?)?.toDouble() ?? 5,
      ratingCount: (raw['ratingCount'] as num?)?.toInt() ?? 0,
      completedCount: (raw['completedCount'] as num?)?.toInt() ?? 0,
      cancelledCount: (raw['cancelledCount'] as num?)?.toInt() ?? 0,
      trustScore: (raw['trustScore'] as num?)?.toDouble() ?? 80,
    );
  }
}

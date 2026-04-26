import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/number_parsing.dart';

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
    required this.isAdmin,
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
  final bool isAdmin;

  bool get canPostTasks => role == 'customer' || role == 'both' || role == 'user' || role == 'admin';
  bool get canTakeTasks => role == 'runner' || role == 'both' || role == 'user' || role == 'admin';

  factory UserProfile.fromDoc(String uid, Map<String, dynamic>? data) {
    final raw = data ?? <String, dynamic>{};
    return UserProfile(
      uid: uid,
      email: (raw['email'] ?? '') as String,
      role: (raw['role'] ?? 'both') as String,
      displayName: (raw['displayName'] ?? '') as String,
      createdAt: (raw['createdAt'] as Timestamp?)?.toDate(),
      ratingAvg: parseDouble(raw['ratingAvg'], fallback: 5.0),
      ratingCount: parseInt(raw['ratingCount']),
      completedCount: parseInt(raw['completedCount']),
      cancelledCount: parseInt(raw['cancelledCount']),
      trustScore: parseDouble(raw['trustScore'], fallback: 80.0),
      isAdmin: raw['isAdmin'] == true,
    );
  }
}

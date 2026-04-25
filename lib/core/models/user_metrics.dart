import '../utils/number_parsing.dart';

class UserMetrics {
  const UserMetrics({
    required this.uid,
    required this.ratingAvg,
    required this.ratingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.trustScore,
  });

  final String uid;
  final double ratingAvg;
  final int ratingCount;
  final int completedCount;
  final int cancelledCount;
  final double trustScore;

  factory UserMetrics.fromDoc(String uid, Map<String, dynamic>? data) {
    final raw = data ?? <String, dynamic>{};
    return UserMetrics(
      uid: uid,
      ratingAvg: parseDouble(raw['ratingAvg']),
      ratingCount: parseInt(raw['ratingCount']),
      completedCount: parseInt(raw['completedCount']),
      cancelledCount: parseInt(raw['cancelledCount']),
      trustScore: parseDouble(raw['trustScore']),
    );
  }
}

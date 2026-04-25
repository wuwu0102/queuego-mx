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
      ratingAvg: (raw['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (raw['ratingCount'] as num?)?.toInt() ?? 0,
      completedCount: (raw['completedCount'] as num?)?.toInt() ?? 0,
      cancelledCount: (raw['cancelledCount'] as num?)?.toInt() ?? 0,
      trustScore: (raw['trustScore'] as num?)?.toDouble() ?? 0,
    );
  }
}

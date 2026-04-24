import '../constants/app_enums.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.email,
    this.phone,
    required this.language,
    this.rating = 0,
    this.completedTasks = 0,
    this.isVerified = false,
    this.isBlocked = false,
    required this.createdAt,
  });

  final String uid;
  final UserRole role;
  final String displayName;
  final String email;
  final String? phone;
  final String language;
  final double rating;
  final int completedTasks;
  final bool isVerified;
  final bool isBlocked;
  final DateTime createdAt;
}

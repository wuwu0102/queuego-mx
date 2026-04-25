import '../models/user_profile.dart';

class AuthService {
  Future<UserProfile> loginWithEmail({required String email, required String role}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return UserProfile(
      uid: 'mock_$role',
      role: role,
      displayName: role == 'customer' ? 'Demo Customer' : 'Demo Runner',
      email: email,
      createdAt: DateTime.now(),
      ratingAvg: role == 'runner' ? 4.8 : 5,
      ratingCount: role == 'runner' ? 12 : 0,
      completedCount: role == 'runner' ? 42 : 0,
      cancelledCount: 0,
      trustScore: role == 'runner' ? 96 : 80,
      isAdmin: false,
    );
  }
}

import '../constants/app_enums.dart';
import '../models/user_profile.dart';

class AuthService {
  Future<UserProfile> loginWithEmail({required String email, required UserRole role}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return UserProfile(
      uid: 'mock_${role.name}',
      role: role,
      displayName: role == UserRole.customer ? 'Demo Customer' : 'Demo Runner',
      email: email,
      language: 'en',
      createdAt: DateTime.now(),
      isVerified: role == UserRole.runner,
      rating: role == UserRole.runner ? 4.8 : 0,
      completedTasks: role == UserRole.runner ? 42 : 0,
    );
  }
}

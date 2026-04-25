import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/onboarding/auth_screen.dart';
import 'auth_constants.dart';
import 'user_profile_service.dart';

bool isFormallyLoggedIn(User? user) {
  final email = user?.email?.trim();
  final isAnonymous = user?.isAnonymous ?? true;
  return !isAnonymous && (email != null && email.isNotEmpty);
}

bool isAdminUser(User? user) {
  final isAnonymous = user?.isAnonymous ?? true;
  if (user == null || isAnonymous) return false;
  return isAdminEmail(user.email);
}

Future<bool> ensureFormalLogin(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (isFormallyLoggedIn(user)) return true;
  await showLoginModal(context);
  final refreshed = FirebaseAuth.instance.currentUser;
  return isFormallyLoggedIn(refreshed);
}

Future<bool> ensureRoleAllowed(
  BuildContext context, {
  required bool forPosting,
}) async {
  final canContinue = await ensureFormalLogin(context);
  if (!canContinue) return false;
  final user = FirebaseAuth.instance.currentUser;
  if (isAdminUser(user)) return true;
  final uid = user?.uid ?? '';
  final profile = await UserProfileService.instance.fetchProfile(uid);
  final role = profile?.role ?? 'both';
  final allowed = forPosting
      ? (role == 'customer' || role == 'both')
      : (role == 'runner' || role == 'both');
  if (allowed) return true;
  if (!context.mounted) return false;
  final message = forPosting
      ? 'Current role cannot post tasks. Switch role in Settings.'
      : 'Current role cannot take tasks. Switch role in Settings.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  return false;
}

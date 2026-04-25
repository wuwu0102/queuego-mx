import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/onboarding/auth_screen.dart';

const adminEmails = [
  'chttwm@gmail.com',
  // Legacy typo kept for compatibility with previous instructions/account input.
  'chhtwm@gmail.com',
];

bool isFormallyLoggedIn(User? user) {
  if (user == null) return false;
  final email = user.email;
  return !user.isAnonymous && (email != null && email.isNotEmpty);
}

bool isAdminUser(User? user) {
  if (user == null) return false;
  if (user.isAnonymous) return false;
  final email = user.email?.toLowerCase().trim();
  return adminEmails.contains(email);
}

Future<bool> ensureFormalLogin(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (isFormallyLoggedIn(user)) return true;
  await showLoginModal(context);
  final refreshed = FirebaseAuth.instance.currentUser;
  return isFormallyLoggedIn(refreshed);
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/onboarding/auth_screen.dart';

const adminEmails = [
  'chttwm@gmail.com',
];

bool isFormallyLoggedIn(User? user) {
  final email = user?.email?.trim();
  final isAnonymous = user?.isAnonymous ?? true;
  return !isAnonymous && (email != null && email.isNotEmpty);
}

bool isAdminUser(User? user) {
  final isAnonymous = user?.isAnonymous ?? true;
  if (isAnonymous) return false;
  final email = user?.email?.toLowerCase().trim();
  return email != null && adminEmails.contains(email);
}

Future<bool> ensureFormalLogin(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (isFormallyLoggedIn(user)) return true;
  await showLoginModal(context);
  final refreshed = FirebaseAuth.instance.currentUser;
  return isFormallyLoggedIn(refreshed);
}

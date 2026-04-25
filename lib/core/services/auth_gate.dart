import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/onboarding/auth_screen.dart';

bool isFormallyLoggedIn(User? user) {
  if (user == null) return false;
  final email = user.email;
  return !user.isAnonymous && (email != null && email.isNotEmpty);
}

Future<bool> ensureFormalLogin(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (isFormallyLoggedIn(user)) return true;
  await showLoginModal(context);
  final refreshed = FirebaseAuth.instance.currentUser;
  return isFormallyLoggedIn(refreshed);
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/onboarding/auth_screen.dart';
import '../i18n/app_strings.dart';

bool isFormallyLoggedIn(User? user) {
  final isAnonymous = user?.isAnonymous ?? true;
  final email = user?.email;
  return !isAnonymous && (email != null && email.isNotEmpty);
}

Future<bool> ensureFormalLogin(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (isFormallyLoggedIn(user)) return true;
  final s = AppStrings.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s.t('formalLoginRequired'))),
  );
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AuthScreen()),
  );
  final refreshed = FirebaseAuth.instance.currentUser;
  return isFormallyLoggedIn(refreshed);
}

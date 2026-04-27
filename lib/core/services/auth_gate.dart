import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/auth_screen.dart';
import 'auth_constants.dart';
import 'user_profile_service.dart';

enum PendingAuthAction {
  publishTask,
  takeTask,
  myTasks,
  myApplications,
  activeTasks,
}

const _pendingAuthActionKey = 'pending_auth_action';

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

Future<void> savePendingAuthAction(PendingAuthAction action) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_pendingAuthActionKey, action.name);
}

Future<PendingAuthAction?> consumePendingAuthAction() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_pendingAuthActionKey);
  if (raw == null || raw.isEmpty) return null;
  await prefs.remove(_pendingAuthActionKey);
  for (final value in PendingAuthAction.values) {
    if (value.name == raw) return value;
  }
  return null;
}

Future<void> clearPendingAuthAction() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_pendingAuthActionKey);
}

Future<bool> ensureFormalLogin(
  BuildContext context, {
  PendingAuthAction? pendingAction,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (isFormallyLoggedIn(user)) return true;
  if (pendingAction != null) {
    await savePendingAuthAction(pendingAction);
  }
  await showLoginModal(context);
  final refreshed = FirebaseAuth.instance.currentUser;
  final success = isFormallyLoggedIn(refreshed);
  if (success) {
    await clearPendingAuthAction();
  }
  return success;
}

Future<bool> ensureRoleAllowed(
  BuildContext context, {
  required bool forPosting,
  PendingAuthAction? pendingAction,
}) async {
  final canContinue = await ensureFormalLogin(
    context,
    pendingAction: pendingAction ??
        (forPosting ? PendingAuthAction.publishTask : PendingAuthAction.takeTask),
  );
  if (!canContinue) return false;
  final user = FirebaseAuth.instance.currentUser;
  if (isAdminUser(user)) return true;
  final uid = user?.uid ?? '';
  final profile = await UserProfileService.instance.fetchProfile(uid);
  final role = profile?.role ?? 'both';
  final allowed = forPosting
      ? (role == 'customer' || role == 'both' || role == 'user')
      : (role == 'runner' || role == 'both' || role == 'user');
  if (allowed) return true;
  if (!context.mounted) return false;
  final message = forPosting
      ? 'Current role cannot post tasks. Switch role in Settings.'
      : 'Current role cannot take tasks. Switch role in Settings.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  return false;
}

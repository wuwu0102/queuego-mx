import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import 'auth_constants.dart';

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  Future<bool> ensureProfile(User? user) async {
    final isAnonymous = user?.isAnonymous ?? true;
    if (user == null || isAnonymous) return false;
    final email = user.email?.toLowerCase().trim();
    if (email == null || email.isEmpty) return false;
    final isAdmin = isAdminEmail(email);
    final ref = _users.doc(user.uid);
    final existing = await ref.get();
    final data = existing.data() ?? <String, dynamic>{};
    final defaults = <String, dynamic>{
      'uid': user.uid,
      'email': email,
      'displayName': _defaultDisplayName(user.displayName, email),
      'createdAt': FieldValue.serverTimestamp(),
      'ratingAvg': 5.0,
      'ratingCount': 0,
      'completedCount': 0,
      'cancelledCount': 0,
      'trustScore': 80.0,
      'role': 'both',
      'isAdmin': false,
    };
    final updates = <String, dynamic>{};
    for (final entry in defaults.entries) {
      if (!data.containsKey(entry.key) || data[entry.key] == null) {
        updates[entry.key] = entry.value;
      }
    }
    updates['isAdmin'] = isAdmin;
    if (isAdmin) {
      updates['role'] = 'both';
    }
    if (updates.isEmpty) return false;
    await ref.set(updates, SetOptions(merge: true));
    return !existing.exists;
  }

  Stream<UserProfile?> streamProfile(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(uid, doc.data());
    });
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(uid, doc.data());
  }

  Future<void> updateRole({required String uid, required String role}) async {
    if (uid.isEmpty) return;
    await _users.doc(uid).set({'role': role}, SetOptions(merge: true));
  }
  String _defaultDisplayName(String? displayName, String email) {
    final candidate = displayName?.trim() ?? '';
    if (candidate.isNotEmpty) return candidate;
    return email.split('@').first;
  }
}

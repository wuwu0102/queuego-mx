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
    final provider = _providerLabel(user);
    final defaults = <String, dynamic>{
      'uid': user.uid,
      'email': email,
      'displayName': _defaultDisplayName(user.displayName, email),
      'photoURL': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) {
      defaults.addAll(<String, dynamic>{
        'createdAt': FieldValue.serverTimestamp(),
        'ratingAvg': 0,
        'ratingCount': 0,
        'completedCount': 0,
        'cancelledCount': 0,
        'trustScore': 0,
        'provider': provider,
        'role': isAdmin ? 'admin' : 'user',
        'isAdmin': isAdmin,
      });
    }
    final updates = <String, dynamic>{};
    for (final entry in defaults.entries) {
      if (!data.containsKey(entry.key) || data[entry.key] == null) {
        updates[entry.key] = entry.value;
      }
    }
    if (!data.containsKey('provider') || data['provider'] == null) {
      updates['provider'] = provider;
    }
    final existingAdmin = data['isAdmin'] == true;
    if (!data.containsKey('isAdmin') || (isAdmin && !existingAdmin)) {
      updates['isAdmin'] = isAdmin;
    }
    if (isAdmin && data['role'] != 'admin') {
      updates['role'] = 'admin';
    }
    updates['updatedAt'] = FieldValue.serverTimestamp();
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
    await _users.doc(uid).set({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _providerLabel(User user) {
    final ids = user.providerData.map((p) => p.providerId).toSet();
    if (ids.contains('password')) return 'password';
    return 'password';
  }
  String _defaultDisplayName(String? displayName, String email) {
    final candidate = displayName?.trim() ?? '';
    if (candidate.isNotEmpty) return candidate;
    return email.split('@').first;
  }
}

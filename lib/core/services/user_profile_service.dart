import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  Future<bool> ensureProfile(User user) async {
    if (user.isAnonymous) return false;
    final email = user.email?.trim();
    if (email == null || email.isEmpty) return false;
    final ref = _users.doc(user.uid);
    final existing = await ref.get();
    if (existing.exists) return false;
    await ref.set({
      'email': email,
      'role': 'both',
      'displayName': (user.displayName ?? email.split('@').first).trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'ratingAvg': 5.0,
      'ratingCount': 0,
      'completedCount': 0,
      'cancelledCount': 0,
      'trustScore': 80.0,
    }, SetOptions(merge: true));
    return true;
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
}

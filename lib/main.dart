import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FirebaseAuth.instance.getRedirectResult();
  } catch (_) {
    // Ignore stale/unavailable redirect payloads; popup is the primary web flow.
  }
  runApp(const QueueGoApp());
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupNotice;

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error) {
    startupNotice = 'Firebase initialization failed: $error';
    debugPrint('Firebase initialization failed: $error');
  }

  runApp(QueueGoApp(startupNotice: startupNotice));
}

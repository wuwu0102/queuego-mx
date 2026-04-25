import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupNotice;
  var useMockMode = false;

  try {
    if (kIsWeb && !DefaultFirebaseOptions.hasValidWebConfig) {
      throw const _FirebaseConfigMissingException();
    }

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.signInAnonymously();
  } on _FirebaseConfigMissingException {
    useMockMode = true;
    startupNotice = 'Firebase config missing.';
  } catch (error) {
    useMockMode = true;
    startupNotice = 'Firebase initialization failed.';
    debugPrint('Firebase initialization failed: $error');
  }

  runApp(
    QueueGoApp(
      startupNotice: startupNotice,
      useMockMode: useMockMode,
    ),
  );
}

class _FirebaseConfigMissingException implements Exception {
  const _FirebaseConfigMissingException();
}

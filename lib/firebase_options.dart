import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static const String _placeholderPrefix = 'YOUR_WEB_';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError('This project is configured for Firebase Web in this task.');
  }

  static bool get hasValidWebConfig {
    final options = web;
    return [
      options.apiKey,
      options.appId,
      options.messagingSenderId,
      options.projectId,
      options.authDomain,
      options.storageBucket,
      options.measurementId,
    ].every(
      (value) => value != null && value.isNotEmpty && !value.startsWith(_placeholderPrefix),
    );
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: 'YOUR_WEB_API_KEY'),
        appId: const String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: 'YOUR_WEB_APP_ID'),
        messagingSenderId: const String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID', defaultValue: 'YOUR_WEB_MESSAGING_SENDER_ID'),
        projectId: const String.fromEnvironment('FIREBASE_WEB_PROJECT_ID', defaultValue: 'YOUR_WEB_PROJECT_ID'),
        authDomain: const String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN', defaultValue: 'YOUR_WEB_AUTH_DOMAIN'),
        storageBucket: const String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET', defaultValue: 'YOUR_WEB_STORAGE_BUCKET'),
        measurementId: const String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID', defaultValue: 'YOUR_WEB_MEASUREMENT_ID'),
      );
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError('DefaultFirebaseOptions are not configured for this platform.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAj4J4goarjV9pzrDKbTK-zyEGtA2Np4JRQ',
    authDomain: 'queuego-mx.firebaseapp.com',
    projectId: 'queuego-mx',
    storageBucket: 'queuego-mx.firebasestorage.app',
    messagingSenderId: '785569032449',
    appId: '1:785569032449:web:e7667caff602b048735300',
  );
}

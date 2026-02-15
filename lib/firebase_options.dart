import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4JI_4DP0JFPYRMRAjX2hUk81x6y8mwEk',
    appId: '1:409230817801:android:aa4d4f1a9aa4fc0fc8d6d8',
    messagingSenderId: '409230817801',
    projectId: 'bookshare-b65b8',
    storageBucket: 'bookshare-b65b8.firebasestorage.app',
  );
}
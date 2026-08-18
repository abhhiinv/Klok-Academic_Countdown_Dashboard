// GENERATED FILE — DO NOT EDIT MANUALLY
// Run: flutterfire configure
//
// Replace this file with your actual Firebase configuration by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// See: https://firebase.flutter.dev/docs/cli

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
      return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for '
          '${defaultTargetPlatform.name} - please run flutterfire configure.',
        );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TODO: Replace with actual values from Firebase Console / flutterfire CLI
  // ─────────────────────────────────────────────────────────────────────────

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('ANDROID_API_KEY'),
    appId: String.fromEnvironment('ANDROID_APP_ID'),
    messagingSenderId: '899914493923',
    projectId: 'klok-events',
    storageBucket: 'klok-events.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('IOS_API_KEY'),
    appId: String.fromEnvironment('IOS_APP_ID'),
    messagingSenderId: '899914493923',
    projectId: 'klok-events',
    storageBucket: 'klok-events.firebasestorage.app',
    iosBundleId: 'com.klok.klok',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('WEB_API_KEY'),
    appId: String.fromEnvironment('WEB_APP_ID'),
    messagingSenderId: '899914493923',
    projectId: 'klok-events',
    authDomain: 'klok-events.firebaseapp.com',
    storageBucket: 'klok-events.firebasestorage.app',
  );
}

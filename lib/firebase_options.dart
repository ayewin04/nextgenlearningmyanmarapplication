// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // REPLACE THESE WITH YOUR ACTUAL FIREBASE CONFIG
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCOZu0msSsnkYQkfY-aYP5hiU-iSp0VCXo',
    appId: '1:641642050064:web:f0bbb148d729bfbbe69095',
    messagingSenderId: '641642050064',
    projectId: 'polyglot-exam-app',
    authDomain: 'polyglot-exam-app.firebaseapp.com',
    storageBucket: 'polyglot-exam-app.firebasestorage.app',
    measurementId: '641642050064',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'polyglot-exam-app',
    storageBucket: 'polyglot-exam-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'polyglot-exam-app',
    storageBucket: 'polyglot-exam-app.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.yourcompany.polyglotapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'polyglot-exam-app',
    storageBucket: 'polyglot-exam-app.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.yourcompany.polyglotapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'polyglot-exam-app',
    authDomain: 'polyglot-exam-app.firebaseapp.com',
    storageBucket: 'polyglot-exam-app.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'polyglot-exam-app',
    authDomain: 'polyglot-exam-app.firebaseapp.com',
    storageBucket: 'polyglot-exam-app.appspot.com',
  );
}
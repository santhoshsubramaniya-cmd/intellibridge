// firebase_options.dart
// Generated from your intellibridge-36e51 Firebase project.
// Values sourced from: android/app/google-services.json + firebase.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9ukwvf_W5UpPnyqgU9klD9i2nh6A2RZE',
    appId: '1:133240949613:android:1317be759df6b5314f2864',
    messagingSenderId: '133240949613',
    projectId: 'intellibridge-36e51',
    storageBucket: 'intellibridge-36e51.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9ukwvf_W5UpPnyqgU9klD9i2nh6A2RZE',
    appId: '1:133240949613:ios:df68af648903d18a4f2864',
    messagingSenderId: '133240949613',
    projectId: 'intellibridge-36e51',
    storageBucket: 'intellibridge-36e51.firebasestorage.app',
    iosBundleId: 'com.santh.intellibridge',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA9ukwvf_W5UpPnyqgU9klD9i2nh6A2RZE',
    appId: '1:133240949613:web:3676bf72db5149294f2864',
    messagingSenderId: '133240949613',
    projectId: 'intellibridge-36e51',
    storageBucket: 'intellibridge-36e51.firebasestorage.app',
  );
}

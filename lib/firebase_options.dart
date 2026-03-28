// lib/firebase_options.dart
// Generated from your Firebase project: intellibridge-36e51
//
// IMPORTANT: The android appId here MUST match the mobilesdk_app_id in
// android/app/google-services.json — they are different registered apps
// in your Firebase project. Always use the google-services.json value.

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Android ───────────────────────────────────────────────────────────────
  // appId taken from android/app/google-services.json → mobilesdk_app_id
  // apiKey taken from google-services.json → api_key → current_key
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9ukwvf_W5UpPnyqgU9klD9i2nh6A2RZE',
    appId: '1:133240949613:android:417030080c7ebf454f2864',
    messagingSenderId: '133240949613',
    projectId: 'intellibridge-36e51',
    storageBucket: 'intellibridge-36e51.firebasestorage.app',
  );

  // ── iOS ───────────────────────────────────────────────────────────────────
  // appId from firebase.json → ios appId
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9ukwvf_W5UpPnyqgU9klD9i2nh6A2RZE',
    appId: '1:133240949613:ios:df68af648903d18a4f2864',
    messagingSenderId: '133240949613',
    projectId: 'intellibridge-36e51',
    storageBucket: 'intellibridge-36e51.firebasestorage.app',
    iosBundleId: 'com.santh.intellibridge',
  );

  // ── macOS ─────────────────────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA9ukwvf_W5UpPnyqgU9klD9i2nh6A2RZE',
    appId: '1:133240949613:ios:df68af648903d18a4f2864',
    messagingSenderId: '133240949613',
    projectId: 'intellibridge-36e51',
    storageBucket: 'intellibridge-36e51.firebasestorage.app',
    iosBundleId: 'com.santh.intellibridge',
  );

  // ── Web ───────────────────────────────────────────────────────────────────
  // appId from firebase.json → web appId
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA9ukwvf_W5UpPnyqgU9klD9i2nh6A2RZE',
    appId: '1:133240949613:web:3676bf72db5149294f2864',
    messagingSenderId: '133240949613',
    projectId: 'intellibridge-36e51',
    storageBucket: 'intellibridge-36e51.firebasestorage.app',
  );

  // ── Windows ───────────────────────────────────────────────────────────────
  // appId from firebase.json → windows appId
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA9ukwvf_W5UpPnyqgU9klD9i2nh6A2RZE',
    appId: '1:133240949613:web:da7fdfc856c0da404f2864',
    messagingSenderId: '133240949613',
    projectId: 'intellibridge-36e51',
    storageBucket: 'intellibridge-36e51.firebasestorage.app',
  );
}

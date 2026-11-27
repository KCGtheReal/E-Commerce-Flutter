// Generated from official `firebase apps:sdkconfig` outputs for project
// `reset-store-ecommerce` (Standard Edition `(default)` database in asia-southeast1).
// Ignore unused file_names lint when keeping standard FlutterFire naming.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for RESET Store Flutter client platforms.
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
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAl6uIP23GKZUdmuyZ_Pvkh9nN3GSUmrvQ',
    appId: '1:380926366953:web:662c985f0af96e3efe8c78',
    messagingSenderId: '380926366953',
    projectId: 'reset-store-ecommerce',
    authDomain: 'reset-store-ecommerce.firebaseapp.com',
    storageBucket: 'reset-store-ecommerce.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMrt0tZdzccjMK00HxXDdgz1n6Z2Yi61U',
    appId: '1:380926366953:android:f970f24e557ee025fe8c78',
    messagingSenderId: '380926366953',
    projectId: 'reset-store-ecommerce',
    storageBucket: 'reset-store-ecommerce.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkDmCwWjmsdgqB45z8B7ou6s1gE5ekMqM',
    appId: '1:380926366953:ios:b316bde7edab0866fe8c78',
    messagingSenderId: '380926366953',
    projectId: 'reset-store-ecommerce',
    storageBucket: 'reset-store-ecommerce.firebasestorage.app',
    iosBundleId: 'store.reset.resetStore',
  );
}

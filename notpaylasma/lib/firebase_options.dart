// Firebase client metadata. API keys are supplied via --dart-define-from-file.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    appId: '1:481457976208:web:9a665b41730e3e27143915',
    messagingSenderId: '481457976208',
    projectId: 'not-paylasma-proje',
    authDomain: 'not-paylasma-proje.firebaseapp.com',
    storageBucket: 'not-paylasma-proje.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    appId: '1:481457976208:android:e7b1e9750e1aa0e8143915',
    messagingSenderId: '481457976208',
    projectId: 'not-paylasma-proje',
    storageBucket: 'not-paylasma-proje.firebasestorage.app',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_MACOS_API_KEY'),
    appId: '1:481457976208:ios:14e717a6e8d125e3143915',
    messagingSenderId: '481457976208',
    projectId: 'not-paylasma-proje',
    storageBucket: 'not-paylasma-proje.firebasestorage.app',
    iosBundleId: 'com.example.notpaylas',
  );
}

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        return ios;
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

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY']!,
    appId: '1:1023231785912:web:70faa45b3990dab9e1ed4d',
    messagingSenderId: '1023231785912',
    projectId: 'runrealm',
    authDomain: 'runrealm.firebaseapp.com',
    storageBucket: 'runrealm.firebasestorage.app',
    measurementId: 'G-2QH528HW7P',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY']!,
    appId: '1:1023231785912:android:70faa45b3990dab9e1ed4d',
    messagingSenderId: '1023231785912',
    projectId: 'runrealm',
    storageBucket: 'runrealm.firebasestorage.app',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY']!,
    appId: '1:1023231785912:ios:70faa45b3990dab9e1ed4d',
    messagingSenderId: '1023231785912',
    projectId: 'runrealm',
    storageBucket: 'runrealm.firebasestorage.app',
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_MACOS_API_KEY']!,
    appId: '1:1023231785912:macos:70faa45b3990dab9e1ed4d',
    messagingSenderId: '1023231785912',
    projectId: 'runrealm',
    storageBucket: 'runrealm.firebasestorage.app',
  );
}

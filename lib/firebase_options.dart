import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform. android:
        return android;
      case TargetPlatform.windows:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD6d3trx91E6N6CWDXNcnB3Clq-r_F--yg',
    appId: '1:964424450630:web:e36c07c698948056cd0047',
    messagingSenderId: '964424450630',
    projectId: 'elearning-f6087',
    authDomain: 'elearning-f6087.firebaseapp.com',
    storageBucket: 'elearning-f6087.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6d3trx91E6N6CWDXNcnB3Clq-r_F--yg',
    appId: '1:964424450630:web:e36c07c698948056cd0047',
    messagingSenderId: '964424450630',
    projectId: 'elearning-f6087',
    storageBucket: 'elearning-f6087.firebasestorage.app',
  );
}
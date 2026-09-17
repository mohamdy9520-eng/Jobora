
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
    apiKey: 'AIzaSyC4h57mPlMUPBvVlLK_RSPqvvwxfSgfvrg',
    appId: '1:175598644174:web:5622db39e248c66a1ad99f',
    messagingSenderId: '175598644174',
    projectId: 'jobora-6b217',
    authDomain: 'jobora-6b217.firebaseapp.com',
    storageBucket: 'jobora-6b217.firebasestorage.app',
    measurementId: 'G-7F3923JJ3J',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDIGr2zpNsfymaJV_0NMNuXNITsk90a61E',
    appId: '1:175598644174:android:3b6a96abf9e6f3b21ad99f',
    messagingSenderId: '175598644174',
    projectId: 'jobora-6b217',
    storageBucket: 'jobora-6b217.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAhrx6sIqY4QF0buFagxAChwP4IVK3CaWE',
    appId: '1:175598644174:ios:92eb11d1949298941ad99f',
    messagingSenderId: '175598644174',
    projectId: 'jobora-6b217',
    storageBucket: 'jobora-6b217.firebasestorage.app',
    iosBundleId: 'com.jobora.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAhrx6sIqY4QF0buFagxAChwP4IVK3CaWE',
    appId: '1:175598644174:ios:92eb11d1949298941ad99f',
    messagingSenderId: '175598644174',
    projectId: 'jobora-6b217',
    storageBucket: 'jobora-6b217.firebasestorage.app',
    iosBundleId: 'com.jobora.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC4h57mPlMUPBvVlLK_RSPqvvwxfSgfvrg',
    appId: '1:175598644174:web:b5df32e6bf651b6b1ad99f',
    messagingSenderId: '175598644174',
    projectId: 'jobora-6b217',
    authDomain: 'jobora-6b217.firebaseapp.com',
    storageBucket: 'jobora-6b217.firebasestorage.app',
    measurementId: 'G-HSXH15MTHW',
  );
}

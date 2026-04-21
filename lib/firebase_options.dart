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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAFkjilSFgJ4Smnn5MkoN_xd5hFIbEBDQ4',
    appId: '1:629077057974:web:placeholder',
    messagingSenderId: '629077057974',
    projectId: 'bambare-tms-e1cc5',
    storageBucket: 'bambare-tms-e1cc5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAFkjilSFgJ4Smnn5MkoN_xd5hFIbEBDQ4',
    appId: '1:629077057974:android:abc123def456',
    messagingSenderId: '629077057974',
    projectId: 'bambare-tms-e1cc5',
    storageBucket: 'bambare-tms-e1cc5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBeLW47XKQgG5lSOc6hmJ4rmXa9e4_UGMM',
    appId: '1:629077057974:ios:0ca04a9958765a8a3aa117',
    messagingSenderId: '629077057974',
    projectId: 'bambare-tms-e1cc5',
    storageBucket: 'bambare-tms-e1cc5.firebasestorage.app',
    iosBundleId: 'com.example.bookTws',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBeLW47XKQgG5lSOc6hmJ4rmXa9e4_UGMM',
    appId: '1:629077057974:ios:0ca04a9958765a8a3aa117',
    messagingSenderId: '629077057974',
    projectId: 'bambare-tms-e1cc5',
    storageBucket: 'bambare-tms-e1cc5.firebasestorage.app',
    iosBundleId: 'com.example.bookTws',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAFkjilSFgJ4Smnn5MkoN_xd5hFIbEBDQ4',
    appId: '1:629077057974:web:placeholder',
    messagingSenderId: '629077057974',
    projectId: 'bambare-tms-e1cc5',
    storageBucket: 'bambare-tms-e1cc5.firebasestorage.app',
  );
}
